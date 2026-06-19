# Legacy Systems — Writers' Room (Phase 2)

Collaborative web app for Jimmy + Ryan to write the movie *Legacy Systems*.
Single-file `index.html` (React + Supabase via CDN, no build step). Backend: **cannoncodeconnect** Supabase, tables prefixed `LS_`.

This phase ships: magic-link auth, **Overview**, and **Characters** (inline editing, live DB). Arcs / Timeline / The Clock / Connections / Scenes / Themes / Activity are stubbed and tabbed off — their tables are already seeded for the next phase.

---

## Go live — 3 steps (no terminal)

### 1. Create the tables + seed data
Supabase dashboard → **SQL Editor** → New query → paste all of `schema.sql` → **Run**.
Safe to re-run (it drops & recreates only the `LS_` tables). Seeds 13 characters, 4 factions, 3 systems, themes and the 5 pitch scenes from the story bible.

### 2. Turn on magic-link email
Supabase dashboard → **Authentication** → **Providers** → **Email** → make sure **Enable Email provider** is on and **Confirm email** / magic link is enabled (it is by default). No other provider needed.

### 3. Open the app
- Quick test: double-click `index.html` to open it in your browser, enter `wcannon83@gmail.com`, click the magic link in your inbox.
- To share with Ryan: drag the **`index.html` file** onto [Netlify Drop](https://app.netlify.com/drop) — gives you a public URL. (One file, no build.)

> Magic link redirects back to wherever the page is loaded — works for both the local file and the Netlify URL.

---

## Adding Ryan later
Open `index.html`, find the `WHITELIST` array near the top, add his email (lowercase), save, and re-drop on Netlify:
```js
WHITELIST: [
  "wcannon83@gmail.com",
  "ryans-email@example.com"
]
```
The whitelist is enforced in the app before the magic link is sent.

---

## Files
- `index.html` — the app (config + whitelist live at the very top)
- `schema.sql` — tables, RLS, and seed data
- `README.md` — this file
