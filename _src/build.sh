#!/usr/bin/env bash
# Assembles the public pages from _src/pages/*.html and the shared partials.
# Usage: bash _src/build.sh   (run from the project root)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/_src/partials"

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
    line = rep(line, "{{CANON}}", canon)
    if (index(line, "{{MOUNTAINS}}") > 0) { print svg } else { print line }
}'

build() {
    local page="$1" title="$2" desc="$3"
    local src="$ROOT/_src/pages/$page" out="$ROOT/$page"
    local svg; svg="$(cat "$P/mountains.svg")"
    # Clean URL used for canonical/og:url (Cloudflare Pages serves about.html as /about)
    local canon="${page%.html}"; [ "$canon" = "index" ] && canon=""
    cat "$P/head.html" "$src" "$P/footer.html" \
        | awk -v title="$title" -v desc="$desc" -v page="$page" -v canon="$canon" -v svg="$svg" "$AWK_REPLACE" > "$out"
    cp "$out" "$DIST/$page"
    echo "built $page"
}

# Deployable copy: only what the public site needs (no _src, no config files)
DIST="$ROOT/dist"
rm -rf "$DIST"; mkdir -p "$DIST"
cp -r "$ROOT/css" "$ROOT/js" "$ROOT/lib" "$ROOT/img" "$DIST/"
cp "$ROOT/robots.txt" "$ROOT/sitemap.xml" "$DIST/"
cp "$ROOT/_src/static/_headers" "$ROOT/_src/static/_redirects" "$DIST/"

build index.html    "RehoSpace Enterprise | Digital Products & Intelligent Business Systems in Tanzania" \
    "RehoSpace Enterprise builds digital products and intelligent business systems for pharmacies, shops, daycares, clinics and growing organisations in Tanzania. PillPointOne, DaycareMIS, RehoPOS and custom software."
build about.html    "About RehoSpace Enterprise | Enhancing Life Digitally" \
    "Learn who RehoSpace Enterprise is: a Morogoro-based technology company creating digital space for businesses and organisations to grow. Our story, vision, mission and values."
build products.html "Our Products | PillPointOne, DaycareMIS, RehoPOS & More | RehoSpace" \
    "Explore RehoSpace products: PillPointOne pharmacy management, DaycareMIS daycare management, RehoPOS retail POS, SkyPush bulk SMS, RehoCare and the RehoSpace Real Estate Platform. Plans from TZS 10,000 per month."
build services.html "Our Services | Custom Software, Business Systems, Automation & IT | RehoSpace" \
    "Custom software development, business management systems, web and mobile apps, AI and automation, payment and API integrations, networking and Wi-Fi portals, websites, digital marketing and technical support."
build contact.html  "Contact RehoSpace Enterprise | Morogoro, Tanzania" \
    "Talk to RehoSpace. Call or WhatsApp +255 745 814 072, email info@rehospace.com, or visit us at Kihonda Mizani, Morogoro. Book a free demo of any of our systems."
build 404.html      "Page Not Found | RehoSpace Enterprise" \
    "The page you are looking for could not be found on the RehoSpace Enterprise website."
