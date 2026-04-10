#-----------Build Stage----------------
FROM node:20 AS builder

WORKDIR /app



COPY app/package.json ./
RUN npm install

COPY app/ ./

#-----------Runtime Stage----------------
FROM gcr.io/distroless/nodejs20-debian13


WORKDIR /app
COPY --from=builder /app/app.js ./app.js
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3001
ENTRYPOINT []
CMD ["/nodejs/bin/node", "app.js"]