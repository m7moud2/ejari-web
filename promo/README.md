# Ejari company site (`promo/`)

Public face for domain, LinkedIn, and Facebook. Arabic by default (RTL), English via toggle.

**Live:** https://m7moud2.github.io/ejari-web/promo/

## Language

- Default: Arabic (`lang=ar`, `dir=rtl`)
- Toggle **عربي | English** in the header (saved in `localStorage` as `ejari_promo_lang`)
- Deep link: `?lang=en` or `?lang=ar`
- Strings live in `js/i18n.js` — keep both languages in sync there

## Download

APK (keep this URL until the next release):

`https://github.com/m7moud2/ejari-web/releases/download/v1.3.5/ejari-1.3.5.apk`

Install help: [download.html](./download.html)  
Download counter: Firestore `public_stats/downloads` via `js/download-stats.js`

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

### Option B — serve `promo/` as the site root

1. Move or copy `promo/` contents to a dedicated Pages branch / folder configured as the Pages root, **or**
2. Add a root redirect/`index.html` that points visitors to `/promo/`.
3. Update canonical + OG URLs to the bare domain.

DNS: add the `A` / `CNAME` records GitHub shows for Pages. Enable HTTPS after DNS propagates.

## Brand

- Green `#0F3A30` · Gold `#B58D3D`
- Share image: `assets/og-cover.jpg` (1200×630)
- Favicon: `assets/favicon.svg` (+ PNG fallback)

## Address placeholder

Footer address is intentionally a founder placeholder — do not invent registration numbers or street addresses.
