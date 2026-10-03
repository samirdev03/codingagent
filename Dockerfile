FROM ghcr.io/anomalyco/opencode:2.0.7

USER root

RUN apk add --no-cache git ripgrep ca-certificates \
    && adduser -D -u 10001 -h /home/opencode opencode \
    && mkdir -p /home/opencode/.config/opencode/agents \
               /home/opencode/.local/share/opencode \
               /home/opencode/.cache/opencode \
               /workspace \
    && chown -R opencode:opencode /home/opencode /workspace

COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json
COPY --chown=opencode:opencode .opencode/agents/ /home/opencode/.config/opencode/agents/

ENV HOME=/home/opencode \
    XDG_CONFIG_HOME=/home/opencode/.config \
    XDG_DATA_HOME=/home/opencode/.local/share \
    XDG_CACHE_HOME=/home/opencode/.cache \
    BUN_RUNTIME_TRANSPILER_CACHE_PATH=0

WORKDIR /workspace
USER opencode

EXPOSE 4096

ENTRYPOINT ["opencode"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4096"]
