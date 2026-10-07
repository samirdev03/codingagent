FROM node:22.18.0-alpine3.22

RUN npm install --global obsidian-mcp@2.0.1 \
    && addgroup -S mcp \
    && adduser -S -G mcp -h /home/mcp mcp \
    && mkdir -p /vault /workspace /tmp \
    && chown -R mcp:mcp /home/mcp /vault /workspace

USER mcp
WORKDIR /workspace

ENTRYPOINT ["sh", "-c"]
CMD ["while :; do sleep 3600; done"]
