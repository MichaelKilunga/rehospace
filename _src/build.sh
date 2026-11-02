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

# Fresh dist/ with only what the public site needs. Empty it rather than delete it,
# because a running `wrangler dev` keeps the folder open and Windows refuses the delete.
mkdir -p "$DIST"; find "$DIST" -mindepth 1 -delete; mkdir -p "$DIST/sw" "$ROOT/sw"
cp -r "$ROOT/css" "$ROOT/js" "$ROOT/lib" "$ROOT/img" "$ROOT/video" "$DIST/"
cp "$ROOT/robots.txt" "$DIST/"
cp "$ROOT/_src/static/_headers" "$ROOT/_src/static/_redirects" "$ROOT/_src/static/site.webmanifest" "$ROOT/_src/static/llms.txt" "$DIST/"
cp "$ROOT/img/icons/favicon.ico" "$DIST/favicon.ico"
# Large source images are only inputs for _src/optimize-images.mjs; the site uses the WebP versions
rm -f "$DIST/img/products/pillpointone-devices.png" "$DIST/img/products/daycaremis-poster.png" "$DIST"/img/screens/*.png

SITEMAP_ENTRIES=""
sitemap_url() {   # $1 = loc, $2 = clean path (for alternates), $3 = lastmod
    SITEMAP_ENTRIES+="  <url>
    <loc>$1</loc>
    <xhtml:link rel=\"alternate\" hreflang=\"en\" href=\"$SITE/$2\"/>
    <xhtml:link rel=\"alternate\" hreflang=\"sw\" href=\"$SITE/sw/$2\"/>
    <xhtml:link rel=\"alternate\" hreflang=\"x-default\" href=\"$SITE/$2\"/>
    <lastmod>$3</lastmod>
  </url>
"
}

# Google ignores <lastmod> when it is always "today", so use the page body's last commit date,
# or today when the body has uncommitted edits or is new.
lastmod() {
    local d
    if git -C "$ROOT" diff --quiet HEAD -- "$1" 2>/dev/null; then d="$(git -C "$ROOT" log -1 --format=%cs -- "$1" 2>/dev/null)"; fi
    echo "${d:-$TODAY}"
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
        sed -i -E 's|href="(about\|products\|services\|agents\|careers\|contact)\.html|href="/\1.html|g; s|href="index\.html|href="/|g' "$out"
        cp "$out" "$DIST/404.html"
    elif [ "$lang" = "en" ]; then
        cp "$out" "$DIST/$page"; sitemap_url "$en_url" "$clean" "$(lastmod "$src")"
    else
        cp "$out" "$DIST/sw/$page"; sitemap_url "$sw_url" "$clean" "$(lastmod "$src")"
    fi
    echo "built $lang/$page"
}

# ---------------------------------------------------------------- English (primary)
build en index.html    "Software Development Company in Tanzania | RehoSpace Enterprise" \
    "RehoSpace Enterprise is a software development company in Morogoro, Tanzania, building custom software, web and mobile apps and business systems, and training young developers across Africa."
build en about.html    "About RehoSpace Enterprise | Software Company in Morogoro, Tanzania" \
    "Software that helps Tanzanian businesses sell more and lose less: pharmacy, shop, daycare and bulk SMS systems from RehoSpace Enterprise in Morogoro."
build en products.html "Pharmacy, POS, Daycare & Bulk SMS Software in Tanzania | RehoSpace" \
    "Business software made in Tanzania: PillPointOne pharmacy management system, DaycareMIS daycare software, RehoPOS point of sale, PushSMS bulk SMS, RehoCare and a Real Estate Platform. Plans from TZS 10,000 per month."
build en services.html "Software Development Services in Tanzania | RehoSpace" \
    "Custom software development in Tanzania and across Africa: business systems, web and mobile apps, AI and automation, M-Pesa and API integrations, websites, networking and technical support."
build en careers.html  "Software Development Training & Internships in Tanzania | RehoSpace" \
    "Learn software development with RehoSpace in Morogoro or online. Hands-on courses, internships and field attachment on live products, mentorship and a path to tech jobs for young people in Tanzania and Africa."
build en agents.html   "Become a PillPointOne Agent | Earn Monthly Commission | RehoSpace" \
    "Join the PillPointOne agent network. Register pharmacies anywhere in Tanzania and earn 20% of every PillPointOne plan payment, for as long as the pharmacy keeps paying. No joining fee; open to anyone aged 18 or older."
build en contact.html  "Contact RehoSpace Enterprise | Software Company in Morogoro, Tanzania" \
    "Talk to RehoSpace. Call or WhatsApp +255 745 814 072, email info@rehospace.com, or visit us at Kihonda Mizani, Morogoro. Book a free demo of any of our systems."
build en 404.html      "Page Not Found | RehoSpace Enterprise" \
    "The page you are looking for could not be found on the RehoSpace Enterprise website."

# ---------------------------------------------------------------- Kiswahili
build sw index.html    "Kampuni ya Kutengeneza Software na Mifumo Tanzania | RehoSpace" \
    "RehoSpace Enterprise ni kampuni ya kutengeneza software na mifumo ya biashara iliyopo Morogoro, Tanzania: programu maalum, apps za wavuti na simu, PillPointOne, RehoPOS na zaidi. Pia tunawafundisha vijana software development."
build sw about.html    "Kuhusu RehoSpace Enterprise | Kampuni ya Software Morogoro, Tanzania" \
    "Software inayosaidia biashara za Tanzania kuuza zaidi na kupoteza kidogo: mifumo ya duka la dawa, maduka, daycare na SMS kwa wingi kutoka RehoSpace Enterprise, Morogoro."
build sw products.html "Mifumo ya Duka la Dawa, POS, Daycare na SMS Tanzania | RehoSpace" \
    "Software za biashara zilizotengenezwa Tanzania: PillPointOne mfumo wa duka la dawa, DaycareMIS mfumo wa daycare, RehoPOS mfumo wa mauzo, PushSMS kwa wingi, RehoCare na Jukwaa la Majengo na Viwanja. Vifurushi kuanzia TZS 10,000 kwa mwezi."
build sw services.html "Huduma za Kutengeneza Software na Mifumo Tanzania | RehoSpace" \
    "Utengenezaji wa software maalum Tanzania na Afrika: mifumo ya biashara, apps za wavuti na simu, AI na automation, M-Pesa na API, tovuti, mitandao, Wi-Fi na msaada wa kiufundi."
build sw careers.html  "Mafunzo ya Software Development, Field na Ajira kwa Vijana | RehoSpace" \
    "Jifunze software development na RehoSpace Morogoro au mtandaoni. Kozi ya vitendo, mafunzo kwa vitendo (field) na internship kwenye mifumo halisi, mentorship na njia ya ajira ya teknolojia kwa vijana Tanzania na Afrika."
build sw agents.html   "Kuwa Wakala wa PillPointOne | Kipato cha Kila Mwezi | RehoSpace" \
    "Jiunge na mtandao wa mawakala wa PillPointOne. Sajili maduka ya dawa popote Tanzania na upate 20% ya kila malipo ya vifurushi vya PillPointOne, kila mwezi duka linapolipa. Hakuna ada ya kujiunga; umri miaka 18 au zaidi."
build sw contact.html  "Wasiliana na RehoSpace Enterprise | Kampuni ya Software Morogoro" \
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
