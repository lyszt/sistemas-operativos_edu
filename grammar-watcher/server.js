const path = require("path");
const { execFile } = require("child_process");
const express = require("express");
const { WebSocketServer } = require("ws");
const chokidar = require("chokidar");

const PORT = process.env.PORT || 5055;
const PDF_PATH = process.env.PDF_PATH || path.join(__dirname, "..", "src", "main.pdf");
const LANGUAGE = "es";
const API_URL = "https://api.languagetool.org/v2/check";

const app = express();
app.use(express.static(path.join(__dirname, "public")));

const server = app.listen(PORT, () => {
  console.log(`grammar-watcher running at http://localhost:${PORT}`);
  console.log(`watching ${PDF_PATH}`);
});

const wss = new WebSocketServer({ server });

function broadcast(payload) {
  const data = JSON.stringify(payload);
  for (const client of wss.clients) {
    if (client.readyState === client.OPEN) client.send(data);
  }
}

function run(cmd, args, input) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { maxBuffer: 10 * 1024 * 1024, input }, (err, stdout) => {
      if (err) return reject(err);
      resolve(stdout);
    });
  });
}

function extractText(pdfPath) {
  return run("pdftotext", ["-layout", pdfPath, "-"]);
}

async function queryLanguageTool(text) {
  const stdout = await run("curl", [
    "-sS", "--fail",
    "--data-urlencode", `text=${text}`,
    "--data-urlencode", `language=${LANGUAGE}`,
    "--data-urlencode", "disabledRules=WHITESPACE_RULE,ES_SPLIT_WORDS_HYPHEN,COMMA_PARENTHESIS_WHITESPACE",
    API_URL,
  ]);
  return JSON.parse(stdout);
}

async function checkGrammar() {
  try {
    const text = await extractText(PDF_PATH);
    if (!text.trim()) {
      broadcast({ ok: false, error: "No text extracted from PDF." });
      return;
    }

    const data = await queryLanguageTool(text);
    broadcast({ ok: true, checkedAt: new Date().toISOString(), matches: data.matches });
  } catch (err) {
    broadcast({ ok: false, error: err.message });
  }
}

let debounceTimer = null;
chokidar.watch(PDF_PATH, { awaitWriteFinish: { stabilityThreshold: 300, pollInterval: 100 } })
  .on("add", scheduleCheck)
  .on("change", scheduleCheck);

function scheduleCheck() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(checkGrammar, 200);
}

wss.on("connection", (ws) => {
  checkGrammar();
});
