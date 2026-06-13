import { appendFileSync, readFileSync } from "node:fs";

const args = parseArgs(process.argv.slice(2));
const room = args.room;
const textPath = args.textPath;
const baseUrl = args.baseUrl || "https://web-clipboard.jpsala.workers.dev";
const logPath = args.logPath || `${process.env.TEMP || process.cwd()}\\web-clipboard-host.log`;

if (!room) throw new Error("Missing --room");
if (!textPath) throw new Error("Missing --textPath");

const text = readFileSync(textPath, "utf8").replace(/^\uFEFF/, "");
const wsUrl = new URL(`/room/${encodeURIComponent(room)}`, baseUrl);
wsUrl.protocol = wsUrl.protocol === "https:" ? "wss:" : "ws:";

const ws = new WebSocket(wsUrl.href);
const timeout = setTimeout(() => {
  writeLog(`error timeout room=${room}`);
  try { ws.close(); } catch {}
  process.exit(1);
}, 5000);

ws.addEventListener("open", () => {
  ws.send(JSON.stringify({ type: "clipboard", text, sentAt: Date.now() }));
  writeLog(`sent room=${room} chars=${text.length}`);
  setTimeout(() => {
    clearTimeout(timeout);
    ws.close();
    process.exit(0);
  }, 300);
});

ws.addEventListener("error", () => {
  clearTimeout(timeout);
  writeLog(`error websocket room=${room}`);
  process.exit(1);
});

function parseArgs(values) {
  const parsed = {};
  for (let index = 0; index < values.length; index += 2) {
    const key = values[index]?.replace(/^--/, "");
    const value = values[index + 1];
    if (key) parsed[key] = value;
  }
  return parsed;
}

function writeLog(message) {
  appendFileSync(logPath, `${new Date().toISOString()} | ${message}\n`, "utf8");
}
