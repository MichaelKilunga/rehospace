// Creates optimised WebP versions of the brand and product images, the social
// sharing image and the square favicons.
// Run: node _src/optimize-images.mjs   (from the project root)
import sharp from "sharp";
import { mkdir, writeFile } from "node:fs/promises";

const jobs = [
    // [source, destination, max width, quality]
    ["img/logo.jpg", "img/logo.webp", 400, 85],
    ["img/logo-icon.jpg", "img/logo-icon.webp", 240, 85],
    ["img/brand-cover.jpg", "img/brand-cover.webp", 1200, 80],
    ["img/products/pillpointone-logo.png", "img/products/pillpointone-logo.webp", 200, 85],
    ["img/products/rehopos-logo.png", "img/products/rehopos-logo.webp", 200, 85],
    ["img/products/daycaremis-logo.png", "img/products/daycaremis-logo.webp", 240, 85],
    ["img/products/pillpointone-devices.png", "img/products/pillpointone-devices.webp", 1400, 78],
    ["img/products/daycaremis-poster.png", "img/products/daycaremis-poster.webp", 1000, 78],
    // Real product screens (demo data), shown in browser and phone frames. The PNGs are not deployed.
    ["img/screens/pp-dashboard.png", "img/screens/pp-dashboard.webp", 1280, 76],
    ["img/screens/pp-pos.png", "img/screens/pp-pos.webp", 1280, 76],
    ["img/screens/pp-expiry.png", "img/screens/pp-expiry.webp", 1280, 76],
    ["img/screens/pp-agent.png", "img/screens/pp-agent.webp", 480, 78],
    ["img/screens/dc-dashboard.png", "img/screens/dc-dashboard.webp", 1280, 76],
    ["img/screens/ps-dashboard.png", "img/screens/ps-dashboard.webp", 1280, 76],
];

await mkdir("img/products", { recursive: true });
await mkdir("img/icons", { recursive: true });
for (const [src, dest, width, quality] of jobs) {
    const img = sharp(src);
    const meta = await img.metadata();
    let pipeline = img.resize({ width: Math.min(width, meta.width), withoutEnlargement: true });
    if (dest.endsWith(".webp")) pipeline = pipeline.webp({ quality });
    else pipeline = pipeline.jpeg({ quality, mozjpeg: true });
    const info = await pipeline.toFile(dest);
    console.log(`${dest.padEnd(44)} ${info.width}x${info.height}  ${(info.size / 1024).toFixed(0)} KB  (from ${(meta.size / 1024).toFixed(0)} KB)`);
}

// Social sharing image: 1200x630 is the Open Graph size Facebook, WhatsApp and LinkedIn expect.
// The cover is wider than 1.91:1, so crop the sides around the logo and slogan (this also drops
// the small duplicate logo in the bottom-right corner).
const og = await sharp("img/brand-cover.jpg")
    .extract({ left: 230, top: 0, width: 1265, height: 664 })
    .resize(1200, 630)
    .jpeg({ quality: 82, mozjpeg: true })
    .toFile("img/og-image.jpg");
console.log(`${"img/og-image.jpg".padEnd(44)} ${og.width}x${og.height}  ${(og.size / 1024).toFixed(0)} KB`);

// Favicons: Google Search only shows square favicons, so place the mountain mark from the
// logo on a white square. favicon.ico holds 16/32/48 px PNGs; the build copies it to the site root.
const WHITE = { r: 255, g: 255, b: 255, alpha: 1 };
const mark = await sharp("img/logo.jpg").extract({ left: 40, top: 200, width: 1000, height: 400 }).toBuffer();
async function icon(size) {
    const inner = Math.round(size * 0.9), pad = Math.floor((size - inner) / 2);
    return sharp(mark)
        .resize(inner, inner, { fit: "contain", background: WHITE })
        .extend({ top: pad, bottom: size - inner - pad, left: pad, right: size - inner - pad, background: WHITE })
        .png()
        .toBuffer();
}
for (const [size, dest] of [[192, "img/icons/icon-192.png"], [512, "img/icons/icon-512.png"], [180, "img/icons/apple-touch-icon.png"]]) {
    await writeFile(dest, await icon(size));
    console.log(`${dest.padEnd(44)} ${size}x${size}`);
}
const icoSizes = [16, 32, 48];
const pngs = await Promise.all(icoSizes.map(icon));
const header = Buffer.alloc(6 + 16 * pngs.length);
header.writeUInt16LE(0, 0); header.writeUInt16LE(1, 2); header.writeUInt16LE(pngs.length, 4);
let offset = header.length;
pngs.forEach((png, i) => {
    const e = 6 + 16 * i;
    header.writeUInt8(icoSizes[i], e); header.writeUInt8(icoSizes[i], e + 1);
    header.writeUInt16LE(1, e + 4); header.writeUInt16LE(32, e + 6);
    header.writeUInt32LE(png.length, e + 8); header.writeUInt32LE(offset, e + 12);
    offset += png.length;
});
await writeFile("img/icons/favicon.ico", Buffer.concat([header, ...pngs]));
console.log(`${"img/icons/favicon.ico".padEnd(44)} ${icoSizes.join("/")} px`);
