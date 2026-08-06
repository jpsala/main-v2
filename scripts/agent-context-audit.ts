import { existsSync, lstatSync, readdirSync, readFileSync, realpathSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { validateToolRoutingPolicy } from "./tool-routing-contract.ts";

type Finding = {
  level: "error" | "warn";
  message: string;
};

const root = process.cwd();
const findings: Finding[] = [];


function read(path: string) {
  return readFileSync(join(root, path), "utf8");
}

function exists(path: string) {
  return existsSync(join(root, path));
}

function add(level: Finding["level"], message: string) {
  findings.push({ level, message });
}

function approxTokensFromChars(chars: number) {
  return Math.ceil(chars / 4);
}

function warnIfTooLarge(path: string, maxChars: number, label: string) {
  if (!exists(path)) return;
  const content = read(path);
  if (content.length > maxChars) {
    add(
      "warn",
      `${label} is large (${content.length} chars, ~${approxTokensFromChars(content.length)} tokens); compact or move detail to deeper references`,
    );
  }
}

function frontmatter(content: string) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  return match?.[1] ?? "";
}

function hasFrontmatterKey(frontmatterText: string, key: string) {
  return new RegExp(`^${key}:`, "m").test(frontmatterText);
}

function frontmatterValue(frontmatterText: string, key: string) {
  const match = frontmatterText.match(new RegExp(`^${key}:[ \\t]*([^\\r\\n]*)`, "m"));
  return match?.[1]?.trim();
}

function hasUnsafePlainYamlColon(value: string | undefined) {
  if (!value) return false;
  const trimmed = value.trim();
  if (/^["'].*["']$/.test(trimmed)) return false;
  return /:\s/.test(trimmed);
}

function warnIfFrontmatterYamlLooksUnsafe(path: string, fm: string) {
  for (const key of ["description"]) {
    const value = frontmatterValue(fm, key);
    if (hasUnsafePlainYamlColon(value)) {
      add("error", `${path} frontmatter ${key} contains an unquoted colon; quote the value so YAML parsers do not treat it as a nested mapping`);
    }
  }
}

function modifiedMs(path: string) {
  return statSync(join(root, path)).mtimeMs;
}

function sectionContent(content: string, heading: string) {
  const lines = content.split(/\r?\n/);
  let start = -1;
  let level = 0;

  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(/^(#{1,6})\s+(.+?)\s*$/);
    if (match?.[2] === heading) {
      start = index + 1;
      level = match[1].length;
      break;
    }
  }

  if (start === -1) return "";

  let end = lines.length;
  for (let index = start; index < lines.length; index += 1) {
    const match = lines[index].match(/^(#{1,6})\s+/);
    if (match && match[1].length <= level) {
      end = index;
      break;
    }
  }

  return lines.slice(start, end).join("\n");
}

function listDirs(path: string) {
  const fullPath = join(root, path);
  if (!existsSync(fullPath)) return [];
  return readdirSync(fullPath, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith("."))
    .map((entry) => `${path}/${entry.name}`.replaceAll("\\", "/"))
    .sort();
}

function backtickedSkillRefs(content: string) {
  return [...content.matchAll(/`([^`*\/]+)\/`/g)].map((match) => match[1]).sort();
}

function walkMarkdownFiles(dir: string): string[] {
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) return walkMarkdownFiles(fullPath);
    return entry.isFile() && entry.name.endsWith(".md") ? [fullPath] : [];
  });
}


for (const path of ["AGENTS.md", "docs/WORKING_MEMORY.md", "docs/TOPICS.md"]) {
  if (!exists(path)) add("error", `Missing ${path}`);
}

if (!exists("docs/GLOSSARY.md")) {
  add("warn", "Missing docs/GLOSSARY.md; aliases will not be included in the generated context index");
}

if (!exists("docs/skills")) {
  add("error", "Missing docs/skills/");
}

warnIfTooLarge("AGENTS.md", 6000, "AGENTS.md");
warnIfTooLarge("docs/README.md", 5000, "docs/README.md");
warnIfTooLarge("docs/WORKING_MEMORY.md", 6000, "docs/WORKING_MEMORY.md");
warnIfTooLarge("docs/TOPICS.md", 11000, "docs/TOPICS.md");
warnIfTooLarge("docs/DEVELOPMENT.md", 12000, "docs/DEVELOPMENT.md");

const hotPathFiles = [
  "AGENTS.md",
  "docs/.generated/context-index.md",
  "docs/WORKING_MEMORY.md",
].filter(exists);
const hotPathChars = hotPathFiles.reduce((total, path) => total + read(path).length, 0);
if (hotPathChars > 18000) {
  add(
    "warn",
    `Hot context path is large (${hotPathChars} chars, ~${approxTokensFromChars(hotPathChars)} tokens across ${hotPathFiles.join(", ")}); reduce initial reading load`,
  );
}

const topicsIndex = exists("docs/TOPICS.md") ? read("docs/TOPICS.md") : "";
const agents = exists("AGENTS.md") ? read("AGENTS.md") : "";
const docsReadme = exists("docs/README.md") ? read("docs/README.md") : "";
const docsKnowledge = exists("docs/topics/docs-knowledge-system.md")
  ? read("docs/topics/docs-knowledge-system.md")
  : "";


if (docsReadme) {
  const readingRoute = sectionContent(docsReadme, "Regla De Lectura Liviana");
  if (readingRoute && !readingRoute.includes("docs/.generated/context-index.md")) {
    add("warn", "docs/README.md reading route should explicitly start from docs/.generated/context-index.md");
  }
}

if (docsKnowledge && !docsKnowledge.includes("docs/.generated/context-index.md")) {
  add("warn", "docs/topics/docs-knowledge-system.md should document docs/.generated/context-index.md in the hot route");
}

if (exists("docs/USER_GUIDE.md") && !topicsIndex.includes("USER_GUIDE.md")) {
  add("warn", "docs/USER_GUIDE.md exists but is not listed in docs/TOPICS.md");
}

if (exists("docs/OS_PROJECTS.md") && !topicsIndex.includes("OS_PROJECTS.md")) {
  add("warn", "docs/OS_PROJECTS.md exists but is not listed in docs/TOPICS.md");
}

if (exists("docs/topics/agentic-os-operations.md") && !topicsIndex.includes("topics/agentic-os-operations.md")) {
  add("warn", "docs/topics/agentic-os-operations.md exists but is not linked from docs/TOPICS.md");
}

if (exists("docs/topics/docs-knowledge-system.md") && !topicsIndex.includes("topics/docs-knowledge-system.md")) {
  add("warn", "docs/topics/docs-knowledge-system.md exists but is not linked from docs/TOPICS.md");
}


const topicFiles = exists("docs/topics")
  ? readdirSync(join(root, "docs", "topics")).filter((name) => name.endsWith(".md")).sort()
  : [];

if (!topicFiles.length) add("error", "No docs/topics/*.md files found");

for (const file of topicFiles) {
  const topicPath = `docs/topics/${file}`;
  const content = read(topicPath);
  const fm = frontmatter(content);

  if (!fm) {
    add("warn", `${topicPath} has no frontmatter`);
  } else {
    for (const key of ["id", "status", "kind", "triggers", "primary_refs"]) {
      if (!hasFrontmatterKey(fm, key)) add("warn", `${topicPath} frontmatter missing ${key}`);
    }

    const status = frontmatterValue(fm, "status");
    const maxChars = status === "reference" || status === "historical" ? 30000 : 25000;
    if (content.length > maxChars) {
      add(
        "warn",
        `${topicPath} is large (${content.length} chars, ~${approxTokensFromChars(content.length)} tokens); keep active topics focused or move detail deeper`,
      );
    }
  }

  if (!topicsIndex.includes(`topics/${file}`)) {
    add("warn", `${topicPath} is not linked from docs/TOPICS.md`);
  }
}

for (const file of walkMarkdownFiles(join(root, "docs", "tracks"))) {
  const trackPath = relative(root, file).replaceAll("\\", "/");
  if (trackPath === "docs/tracks/README.md") continue;
  const content = read(trackPath);
  const fm = frontmatter(content);

  if (!fm) {
    add("warn", `${trackPath} has no frontmatter`);
    continue;
  }

  for (const key of ["status", "updated"]) {
    if (!hasFrontmatterKey(fm, key)) add("warn", `${trackPath} frontmatter missing ${key}`);
  }

  if (content.length > 50000) {
    add(
      "warn",
      `${trackPath} is large (${content.length} chars, ~${approxTokensFromChars(content.length)} tokens); tracks should be resumable state, not a transcript`,
    );
  }
}

if (exists("docs/skills")) {
const skillDirs = listDirs("docs/skills");

if (exists("docs/skills/README.md")) {
    const skillNames = new Set(skillDirs.map((dir) => dir.split("/").at(-1) ?? dir));
    for (const skillName of backtickedSkillRefs(read("docs/skills/README.md"))) {
      if (!skillNames.has(skillName)) {
        add("warn", `docs/skills/README.md references missing skill docs/skills/${skillName}/`);
      }
    }
  }

  for (const skillDir of skillDirs) {
    const skillFile = `${skillDir}/SKILL.md`;
    if (!exists(skillFile)) {
      add("warn", `${skillDir} is missing SKILL.md`);
      continue;
    }

    const content = read(skillFile);
    const fm = frontmatter(content);
    if (!fm) {
      add("warn", `${skillFile} has no frontmatter`);
      continue;
    }

    for (const key of ["name", "description"]) {
      if (!hasFrontmatterKey(fm, key)) add("warn", `${skillFile} frontmatter missing ${key}`);
    }
    warnIfFrontmatterYamlLooksUnsafe(skillFile, fm);
  }
}

const legacyRuntimeSurfaces = [
  "runtime/aos-flujo.ts",
  "runtime/aos-flujo-omp.ts",
  "aos.manifest.json",
  "aos.requirements.json",
  "types/aos-runtime.d.ts",
  ".pi",
  "docs/topics/pi-agentic-os.md",
  "docs/topics/pi-extension-stack.md",
];
for (const path of legacyRuntimeSurfaces) {
  if (exists(path)) {
    add("error", `${path} is a legacy project agent runtime or manifest surface; OMP supplies the agentic harness`);
  }
}

try {
  const pkg = JSON.parse(read("package.json"));
  if ("pi" in pkg || "omp" in pkg) {
    add("error", "package.json must not publish Pi or OMP agent runtime extensions");
  }
} catch {
  add("error", "package.json is invalid JSON");
}

const routing = exists("docs/reference/tool-routing.yaml") ? read("docs/reference/tool-routing.yaml") : "";
for (const error of validateToolRoutingPolicy(routing)) add("error", error);
if (!exists("docs/topics/portable-multiharness-contract.md")) add("error", "Missing docs/topics/portable-multiharness-contract.md");

const agenticHotPaths = [
  "AGENTS.md",
  "docs/WORKING_MEMORY.md",
  "docs/TOPICS.md",
  "docs/README.md",
  "docs/PROJECT.md",
  "docs/GLOSSARY.md",
  "docs/.generated/context-index.md",
  "docs/OS_PLAYBOOK.md",
  "docs/topics/agent-tool-routing.md",
  "docs/topics/agentic-os-operations.md",
  "docs/topics/portable-multiharness-contract.md",
  "docs/topics/local-codex-skills.md",
  "docs/topics/os-quality.md",
  "docs/skills/README.md",
  "docs/reference/tool-routing.yaml",
];
for (const path of agenticHotPaths.filter(exists)) {
  const content = read(path);
  for (const legacyToken of [
    "/flow",
    "AOS_HOME",
    "aos.requirements.json",
    "runtime/aos-flujo",
    "execution_route",
    "global_aos_package",
    "flow_first_explicit_model_route",
  ]) {
    if (content.includes(legacyToken)) {
      add("error", `${path} reintroduces legacy project agent runtime token ${legacyToken}`);
    }
  }
}

const productPiLauncherContract = [
  {
    path: "menu-actions.ahk",
    phrases: [
      "RunPiMenuPreset(preset)",
      'scriptPath := "C:\\tools\\pi-menu.ps1"',
      "ShowPiMenuHelp()",
    ],
  },
  {
    path: "menus.ahk",
    phrases: [
      'label: "Pi launcher"',
      'RunPiMenuPreset("plan")',
      'label: "AOS normal"',
      'RunPiMenuPreset("aos")',
    ],
  },
  {
    path: "tests/command-palette-probe.ahk",
    phrases: ['"Pi launcher option "'],
  },
];
for (const contract of productPiLauncherContract) {
  if (!exists(contract.path)) {
    add("error", `${contract.path} is missing; preserve the external product Pi launcher`);
    continue;
  }
  const content = read(contract.path);
  for (const phrase of contract.phrases) {
    if (!content.includes(phrase)) {
      add("error", `${contract.path} no longer preserves product Pi launcher contract ${phrase}`);
    }
  }
}

if (!exists(".agents/skills")) {
  // Allowed when this repo does not expose local skills to OMP discovery.
} else if (exists("docs/skills")) {
  const stats = lstatSync(join(root, ".agents/skills"));
  if (!(stats.isSymbolicLink() || stats.isDirectory())) {
    add("warn", ".agents/skills exists but is not a directory-like link");
  }

  const compatPath = realpathSync(join(root, ".agents/skills"));
  const canonicalPath = realpathSync(join(root, "docs/skills"));
  if (compatPath !== canonicalPath) {
    add("warn", ".agents/skills does not resolve to docs/skills");
  }
}

const specDirs = ["specs", ".specify/specs"].flatMap((specRoot) =>
  listDirs(specRoot).map((path) => ({
    path,
    name: path.split("/").at(-1) ?? path,
  })),
);
const specPrefixes = new Map<string, string[]>();

for (const spec of specDirs) {
  if (!exists(`${spec.path}/spec.md`)) {
    add("warn", `${spec.path} has no spec.md`);
  }

  const prefix = spec.name.match(/^\d+/)?.[0];
  if (!prefix) continue;
  specPrefixes.set(prefix, [...(specPrefixes.get(prefix) ?? []), spec.path]);
}

for (const [prefix, paths] of specPrefixes) {
  if (paths.length > 1) {
    add("warn", `Spec numeric prefix ${prefix} is duplicated across ${paths.join(", ")}`);
  }
}

if (!exists("docs/.generated/context-index.md")) {
  add("warn", "Missing generated context index docs/.generated/context-index.md");
} else {
  const generatedIndex = read("docs/.generated/context-index.md");
  const tracksSection = sectionContent(generatedIndex, "Tracks") ?? "";
  const indexedTracks = [...tracksSection.matchAll(/\]\(\.\.\/(tracks\/[^)#]+\.md)\)/g)]
    .map((match) => `docs/${match[1]}`)
    .sort();
  const memoryFocus = exists("docs/WORKING_MEMORY.md")
    ? sectionContent(read("docs/WORKING_MEMORY.md"), "Foco Único De Ejecución") ?? ""
    : "";
  const focusState = memoryFocus.match(/^- \*\*Estado:\*\* `([^`]+)`/m)?.[1];
  const focusField = focusState === "ready" ? "Plan" : focusState === "blocked" || focusState === "waiting_gate" ? "Referencia" : undefined;
  const focusedTracks = focusField
    ? [...memoryFocus.matchAll(new RegExp("^- \\*\\*" + focusField + ":\\*\\* `(docs/tracks/[^`]+\\.md)`", "gm"))].map((match) => match[1]).sort()
    : [];
  if (JSON.stringify(indexedTracks) !== JSON.stringify(focusedTracks)) {
    add("error", `Generated context index tracks must match the current execution focus (expected: ${focusedTracks.join(", ") || "none"}; found: ${indexedTracks.join(", ") || "none"})`);
  }

  const indexTime = modifiedMs("docs/.generated/context-index.md");
  const trackMarkdown = walkMarkdownFiles(join(root, "docs", "tracks")).map((path) =>
    relative(root, path).replaceAll("\\", "/"),
  );
  const specMarkdown = specDirs.flatMap((spec) =>
    walkMarkdownFiles(join(root, spec.path)).map((path) => relative(root, path).replaceAll("\\", "/")),
  );
  const indexSources = [
    "scripts/context-index.ts",
    "docs/WORKING_MEMORY.md",
    "docs/GLOSSARY.md",
    "docs/TOPICS.md",
    "docs/OS_PROJECTS.md",
    "docs/skills/README.md",
    "docs/tracks/README.md",
    ...topicFiles.map((file) => `docs/topics/${file}`),
    ...walkMarkdownFiles(join(root, "docs", "skills")).map((path) => relative(root, path).replaceAll("\\", "/")),
    ...trackMarkdown,
    ...specMarkdown,
  ];

  for (const path of indexSources) {
    if (exists(path) && modifiedMs(path) > indexTime) {
      add("warn", `docs/.generated/context-index.md is older than ${path}`);
    }
  }
}

const errors = findings.filter((finding) => finding.level === "error");
const warnings = findings.filter((finding) => finding.level === "warn");

if (!findings.length) {
  console.log("Agent context audit passed.");
  process.exit(0);
}

for (const finding of findings) {
  console.log(`${finding.level.toUpperCase()}: ${finding.message}`);
}

console.log(`Agent context audit found ${errors.length} error(s), ${warnings.length} warning(s).`);
process.exit(errors.length ? 1 : 0);
