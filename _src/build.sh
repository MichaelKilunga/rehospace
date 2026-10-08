#!/usr/bin/env bash
# Assembles the public pages (English at the root, Swahili under /sw/) from
# _src/pages/<lang>/*.html and the shared partials, then stages a deployable dist/.
# Usage: bash _src/build.sh   (run from the project root)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/_src/partials"
SITE="https://rehospace.com"
TODAY="$(date +%Y-%m-%d)"
DIST="$ROOT/dist"

# Literal (non-regex) placeholder replacement so titles may contain |, &, . etc.
AWK_REPLACE='
function rep(s, pat, val,    i, out) {
    out = ""
    while ((i = index(s, pat)) > 0) { out = out substr(s, 1, i - 1) val; s = substr(s, i + length(pat)) }
    return out s
}
{
    line = $0
    line = rep(line, "{{TITLE}}", title)
    line = rep(line, "{{DESC}}", desc)
    line = rep(line, "{{PAGE}}", page)
    line = rep(line, "{{CANON_URL}}", canon_url)
    line = rep(line, "{{EN_URL}}", en_url)
    line = rep(line, "{{SW_URL}}", sw_url)
    line = rep(line, "{{ALT_URL}}", alt_url)
    line = rep(line, "{{BASE}}", base)
    if (index(line, "{{MOUNTAINS}}") > 0) { print svg } else { print line }
}'

# Fresh dist/ with only what the public site needs
rm -rf "$DIST"; mkdir -p "$DIST/sw" "$ROOT/sw"
cp -r "$ROOT/css" "$ROOT/js" "$ROOT/lib" "$ROOT/img" "$DIST/"
cp "$ROOT/robots.txt" "$DIST/"
cp "$ROOT/_src/static/_headers" "$ROOT/_src/static/_redirects" "$DIST/"
# Large source images are only inputs for _src/optimize-images.mjs; the site uses the WebP versions
rm -f "$DIST/img/products/pillpointone-devices.png" "$DIST/img/products/daycaremis-poster.png"

SITEMAP_ENTRIES=""
sitemap_url() {   # $1 = loc, $2 = clean path (for alternates)
    SITEMAP_ENTRIES+="  <url>
    <loc>$1</loc>
    <xhtml:link rel=\"alternate\" hreflang=\"en\" href=\"$SITE/$2\"/>
    <xhtml:link rel=\"alternate\" hreflang=\"sw\" href=\"$SITE/sw/$2\"/>
    <xhtml:link rel=\"alternate\" hreflang=\"x-default\" href=\"$SITE/$2\"/>
    <lastmod>$TODAY</lastmod>
  </url>
"
}

build() {   # build <lang> <page> <title> <description>
    local lang="$1" page="$2" title="$3" desc="$4"
    local src="$ROOT/_src/pages/$lang/$page"
    local svg; svg="$(cat "$P/mountains.svg")"
    local clean="${page%.html}"; [ "$clean" = "index" ] && clean=""
    local en_url="$SITE/$clean" sw_url="$SITE/sw/$clean"
    local out base canon_url alt_url
    if [ "$lang" = "en" ]; then
        out="$ROOT/$page"; base=""; canon_url="$en_url"; alt_url="sw/$page"
    else
        out="$ROOT/sw/$page"; base="../"; canon_url="$sw_url"; alt_url="../$page"
    fi
    # The 404 page is served at any path, so it must use root-absolute links
    if [ "$page" = "404.html" ]; then base="/"; alt_url="/sw/"; fi

    cat "$P/$lang/head.html" "$src" "$P/$lang/footer.html" \
        | awk -v title="$title" -v desc="$desc" -v page="$page" -v canon_url="$canon_url" \
              -v en_url="$en_url" -v sw_url="$sw_url" -v alt_url="$alt_url" -v base="$base" -v svg="$svg" \
              "$AWK_REPLACE" > "$out"

    if [ "$page" = "404.html" ]; then
        sed -i -E 's|href="(about\|products\|services\|contact)\.html|href="/\1.html|g; s|href="index\.html|href="/|g' "$out"
        cp "$out" "$DIST/404.html"
    elif [ "$lang" = "en" ]; then
        cp "$out" "$DIST/$page"; sitemap_url "$en_url" "$clean"
    else
        cp "$out" "$DIST/sw/$page"; sitemap_url "$sw_url" "$clean"
    fi
    echo "built $lang/$page"
}

# ---------------------------------------------------------------- English (primary)
build en index.html    "RehoSpace Enterprise | Digital Products & Intelligent Business Systems in Tanzania" \
    "RehoSpace Enterprise builds digital products and intelligent business systems for pharmacies, shops, daycares, clinics and growing organisations in Tanzania. PillPointOne, DaycareMIS, RehoPOS, SkyPush and custom software."
build en about.html    "About RehoSpace Enterprise | Technology Company in Morogoro, Tanzania" \
    "Learn who RehoSpace Enterprise is: a Morogoro-based technology company creating digital space for businesses and organisations to grow. Our story, vision, mission and values."
build en products.html "Our Products | PillPointOne, DaycareMIS, RehoPOS, SkyPush | RehoSpace" \
    "Explore RehoSpace products: PillPointOne pharmacy management, DaycareMIS daycare management, RehoPOS retail POS, SkyPush bulk SMS, RehoCare and the RehoSpace Real Estate Platform. Plans from TZS 10,000 per month."
build en services.html "Our Services | Custom Software, Business Systems, Automation & IT | RehoSpace" \
    "Custom software development, business management systems, web and mobile apps, AI and automation, payment and API integrations, networking and Wi-Fi portals, websites, digital marketing and technical support in Tanzania."
build en contact.html  "Contact RehoSpace Enterprise | Morogoro, Tanzania" \
    "Talk to RehoSpace. Call or WhatsApp +255 745 814 072, email info@rehospace.com, or visit us at Kihonda Mizani, Morogoro. Book a free demo of any of our systems."
build en 404.html      "Page Not Found | RehoSpace Enterprise" \
    "The page you are looking for could not be found on the RehoSpace Enterprise website."

# ---------------------------------------------------------------- Kiswahili
build sw index.html    "RehoSpace Enterprise | Bidhaa za Kidijitali na Mifumo ya Biashara Tanzania" \
    "RehoSpace Enterprise inatengeneza bidhaa za kidijitali na mifumo ya biashara yenye akili kwa maduka ya dawa, maduka, daycare, zahanati na taasisi zinazokua Tanzania. PillPointOne, DaycareMIS, RehoPOS, SkyPush na programu maalum."
build sw about.html    "Kuhusu RehoSpace Enterprise | Kampuni ya Teknolojia Morogoro, Tanzania" \
    "Fahamu RehoSpace Enterprise: kampuni ya teknolojia iliyopo Morogoro inayotengeneza nafasi ya kidijitali kwa biashara na taasisi kukua. Historia yetu, dira, dhamira na maadili."
build sw products.html "Bidhaa Zetu | PillPointOne, DaycareMIS, RehoPOS, SkyPush | RehoSpace" \
    "Tazama bidhaa za RehoSpace: PillPointOne mfumo wa duka la dawa, DaycareMIS mfumo wa daycare, RehoPOS mfumo wa mauzo, SkyPush SMS kwa wingi, RehoCare na Jukwaa la Majengo na Viwanja. Vifurushi kuanzia TZS 10,000 kwa mwezi."
build sw services.html "Huduma Zetu | Programu Maalum, Mifumo ya Biashara, Automation na IT | RehoSpace" \
    "Utengenezaji wa programu maalum, mifumo ya usimamizi wa biashara, programu za wavuti na simu, AI na automation, miunganisho ya malipo na API, mitandao na Wi-Fi, tovuti, masoko ya kidijitali na msaada wa kiufundi Tanzania."
build sw contact.html  "Wasiliana na RehoSpace Enterprise | Morogoro, Tanzania" \
    "Zungumza na RehoSpace. Piga au WhatsApp +255 745 814 072, barua pepe info@rehospace.com, au tutembelee Kihonda Mizani, Morogoro. Omba demo ya bure ya mfumo wowote wetu."

# ---------------------------------------------------------------- Sitemap (both languages, with hreflang alternates)
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">'
    printf '%s' "$SITEMAP_ENTRIES"
    echo '</urlset>'
} > "$ROOT/sitemap.xml"
cp "$ROOT/sitemap.xml" "$DIST/sitemap.xml"
echo "sitemap.xml written ($(grep -c '<loc>' "$ROOT/sitemap.xml") URLs)"
