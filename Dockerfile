FROM node:22-alpine AS discord-mcp-build

RUN apk add --no-cache git ca-certificates \
    && npm install --global pnpm@10.15.1 \
    && git clone --depth 1 https://github.com/diocata/discord-bot-mcp.git /opt/discord-bot-mcp \
    && cd /opt/discord-bot-mcp \
    && pnpm install --frozen-lockfile \
    && pnpm build

FROM ghcr.io/anomalyco/opencode:2.0.7

USER root

RUN apk add --no-cache git ripgrep ca-certificates nodejs npm python3 py3-pip curl wget \
    && adduser -D -u 10001 -h /home/opencode opencode \
    && mkdir -p /home/opencode/.config/opencode/agents \
               /home/opencode/.local/share/opencode \
               /home/opencode/.local/tools \
               /home/opencode/.cache/opencode \
               /opt/discord-bot-mcp \
               /workspace \
    && chown -R opencode:opencode /home/opencode /workspace /opt/discord-bot-mcp

COPY --from=discord-mcp-build /opt/discord-bot-mcp/dist/ /opt/discord-bot-mcp/dist/
COPY --from=discord-mcp-build /opt/discord-bot-mcp/node_modules/ /opt/discord-bot-mcp/node_modules/
COPY --from=discord-mcp-build /opt/discord-bot-mcp/package.json /opt/discord-bot-mcp/package.json
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json
COPY --chown=opencode:opencode .opencode/agents/ /home/opencode/.config/opencode/agents/

ENV HOME=/home/opencode \
    XDG_CONFIG_HOME=/home/opencode/.config \
    XDG_DATA_HOME=/home/opencode/.local/share \
    XDG_CACHE_HOME=/home/opencode/.cache \
    BUN_RUNTIME_TRANSPILER_CACHE_PATH=0 \
    NPM_CONFIG_PREFIX=/home/opencode/.local/tools/npm \
    PATH=/home/opencode/.local/tools/npm/bin:$PATH

WORKDIR /workspace
USER opencode

EXPOSE 4096

ENTRYPOINT ["opencode"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4096"]
