# Ejari company site (`promo/`)

Public face for domain, LinkedIn, and Facebook. Arabic by default (RTL), English via toggle.

**Live:** https://m7moud2.github.io/ejari-web/promo/

English deep link: https://m7moud2.github.io/ejari-web/promo/?lang=en

## Language

- Default: Arabic (`lang=ar`, `dir=rtl`)
- Toggle **عربي | English** in the header (saved in `localStorage` as `ejari_promo_lang`)
- Deep link: `?lang=en` or `?lang=ar`
- Strings live in `js/i18n.js` — keep both languages in sync there
- Legal pages (`docs/privacy.html`, `docs/terms.html`) have their own AR/EN toggle (`ejari_legal_lang`)

## Download

APK (keep this URL until the next release):

`https://github.com/m7moud2/ejari-web/releases/download/v1.3.9/ejari-1.3.9.apk`

Install help: [download.html](./download.html)  
Download counter: Firestore `public_stats/downloads` via `js/download-stats.js`

## SEO (repo root)

GitHub Pages serves from the **repo root**, so these live at the site root:

| File | Purpose |
|------|---------|
| `/robots.txt` | Allow crawl + sitemap pointer |
| `/sitemap.xml` | Promo AR/EN (`?lang=en`), download, privacy, terms |

After a custom domain, update the absolute URLs inside both files and the `canonical` / `og:*` tags in HTML.

## Custom domain (GitHub Pages)

This folder is published from the repo root under `/promo/`.

### Option A — keep path `/promo/`

1. In the repo: **Settings → Pages** → source = `main` / root (current setup).
2. Add a custom domain (e.g. `ejari.app`).
3. Update every `canonical`, `og:url`, and `og:image` in `index.html` / `download.html` from  
   `https://m7moud2.github.io/ejari-web/promo/`  
   to  
   `https://YOUR-DOMAIN/promo/`  
   (or `https://YOUR-DOMAIN/` if you later make `promo/` the site root).
4. Update `robots.txt` sitemap URL and every `<loc>` in `sitemap.xml` to the new domain.

### Option B — serve `promo/` as the site root

1. Move or copy `promo/` contents to a dedicated Pages branch / folder configured as the Pages root, **or**
2. Add a root redirect/`index.html` that points visitors to `/promo/`.
3. Update canonical + OG + sitemap URLs to the bare domain.

DNS: add the `A` / `CNAME` records GitHub shows for Pages. Enable HTTPS after DNS propagates.

## Brand

- Green `#0F3A30` · Gold `#B58D3D`
- Share image: `assets/og-cover.jpg` (1200×630)
- Favicon: `assets/favicon.svg` (+ PNG fallback)

## Founder placeholders (do not invent)

Footer / About show **Cairo, Egypt** only. In `index.html`, HTML comments mark where to fill:

- Legal company name → `[data-founder="legal-name"]` (remove `hidden`, add text)
- Commercial registry → `[data-founder="registry"]`
- Street address → `[data-founder="street"]`

Also replace illustrative unit photos with official ones when ready.
