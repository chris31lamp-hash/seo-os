#!/usr/bin/env node
// Load a list of clients into a running SEO Office in one go.
//
// Usage (SEO Office must be running: `pnpm dev`):
//   node scripts/seed-clients.mjs                     # reads private/clients.json
//   node scripts/seed-clients.mjs path/to/list.json
//   SEO_OFFICE_URL=http://localhost:3000 node scripts/seed-clients.mjs
//
// File format:
//   { "owner": "Your name",
//     "clients": [ { "clientName": "Example Co", "siteUrl": "https://example.com/" } ] }
//
// `private/` is gitignored, so client lists never reach the repo.
// Clients whose site is already in SEO Office are skipped.
import { readFileSync } from "node:fs";

const base = (process.env.SEO_OFFICE_URL || "http://localhost:3000").replace(/\/$/, "");
const file = process.argv[2] || "private/clients.json";

function host(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, "").toLowerCase();
  } catch {
    return String(url).toLowerCase();
  }
}

let list;
try {
  list = JSON.parse(readFileSync(file, "utf8"));
} catch (err) {
  console.error(`Could not read ${file}: ${err.message}`);
  process.exit(1);
}
const clients = Array.isArray(list) ? list : list.clients;
if (!Array.isArray(clients) || clients.length === 0) {
  console.error(`${file} has no "clients" list.`);
  process.exit(1);
}
const owner = Array.isArray(list) ? undefined : list.owner;

let existing;
try {
  const res = await fetch(`${base}/api/clients`);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  existing = new Set(((await res.json()).clients || []).map((c) => host(c.site_url)));
} catch (err) {
  console.error(`SEO Office is not reachable at ${base} (${err.message}). Start it with: pnpm dev`);
  process.exit(1);
}

let added = 0, skipped = 0, failed = 0;
for (const c of clients) {
  const name = c.clientName || c.siteUrl;
  if (!c.siteUrl) {
    console.log(`  ! ${name}: no siteUrl, skipped`);
    failed++;
    continue;
  }
  if (existing.has(host(c.siteUrl))) {
    console.log(`  - ${name}: already in SEO Office`);
    skipped++;
    continue;
  }
  const body = { siteUrl: c.siteUrl, clientName: c.clientName };
  if (c.owner || owner) body.owner = c.owner || owner;
  if (c.businessType) body.businessType = c.businessType;
  const res = await fetch(`${base}/api/clients`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const out = await res.json().catch(() => ({}));
  if (res.ok && out.ok !== false) {
    console.log(`  ✓ ${name} → ${out.slug ?? "created"}`);
    existing.add(host(c.siteUrl));
    added++;
  } else {
    console.log(`  ✗ ${name}: ${out.error || `HTTP ${res.status}`}`);
    failed++;
  }
}
console.log(`\nAdded ${added}, already there ${skipped}, failed ${failed}.`);
process.exit(failed ? 1 : 0);
