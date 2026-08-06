import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { hasAuthoritativeTraycerEvidence, validateToolRoutingPolicy } from "../scripts/tool-routing-contract.ts";

const root = join(import.meta.dir, "..");
const readPolicy = () => readFileSync(join(root, "docs/reference/tool-routing.yaml"), "utf8");
const readSupersessionSection = () => {
  const track = readFileSync(join(root, "docs/tracks/main-os-alignment.md"), "utf8");
  const match = track.match(/## Supersesión vigente(?:\s+\([^)]+\))?\r?\n([\s\S]*?)(?=\r?\n## |\s*$)/i);
  if (!match || match.index === undefined) throw new Error("Missing Main supersession section");
  return { historical: track.slice(0, match.index), section: match[1] };
};

const expectDailyTraycerAuthority = (section: string) => {
  expect(section).toMatch(/Traycer\s+con\s+harness\s+nativo\s+es\s+la\s+autoridad\s+de\s+sesión\s+cotidiana/i);
  expect(section).toMatch(/OMP\s+queda\s+standalone\/manual/i);
  expect(section).toMatch(/no\s+gobierna\s+la\s+sesión/i);
};

describe("Traycer-native routing contract", () => {
  test("accepts the v14 policy and rejects narrative-only evidence", () => {
    const policy = readPolicy();
    expect(validateToolRoutingPolicy(policy)).toEqual([]);
    expect(hasAuthoritativeTraycerEvidence(policy)).toBe(true);
    expect(hasAuthoritativeTraycerEvidence("No usar Traycer como control plane; OMP sigue diario.")).toBe(false);
  });

  test("fails closed for version, authority, fallback, Pi usage and gates", () => {
    const policy = readPolicy();
    expect(validateToolRoutingPolicy(policy.replace("version: 14", "version: 13"))).toEqual(expect.arrayContaining([expect.stringContaining("version")]));
    expect(validateToolRoutingPolicy(policy.replace("automatic_fallback: false", "automatic_fallback: true"))).toEqual(expect.arrayContaining([expect.stringContaining("automatic_fallback")]));
    expect(validateToolRoutingPolicy(policy.replace("- harness_lab", "- coding_runtime"))).toEqual(expect.arrayContaining([expect.stringContaining("pi_usage")]));
    expect(validateToolRoutingPolicy(policy.replace("policy: traycer_native_intent_first", "policy: omp_native_intent_first").replace("control_plane: traycer", "control_plane: omp").replace("harness: codex", "harness: omp"))).toEqual(expect.arrayContaining([expect.stringContaining("policy"), expect.stringContaining("runtime.control_plane"), expect.stringContaining("runtime.harness")]));
    expect(validateToolRoutingPolicy(policy.replace("  control_plane: traycer", "control_plane: traycer"))).toEqual(expect.arrayContaining([expect.stringContaining("control_plane outside runtime.control_plane")]));
    expect(validateToolRoutingPolicy(policy.replace("    - installs", "    - removed_install_gate"))).toEqual(expect.arrayContaining([expect.stringContaining("approval.require_for")]));
  });

  test("rejects duplicate critical mappings and unsupported flow syntax", () => {
    const policy = readPolicy();
    expect(validateToolRoutingPolicy(policy.replace("  control_plane: traycer", "  control_plane: traycer\n  control_plane: omp"))).toEqual(expect.arrayContaining([expect.stringContaining("duplicate YAML mapping runtime.control_plane")]));
    expect(validateToolRoutingPolicy(`${policy}\nextra: { harness: omp }\n`)).toEqual(expect.arrayContaining([expect.stringContaining("unsupported inline comment, flow syntax")]));
  });

  test("fails closed for Product Integrations invariant and hot OMP authority", () => {
    const policy = readPolicy();
    const removed = policy.replace("product_integrations:", "product_integrations_removed:");
    expect(validateToolRoutingPolicy(removed)).toEqual(expect.arrayContaining([expect.stringContaining("product_integrations")]));
    const launcherRemoved = policy.replace("  product_pi_launcher: external_desktop_integration", "  product_pi_launcher: removed");
    expect(validateToolRoutingPolicy(launcherRemoved)).toEqual(expect.arrayContaining([expect.stringContaining("product_integrations.product_pi_launcher")]));
    const hotPaths = [
      "AGENTS.md",
      "docs/OS_PLAYBOOK.md",
      "docs/topics/agent-tool-routing.md",
      "docs/topics/agentic-os-operations.md",
      "docs/TOPICS.md",
      "docs/PROJECT.md",
      "docs/topics/os-quality.md",
      "docs/GLOSSARY.md",
      "docs/.generated/context-index.md",
    ];
    const hot = hotPaths.map((path) => readFileSync(join(root, path), "utf8")).join("\n");
    const history = readFileSync(join(root, "docs/tracks/main-os-alignment.md"), "utf8");
    expect(hot).not.toMatch(/OMP(?:\s+nativo)?\s+gobierna(?:\s+la)?\s+sesión/i);
    expect(hot).not.toMatch(/OMP\s+es\s+el\s+harness\s+de\s+trabajo/i);
    expect(hot).not.toMatch(/Scripts\s+OMP\s+con\s+Bun\/TypeScript/i);
    expect(hot).not.toMatch(/^##\s+OMP\s+nativo\s*$/im);
    expect(hot).not.toMatch(/OMP(?:\s+nativo)?\s+(?:es|sigue\s+siendo)\s+(?:la\s+)?(?:sesión|ruta|autoridad|harness)\s+(?:cotidiana|diaria|de\s+trabajo)/i);
    expect(history).toMatch(/Traycer/i);
    expect(history).toMatch(/supersed/i);
    expect(history).toMatch(/OMP\s+nativa/i);

    const { historical, section } = readSupersessionSection();
    expect(historical).toMatch(/OMP\s+nativa/i);
    expectDailyTraycerAuthority(section);

    const inverted = section
      .replace(
        "Traycer con harness nativo es la autoridad de sesión cotidiana para esta capa.",
        "OMP nativo es la autoridad de sesión cotidiana para esta capa.",
      )
      .replace(
        "OMP queda standalone/manual y no gobierna la sesión; el launcher Pi de producto",
        "Traycer queda standalone/manual y no gobierna la sesión; el launcher Pi de producto",
      );
    expect(inverted).toContain("OMP nativo es la autoridad de sesión cotidiana");
    expect(inverted).toContain("Traycer queda standalone/manual");
    expect(() => expectDailyTraycerAuthority(inverted)).toThrow();
  });
});
