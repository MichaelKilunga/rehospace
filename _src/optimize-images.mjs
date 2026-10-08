// Creates optimised WebP versions of the brand and product images.
// Run: node _src/optimize-images.mjs   (from the project root)
import sharp from "sharp";
import { mkdir } from "node:fs/promises";

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
    // Social sharing image (JPEG, 1200x630 is the standard Open Graph size)
    ["img/brand-cover.jpg", "img/og-image.jpg", 1200, 82],
];

await mkdir("img/products", { recursive: true });
for (const [src, dest, width, quality] of jobs) {
    const img = sharp(src);
    const meta = await img.metadata();
    let pipeline = img.resize({ width: Math.min(width, meta.width), withoutEnlargement: true });
    if (dest.endsWith(".webp")) pipeline = pipeline.webp({ quality });
    else pipeline = pipeline.jpeg({ quality, mozjpeg: true });
    const info = await pipeline.toFile(dest);
    console.log(`${dest.padEnd(44)} ${info.width}x${info.height}  ${(info.size / 1024).toFixed(0)} KB  (from ${(meta.size / 1024).toFixed(0)} KB)`);
}
