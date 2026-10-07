# Remote setup

## Server prerequisites

Use a Linux server reachable over SSH. Install Git, Node.js/npm (Node 22 or newer), Docker Engine, and the Docker Compose plugin. Add the SSH user to the Docker group only if you accept the host-level privileges that grants; otherwise use an authorized Docker setup. The repository's Playwright endpoint is published only on `127.0.0.1:8931`.

Clone the project and install Codex on the SSH user account:

```sh
git clone --branch feat/codex-remote-obsidian https://github.com/samirdev03/codingagent.git
cd codingagent
cp .env.example .env
sed -i "s/^OBSIDIAN_UID=.*/OBSIDIAN_UID=$(id -u)/; s/^OBSIDIAN_GID=.*/OBSIDIAN_GID=$(id -g)/" .env
bash scripts/install-codex-host.sh
```

Start a fresh login shell so its PATH changes apply, then authenticate Codex with the ChatGPT account you intend to use:

```sh
codex login
```

Codex account authentication is separate from GitHub authorization. Do not copy `~/.codex/auth.json` into the repository or Docker image.

## Start MCP services

```sh
docker compose up -d --build
scripts/remote-doctor.sh
```

The Obsidian MCP reads and writes only the repository vault mounted at `/vault`. The Playwright MCP listens on loopback at port 8931; it is not exposed publicly. The GitHub MCP image is downloaded on first use and launched by Codex over stdio. Install GitHub CLI from [cli.github.com](https://cli.github.com/) if needed, then authenticate the server user once:

```sh
gh auth login --hostname github.com --git-protocol https --web
```

The MCP wrapper reads the credential with `gh auth token` and passes it to the container as an environment variable. It does not print or write the token to the repository or image. Protect the server user's GitHub CLI config as a credential.

## Connect from the desktop app

Configure SSH access in the desktop user's `~/.ssh/config` (or the platform's equivalent), for example:

```sshconfig
Host codingagent-server
  HostName your-server.example
  User your-linux-user
  IdentityFile ~/.ssh/codingagent_ed25519
  IdentitiesOnly yes
```

Install the private key securely on the desktop and add its public key to the server user's `~/.ssh/authorized_keys`. Verify `ssh codingagent-server` works from a terminal. In the ChatGPT desktop app, switch to Codex, add/connect an SSH host using that host alias, and open the cloned `codingagent` folder as the project. Leave the server online and Compose services running. Codex CLI is launched on the SSH host when the desktop app opens a remote Codex session.

## Mobile access

Codex is not a selectable standalone mode in ChatGPT mobile. Open the mobile app's **Remote** tab for supported desktop Codex chats. OpenAI's current help documentation describes that as remote access to supported desktop chats; it does not guarantee that every SSH-hosted session is exposed there. Connect and test the server workspace in the desktop app first. If the session is not listed in mobile Remote, use the desktop app for that SSH workspace or use Codex Cloud for a mobile-first cloud task. Remote access depends on the supported desktop host and the app/session remaining available.

References: [ChatGPT Work and Codex](https://help.openai.com/en/articles/20001275-chatgpt-work-and-codex), [Codex remote engineering guide](https://developers.openai.com/blog/mastering-codex-remote-for-engineering).

## Obsidian vault

No Obsidian account sign-in is needed for the server-side Markdown vault. Run the `obsidian-init` skill from the repository workspace to bootstrap its layout. If you want Obsidian Sync, install/sign in to Obsidian separately on a client and configure Sync there; the Compose stack does not run Obsidian's desktop GUI or Sync client. The server vault path is `obsidian-vault/`.

## Authentication summary

- **Codex**: `codex login` on the Linux SSH user account.
- **GitHub MCP**: `gh auth login` once on the Linux SSH user account; the wrapper reuses the GitHub CLI credential.
- **Obsidian vault**: local files, no account login. Optional Obsidian Sync is separate.
