# Full toolkit setup guide

This guide installs SEO Office and the five companion Claude Code plugins, plus YouTube Pro, on your own computer. It assumes no technical background. Budget about 45 minutes the first time, most of it waiting for downloads and collecting API keys.

## What you are installing

| Tool | What it does for you | Where it runs | How you use it |
| --- | --- | --- | --- |
| **SEO Office** (this repo) | 3D "agency office" with 25 SEO specialists and a per-client brain | Browser, at `http://localhost:3000` | `pnpm dev`, then click around |
| **claude-seo** | SEO audits, schema, technical, local, AI search checks | Inside Claude Code | `/seo ...` commands |
| **claude-obsidian** | Turns sources into a linked, cited knowledge vault (Markdown, works with the Obsidian app) | Inside Claude Code | `/claude-obsidian:wiki` |
| **claude-ads** | Paid-media audits and plans for Google, Meta, LinkedIn, TikTok and more. Read-only by default | Inside Claude Code | `/ads ...` commands |
| **claude-blog** | Blog strategy, writing, and content audits with a quality gate | Inside Claude Code | `/blog ...` commands |
| **banana-claude** | Image generation with Google Gemini. Shows the prompt and cost before it runs | Inside Claude Code | `/banana-claude:banana ...` |
| **YouTube Pro** | YouTube research, AI insights, scripts, and thumbnails | Browser, at `http://127.0.0.1:5000` | `npm run dev` in its folder |
| **Obsidian vault** | Your SEO knowledge base: research, client notes, decisions, all with sources | Obsidian app + Claude Code | `~/Documents/SEO-Office-Vault` |

## Before you start

You need:

- [ ] A Mac, a Linux computer, or Windows with WSL2. Plain Windows (PowerShell/CMD) is not supported by SEO Office.
- [ ] **Claude Code** installed and signed in. Install instructions: <https://code.claude.com/docs>. Check by typing `claude --version` in a terminal.
- [ ] **git**. On a Mac, typing `git --version` offers to install it if missing.
- [ ] **Python 3.11 or newer.** Mac: `brew install python@3.13`. Ubuntu/WSL: `sudo apt install python3.13` (or your distro's equivalent).
- [ ] About 3 GB of free disk space.

Node.js and pnpm are installed for you by the script if they are missing (it asks first).

## Step 1 — Get the code

Open a terminal and run:

```bash
git clone https://github.com/chris31lamp-hash/seo-os.git ~/seo-office
```

This is your copy of SEO Office, and it includes the toolkit setup script. If the repository is private, git asks you to sign in to GitHub.

> The original instructions clone `AgriciDaniel/seo-os`. That works too, but it does not include `scripts/setup-toolkit.sh` or this guide.

## Step 2 — Run the toolkit installer

```bash
bash ~/seo-office/scripts/setup-toolkit.sh
```

It runs in this order:

1. **SEO Office.** Runs the original `scripts/install.sh`: checks your system, installs Node 24 and pnpm if needed, installs dependencies, and creates `.env.local`.
2. **Claude Code plugins.** Adds each plugin's marketplace and installs claude-seo, claude-obsidian, claude-ads, claude-blog, and banana-claude. These are the same as typing `/plugin marketplace add ...` and `/plugin install ...` inside Claude Code.
3. **YouTube Pro.** Clones it to `~/youtubepro`, runs `npm install`, and creates its `.env` file.
4. **Obsidian vault.** Copies `obsidian-vault-template/` to `~/Documents/SEO-Office-Vault`. If that folder already exists, it is left alone.

It ends with a summary. Anything that failed is listed; fix it and run the same command again. Parts that already worked are skipped.

## Step 3 — SEO Office first run

```bash
cd ~/seo-office
pnpm dev
```

Open <http://localhost:3000/setup> and follow the wizard:

1. **Pick an AI provider.** Choose **Claude CLI** if Claude Code is installed. It uses your existing Claude subscription instead of paying per request.
2. **Add integrations** (optional, see the API key table below). Each missing key only switches off the specialists that need it.
3. **Add your first client.** Click **+ New Client**, paste the website URL, then open the orchestrator (the centre dais) and type `build the brain`.

Leave this terminal running while you use SEO Office. Press `Ctrl+C` to stop it.

## Step 4 — Finish the plugin setup inside Claude Code

Open a **second** terminal:

```bash
cd ~/seo-office
claude
```

If Claude Code asks whether to trust this folder, say yes. This repo's `.claude/settings.json` lists all five plugins, so Claude Code offers to install anything that is still missing.

Then type these one at a time and follow each one's prompts:

| Command | What it does |
| --- | --- |
| `/reload-plugins` | Loads the newly installed plugins |
| `/seo setup` | Creates claude-seo's private Python environment and installs its browser |
| `/seo doctor` | Confirms claude-seo is ready |
| `/ads setup` | Creates your first client profile: accounts, KPIs, and safety guardrails |
| `/banana-claude:banana generate a 16:9 test image of a tidy desk` | Test image. Needs a Gemini key; shows cost before running |
| `/blog strategy <your niche>` | First blog plan |

## Step 5 — Your Obsidian vault

The installer created a ready-made vault at `~/Documents/SEO-Office-Vault`. It was generated with claude-obsidian's own setup tool and passes its health check.

**Open it in Obsidian**

1. Download Obsidian (free) from <https://obsidian.md> and install it.
2. Open Obsidian → **Open folder as vault** → choose `Documents/SEO-Office-Vault`.

**Fill it with Claude**

```bash
cd ~/Documents/SEO-Office-Vault
claude
```

| Command | What it does |
| --- | --- |
| `/claude-obsidian:wiki` | Checks the vault and shows what to do next |
| Drop a file into `inbox/`, then `/claude-obsidian:wiki-ingest` | Turns a source (report, brief, transcript) into linked, cited notes |
| `/claude-obsidian:wiki-query <question>` | Answers from your vault only, with sources |
| `/claude-obsidian:save` | Saves a useful answer from the chat into the vault |
| `/claude-obsidian:wiki-lint` | Health check: dead links, orphans, missing sources |

Each change is shown as a plan first and written only after you approve it.

**What's inside**

| Folder | Purpose |
| --- | --- |
| `inbox/` | Drop new sources here |
| `wiki/` | Your notes. `index.md` is the catalogue, `hot.md` is recent context, `log.md` is the history |
| `wiki/meta/ledgers/` | Source and claim tracking. Leave these to the plugin |
| `.raw/` | Archived copies of ingested sources (hidden in Obsidian) |

**Keep client data private.** The vault lives outside the SEO Office folder, so nothing in it is uploaded to GitHub. `obsidian-vault-template/` in this repo is only the empty starting copy. Don't put client notes in it.

## Step 6 — API keys

You do not need all of these on day one. Start with the **Priority 1** rows.

| Priority | Key or account | Used by | Where to get it | Where it goes |
| --- | --- | --- | --- | --- |
| 1 | Claude subscription (via Claude Code) | Everything | You already have this if Claude Code works | Nothing to paste |
| 1 | Google Cloud sign-in (gcloud) | SEO Office: Search Console, GA4 | The SEO Office `/setup` wizard walks you through it | Handled by the wizard |
| 1 | Google API key (PageSpeed, CrUX) | SEO Office, claude-seo | Google Cloud Console → APIs & Services → Credentials | SEO Office `/setup` page |
| 2 | DataForSEO login | SEO Office keyword, SERP, and backlink specialists; claude-seo extensions | dataforseo.com (paid, pay-as-you-go) | SEO Office `/setup` page |
| 2 | Gemini API key (billing enabled) | banana-claude, YouTube Pro, claude-blog images | Google AI Studio | banana-claude prompts for it; YouTube Pro Settings page |
| 2 | YouTube Data API v3 key | YouTube Pro research | Google Cloud Console → enable "YouTube Data API v3" → Credentials | YouTube Pro Settings page |
| 3 | Bing Webmaster API key | SEO Office second-source backlinks | Bing Webmaster Tools → Settings → API access | SEO Office `/setup` page |
| 3 | Firecrawl API key | SEO Office full-site crawling | firecrawl.dev | SEO Office `/setup` page |
| 3 | Ad platform access (Google Ads, Meta, etc.) | claude-ads | Each ad platform | `/ads setup` explains; keep keys in environment variables or your OS keychain |

Rules for keys:

- Paste keys only into the setup pages or files named above. Never into a chat, email, or document.
- `.env`, `.env.local`, and `.seo-office/` are excluded from git, so they are never uploaded to GitHub.
- One Google Cloud project can hold the Google API key and the YouTube key. Turn on billing alerts in Google Cloud before using Gemini image generation.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `claude: command not found` | Install Claude Code, open a new terminal, then run `SKIP_SEO_OFFICE=1 bash scripts/setup-toolkit.sh` |
| `pnpm: command not found` after install | Close and reopen the terminal |
| Plugin commands like `/seo` do nothing | Run `/reload-plugins`, or quit and restart Claude Code |
| YouTube Pro says port 5000 is in use (common on Mac) | Add `PORT=5050` to `~/youtubepro/.env`, then open `http://127.0.0.1:5050` |
| Python version error | Install Python 3.11+ (see "Before you start"), then re-run the script |
| Want to redo just one part | `SKIP_SEO_OFFICE=1`, `SKIP_PLUGINS=1`, `SKIP_YOUTUBEPRO=1`, or `SKIP_VAULT=1` in front of the command skips that part |
| Want the vault somewhere else | `VAULT_DIR="$HOME/Obsidian/SEO" bash scripts/setup-toolkit.sh` |

## Safety notes

- **claude-ads** is read-only by default. It asks before changing anything in an ad account. Say no until you have reviewed the plan.
- **banana-claude** shows the model and estimated cost before generating and needs your approval for each attempt.
- **YouTube Pro** listens only on your own computer. Do not expose it to the internet.
- All client data stays on your computer: SEO Office in `~/seo-office/.seo-office/`, your knowledge vault wherever you choose to create it.
