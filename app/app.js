const express = require("express");
const os = require("os");

const app = express();
const PORT = 3001;

app.get("/", (req, res) => {
  res.send(`Hello World from container 👋
Hostname: ${os.hostname()}`);
});

app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

app.listen(PORT, () => {
  console.log(`App running on port ${PORT}`);
});