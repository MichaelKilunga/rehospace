# RehoSpace Enterprise — Company Website

Public website for RehoSpace Enterprise (rehospace.com). Static, bilingual front-end (English primary, Kiswahili at `/sw/`), hosted on Cloudflare Workers static assets. Built to be upgraded to a dynamic platform (public site + customer portal + admin) later.

## Structure

```
index.html, about.html, products.html, services.html, careers.html, agents.html, contact.html, 404.html   built English pages (do not edit)
sw/*.html                 built Kiswahili pages (do not edit)
_src/pages/en/, _src/pages/sw/   page bodies — edit content here
_src/partials/en/, _src/partials/sw/   head (meta, structured data, topbar, navbar) and footer per language
_src/partials/mountains.svg
_src/static/              Cloudflare _headers and _redirects, site.webmanifest, llms.txt (copied to the site root)
_src/build.sh             assembles pages, writes sitemap.xml, stages dist/
_src/optimize-images.mjs  creates WebP versions, the 1200x630 share image and the favicons (node, uses sharp)
css/style.css             all site styling (brand tokens at the top)
js/main.js                spinner, sticky header, counters, nav highlight, bilingual contact form
img/                      brand assets, img/products/ (logos, WebP derivatives), img/screens/ (real product screens), img/icons/ (favicons)
video/                    short silent product clips (MP4) with a WebP still frame each
dist/                     deploy folder (generated, ignored by git)
wrangler.toml             Cloudflare Workers config (custom domains rehospace.com + www)
```

## Editing content

1. Edit the page body in `_src/pages/<lang>/<page>.html`, or the shared header/footer in `_src/partials/<lang>/`.
2. Page titles and meta descriptions live in `_src/build.sh` (one `build` line per page and language).
3. Rebuild and preview locally, then deploy:

```
npm run build      # rebuilds pages + sitemap + dist/
npm run preview    # local server via wrangler dev
npm run deploy     # build + wrangler deploy (needs: npx wrangler login)
```

Keep both languages in sync: every English page has a Swahili twin with the same file name, which the build links through `hreflang` tags, the language switch and the sitemap.

## Images

Put originals in `img/` or `img/products/`, add a line to `_src/optimize-images.mjs`, then run `node _src/optimize-images.mjs`. Reference the `.webp` output in pages with `{{BASE}}img/...` (the build turns `{{BASE}}` into `../` for Swahili pages).

Product screenshots in `img/screens/` come from the system profiles on the company drive (`MARKETING\<PRODUCT>\System Profile Source\img`) and show demo data. The PNGs stay in git as sources; only the WebP versions are deployed. Use real screens and real photos, never AI-generated pictures of people.

## Video

The clips in `video/` are the November 2026 social media clips (`MARKETING\...\Social Media - Novemba 2026`), re-encoded for the web: 540x960, H.264, no audio, about 300 KB each. Each has a `.webp` still frame used as the poster:

```
ffmpeg -i source.mp4 -an -vf scale=540:960 -c:v libx264 -profile:v main -pix_fmt yuv420p -preset slow -crf 30 -movflags +faststart video/name.mp4
ffmpeg -ss 5 -i video/name.mp4 -frames:v 1 -c:v libwebp -quality 72 video/name.webp
```

Use them in pages as `<div class="clip"><video muted loop playsinline preload="none" poster="{{BASE}}video/name.webp" aria-label="What the clip shows"><source src="{{BASE}}video/name.mp4" type="video/mp4"></video></div>`. `js/main.js` adds the play/pause button, plays a clip only while it is on screen, and never autoplays for visitors with reduced motion or data saver on.

## SEO

Per page: canonical URL, `hreflang` alternates (en, sw, x-default), Open Graph and Twitter cards, JSON-LD (Organization, WebSite, BreadcrumbList, product ItemList, Service, Course, FAQPage, AboutPage, ContactPage). Site-wide: `robots.txt`, generated `sitemap.xml` with language alternates, security and caching headers in `_headers`, clean URLs (`/about`, `/sw/about`), square favicons, and `llms.txt` (a plain summary for AI search assistants).

Each page targets one main search phrase, used in its title (in `_src/build.sh`), H1 and opening paragraph:

| Page | English target | Kiswahili target |
| --- | --- | --- |
| Home | software development company in Tanzania | kampuni ya kutengeneza software Tanzania |
| Services | software development services in Tanzania | huduma za kutengeneza software |
| Careers | software development training and internships in Tanzania | mafunzo ya software development, field na ajira kwa vijana |
| Products | pharmacy, POS, daycare and bulk SMS software in Tanzania | mfumo wa duka la dawa, POS, daycare na SMS |
| Agents | PillPointOne agent, monthly commission | wakala wa PillPointOne |

The FAQ sections on services, careers and agents are repeated as FAQPage JSON-LD at the bottom of each page body. Change both together.

`<lastmod>` in the sitemap is the last commit date of each page body, so commit content changes before deploying.

After deploying, submit `https://rehospace.com/sitemap.xml` in Google Search Console and Bing Webmaster Tools.

## Contact form

No backend yet. "Send via WhatsApp" opens wa.me with the message prefilled; "Send via Email" opens the visitor's mail app. Number and email are set near the form code in `js/main.js`.

&copy; RehoSpace Enterprise. All rights reserved.
