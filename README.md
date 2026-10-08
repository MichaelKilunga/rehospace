# RehoSpace Enterprise — Company Website

Public website for RehoSpace Enterprise (rehospace.com). Static front-end, built to be upgraded to a dynamic platform (public site + customer portal + admin) later.

## Structure

```
index.html, about.html, products.html, services.html, contact.html   built pages (do not edit directly)
_src/partials/   head.html (meta, topbar, navbar), footer.html, mountains.svg
_src/pages/      page bodies — edit content here
_src/build.sh    assembles pages: partials + page body
css/style.css    all site styling (brand tokens at the top)
css/bootstrap.min.css   Bootstrap 5.3.3 (MIT)
js/main.js       spinner, sticky header, counters, nav highlight, contact form
js/bootstrap.bundle.min.js
lib/wow, lib/animate, lib/easing, lib/waypoints   MIT-licensed animation helpers
img/             brand assets (logo, cover) and img/products/ (product logos, screenshots)
robots.txt, sitemap.xml
```

## Editing content

1. Edit the page body in `_src/pages/<page>.html`, or the shared header/footer in `_src/partials/`.
2. Page titles and meta descriptions live in `_src/build.sh`.
3. Rebuild from the project root:

```
bash _src/build.sh
```

## Contact form

The form has no backend yet. "Send via WhatsApp" opens wa.me with the message prefilled; "Send via Email" opens the visitor's mail app. The WhatsApp number and email are set at the top of the form section in `js/main.js`.

## Brand

Colours are CSS variables at the top of `css/style.css` (`--rs-purple`, `--rs-violet`, `--rs-lilac`...). Fonts: Poppins (headings) and Inter (body).

&copy; RehoSpace Enterprise. All rights reserved.
