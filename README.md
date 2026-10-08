# RehoSpace Enterprise — Company Website

Public website for RehoSpace Enterprise (rehospace.com). Static, bilingual front-end (English primary, Kiswahili at `/sw/`), hosted on Cloudflare Workers static assets. Built to be upgraded to a dynamic platform (public site + customer portal + admin) later.

## Structure

```
index.html, about.html, products.html, services.html, contact.html, 404.html   built English pages (do not edit)
sw/*.html                 built Kiswahili pages (do not edit)
_src/pages/en/, _src/pages/sw/   page bodies — edit content here
_src/partials/en/, _src/partials/sw/   head (meta, structured data, topbar, navbar) and footer per language
_src/partials/mountains.svg
_src/static/_headers, _redirects   Cloudflare headers and redirects
_src/build.sh             assembles pages, writes sitemap.xml, stages dist/
_src/optimize-images.mjs  creates WebP versions of brand/product images (node, uses sharp)
css/style.css             all site styling (brand tokens at the top)
js/main.js                spinner, sticky header, counters, nav highlight, bilingual contact form
img/                      brand assets and img/products/ (logos, screenshots, WebP derivatives)
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

## SEO

Per page: canonical URL, `hreflang` alternates (en, sw, x-default), Open Graph and Twitter cards, JSON-LD (Organization, WebSite, BreadcrumbList, product ItemList, Service, AboutPage, ContactPage). Site-wide: `robots.txt`, generated `sitemap.xml` with language alternates, security and caching headers in `_headers`, clean URLs (`/about`, `/sw/about`).

After deploying, submit `https://rehospace.com/sitemap.xml` in Google Search Console and Bing Webmaster Tools.

## Contact form

No backend yet. "Send via WhatsApp" opens wa.me with the message prefilled; "Send via Email" opens the visitor's mail app. Number and email are set near the form code in `js/main.js`.

&copy; RehoSpace Enterprise. All rights reserved.
