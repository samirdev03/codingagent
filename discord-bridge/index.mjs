import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { Client, GatewayIntentBits } from "discord.js";

const required = [
  "DISCORD_BOT_TOKEN",
  "DISCORD_GUILD_ID",
  "DISCORD_ALLOWED_USER_IDS",
  "DISCORD_ALLOWED_CHANNEL_IDS",
  "OPENCODE_SERVER_USERNAME",
  "OPENCODE_SERVER_PASSWORD",
  "SESSION_STATE_FILE",
];
for (const name of required) {
  if (!process.env[name]?.trim()) throw new Error(name + " must be set");
}

const allowedUsers = new Set(process.env.DISCORD_ALLOWED_USER_IDS.split(",").map((id) => id.trim()).filter(Boolean));
const allowedChannels = new Set(process.env.DISCORD_ALLOWED_CHANNEL_IDS.split(",").map((id) => id.trim()).filter(Boolean));
if (allowedUsers.size === 0 || allowedChannels.size === 0) {
  throw new Error("At least one allowed Discord user and channel ID is required");
}

const statePath = process.env.SESSION_STATE_FILE;
const stateTempPath = statePath + ".tmp";
const state = { sessions: {} };
const baseUrl = (process.env.OPENCODE_BASE_URL || "http://codingagent:4096").replace(/\/$/, "");
const workspace = process.env.OPENCODE_WORKSPACE || "/workspace";
const architectModel = { providerID: "openrouter", id: "anthropic/claude-sonnet-5" };
const basicAuth = Buffer.from(
  process.env.OPENCODE_SERVER_USERNAME + ":" + process.env.OPENCODE_SERVER_PASSWORD,
).toString("base64");

try {
  Object.assign(state, JSON.parse(await readFile(statePath, "utf8")));
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}

async function saveState() {
  await mkdir(dirname(statePath), { recursive: true });
  await writeFile(stateTempPath, JSON.stringify(state, null, 2), { mode: 0o600 });
  await rename(stateTempPath, statePath);
}

async function api(path, options = {}) {
  const response = await fetch(baseUrl + path, {
    ...options,
    headers: {
      authorization: "Basic " + basicAuth,
      ...(options.body ? { "content-type": "application/json" } : {}),
      ...options.headers,
    },
    signal: options.signal || AbortSignal.timeout(30 * 60 * 1000),
  });
  if (!response.ok) {
    const detail = await response.text();
    throw new Error("OpenCode API returned " + response.status + ": " + detail.slice(0, 500));
  }
  if (response.status === 204) return null;
  return response.json();
}

async function sessionFor(channel) {
  let sessionID = state.sessions[channel.id];
  if (sessionID) return sessionID;

  const created = await api("/api/session", {
    method: "POST",
    body: JSON.stringify({
      title: "Discord #" + (channel.name || channel.id),
      agent: "architect",
      model: architectModel,
      location: { directory: workspace },
    }),
  });
  sessionID = created?.data?.id || created?.id;
  if (!sessionID) throw new Error("OpenCode did not return a session ID");
  state.sessions[channel.id] = sessionID;
  await saveState();
  return sessionID;
}

async function messagesFor(sessionID) {
  const result = await api("/api/session/" + encodeURIComponent(sessionID) + "/message?limit=50&order=desc");
  if (Array.isArray(result?.data?.items)) return result.data.items;
  if (Array.isArray(result?.data)) return result.data;
  if (Array.isArray(result?.items)) return result.items;
  return [];
}

function roleOf(message) {
  return message?.info?.role
    || message?.role
    || (message?.type === "assistant" ? "assistant" : undefined);
}

function idOf(message) {
  return message?.info?.id || message?.id;
}

function finishOf(message) {
  return message?.info?.finish || message?.finish;
}

function textFrom(message) {
  const parts = Array.isArray(message?.content) ? message.content : message?.parts || [];
  return parts
    .filter((part) => part?.type === "text" && typeof part.text === "string")
    .map((part) => part.text)
    .join("\n")
    .trim();
}

function createdAt(message) {
  return Number(message?.info?.time?.created || message?.time?.created || 0);
}

async function answerFor(sessionID, text) {
  await api("/api/session/" + encodeURIComponent(sessionID) + "/model", {
    method: "POST",
    body: JSON.stringify({ model: architectModel }),
  });

  const previousAssistantIDs = new Set(
    (await messagesFor(sessionID))
      .filter((message) => roleOf(message) === "assistant")
      .map(idOf)
      .filter(Boolean),
  );

  await api("/api/session/" + encodeURIComponent(sessionID) + "/prompt", {
    method: "POST",
    body: JSON.stringify({ text }),
  });

  const deadline = Date.now() + 30 * 60 * 1000;
  while (Date.now() < deadline) {
    const messages = await messagesFor(sessionID);
    const assistant = messages
      .filter((message) =>
        roleOf(message) === "assistant"
        && finishOf(message)
        && !previousAssistantIDs.has(idOf(message))
        && textFrom(message),
      )
      .sort((left, right) => createdAt(right) - createdAt(left))[0];

    if (assistant) return textFrom(assistant);
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  throw new Error("Timed out waiting for a completed OpenCode text response");
}

function splitDiscordMessage(text) {
  const chunks = [];
  let remaining = text;
  while (remaining.length > 1900) {
    let splitAt = remaining.lastIndexOf("\n", 1900);
    if (splitAt < 900) splitAt = 1900;
    chunks.push(remaining.slice(0, splitAt));
    remaining = remaining.slice(splitAt).trimStart();
  }
  if (remaining) chunks.push(remaining);
  return chunks;
}

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent],
});
const queues = new Map();

client.once("ready", () => {
  console.log("Discord bridge connected as " + client.user.tag);
});

client.on("messageCreate", (message) => {
  if (message.author.bot || message.guildId !== process.env.DISCORD_GUILD_ID) return;
  if (!allowedUsers.has(message.author.id) || !allowedChannels.has(message.channelId)) return;

  const content = message.content.replace(new RegExp("<@!?" + client.user.id + ">", "g"), "").trim();
  if (!content) return;

  const channelID = message.channelId;
  const previous = queues.get(channelID) || Promise.resolve();
  const next = previous
    .catch(() => {})
    .then(async () => {
      const typing = setInterval(() => message.channel.sendTyping().catch(() => {}), 8000);
      try {
        await message.channel.sendTyping();
        const sessionID = await sessionFor(message.channel);
        const answer = await answerFor(
          sessionID,
          "Discord user " + message.author.username + " (" + message.author.id + ") says:\n" + content,
        );
        for (const chunk of splitDiscordMessage(answer)) {
          await message.reply({ content: chunk, allowedMentions: { repliedUser: false } });
        }
      } catch (error) {
        console.error("Discord request failed:", error.message);
        await message.reply({
          content: "Bei der Verarbeitung ist ein Fehler aufgetreten. Prüfe die Container-Logs.",
          allowedMentions: { repliedUser: false },
        }).catch(() => {});
      } finally {
        clearInterval(typing);
      }
    });
  queues.set(channelID, next);
  next.finally(() => {
    if (queues.get(channelID) === next) queues.delete(channelID);
  });
});

await client.login(process.env.DISCORD_BOT_TOKEN);
