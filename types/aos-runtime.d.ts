interface AosFsStats {
  isDirectory(): boolean;
  isFile(): boolean;
  isSymbolicLink(): boolean;
  mtimeMs: number;
}

interface AosFsDirent {
  name: string;
  isDirectory(): boolean;
  isFile(): boolean;
}

declare module "node:fs" {
  export function existsSync(path: string): boolean;
  export function lstatSync(path: string): AosFsStats;
  export function mkdirSync(path: string, options: { recursive: true }): string | undefined;
  export function readdirSync(path: string): string[];
  export function readdirSync(path: string, options: { withFileTypes: true }): AosFsDirent[];
  export function readFileSync(path: string, encoding: "utf8"): string;
  export function realpathSync(path: string): string;
  export function statSync(path: string): AosFsStats;
  export function writeFileSync(path: string, data: string): void;
}

declare module "node:path" {
  export function dirname(path: string): string;
  export function isAbsolute(path: string): boolean;
  export function join(...paths: string[]): string;
  export function relative(from: string, to: string): string;
  export function resolve(...paths: string[]): string;
}

declare module "node:url" {
  export function pathToFileURL(path: string): { href: string };
}

declare const process: {
  cwd(): string;
  env: Record<string, string | undefined>;
  platform: string;
  exit(code?: number): never;
  exitCode?: number;
};
