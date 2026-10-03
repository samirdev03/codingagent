FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund \
    && mkdir -p /state \
    && chown node:node /state

COPY index.mjs ./

USER node

CMD ["node", "index.mjs"]
