#-----------Build Stage----------------
FROM node:25 AS builder

WORKDIR /app



COPY package.json ./
RUN npm install

COPY . .

#-----------Runtime Stage----------------
FROM gcr.io/distroless/nodejs20-debian12


WORKDIR /app
COPY --from=builder /app/app.js ./app.js
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3001
CMD ["app.js"]