# Flyokai Marketplace documentation

Source for **marketplace.flyokai.com**, built with
[MkDocs Material](https://squidfunk.github.io/mkdocs-material/). Documents the
**Flyokai Marketplace** plugin suite for Shopware 6 (Base + Remote + Bulk).

**This repo holds only the renderer** — config, theme, CI. The Markdown content
is **synced from [`flyokai/flyokai`](https://github.com/flyokai/flyokai)**
(`marketplace-docs/docs/`) at build time. Editing `docs/*.md` here has no effect;
the next sync overwrites it. This is the same pattern
[`flyokai/docs`](https://github.com/flyokai/docs) uses for the framework docs.

## How it works

```
flyokai/flyokai (private)              flyokai/marketplace-docs (this repo, public)   gh-pages → marketplace.flyokai.com
└─ marketplace-docs/                   ├─ mkdocs.yml                                   ├─ index.html
   └─ docs/                            ├─ requirements.txt                             ├─ getting-started/
      ├─ index.md                      ├─ bin/sync-docs.sh                             ├─ architecture/
      ├─ architecture.md               └─ .github/workflows/docs.yml                   └─ ...
      └─ ...                                      │
           │                                      │
           └────────────── sync ────────► docs/ (generated, gitignored)
                                                  │
                                                  └── mkdocs gh-deploy ──►
```

The `Deploy docs` GitHub Action runs:

1. **Daily at 04:00 UTC** (cron) — picks up upstream doc edits.
2. **On push to `main`** of this repo — picks up theme/config changes.
3. **On manual trigger** (`workflow_dispatch`) — for ad-hoc rebuilds.

Each run clones `flyokai/flyokai@main`, executes `bin/sync-docs.sh`, then
`mkdocs gh-deploy --force`.

## Editing documentation

Don't edit files here. Edit them upstream:

```bash
cd /path/to/flyokai/flyokai
# edit marketplace-docs/docs/architecture.md, etc.
git commit -am "marketplace-docs: clarify the offer lifecycle"
git push origin main
```

The site rebuilds within 24 hours (next cron tick), or trigger immediately:

```bash
gh workflow run --repo flyokai/marketplace-docs "Deploy docs"
```

## Local preview

Sync once from a local `flyokai/flyokai` checkout, then run mkdocs:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Sync from a local clone (any flyokai/flyokai working copy works).
FLYOKAI_SOURCE_DIR=/www/sw6710/flyokai bin/sync-docs.sh

mkdocs serve
# open http://127.0.0.1:8000
```

`mkdocs serve` live-reloads on save — but those edits are in the *generated*
`docs/` directory and are lost on the next sync. Use it to preview, not to author.

## CI configuration

The workflow needs read access to `flyokai/flyokai` (private). Setup:

1. **Generate a fine-grained PAT** at <https://github.com/settings/personal-access-tokens/new>:
   - **Resource owner**: `flyokai`
   - **Repository access**: *Only select repositories* → `flyokai/flyokai`
   - **Permissions**: *Repository permissions* → **Contents: Read-only**
   - **Expiration**: 1 year (or shorter — set a calendar reminder)
2. **Add as a repo secret** in this repo's *Settings → Secrets and variables → Actions*:
   - **Name**: `FLYOKAI_DOCS_TOKEN`
   - **Value**: the `github_pat_…` string from step 1
3. The next workflow run will succeed. Trigger one manually with
   `gh workflow run "Deploy docs"`.

When `flyokai/flyokai` becomes public, the secret is no longer required — the
clone step works anonymously. The workflow keeps working with or without it; you
can delete it for hygiene at that point.

> **First deploy:** `mkdocs gh-deploy` pushes a `gh-pages` branch. After the
> first successful run, set *Settings → Pages → Source* to the `gh-pages`
> branch, and point the `marketplace.flyokai.com` DNS `CNAME` at
> `<owner>.github.io`. The `CNAME` file is written by `bin/sync-docs.sh`
> (override with the `SITE_DOMAIN` env var).

## Repo layout

```
mkdocs.yml                       Site config: theme, nav, plugins
requirements.txt                 Python deps (pinned)
bin/sync-docs.sh                 Pulls marketplace-docs/docs/ from flyokai/flyokai
.github/workflows/docs.yml       Build + deploy pipeline
.gitignore                       Ignores docs/ (generated) and site/ (built)
```
