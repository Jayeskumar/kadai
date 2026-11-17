#!/usr/bin/env node
/**
 * Renders the branded images of KadaiSetup.exe from the Kadai logo (apps/web/public/favicon.svg)
 * and the app's own fonts (Inter, Noto Sans Tamil), so the installer looks like the product:
 *
 *   wizard-<w>x<h>.bmp   welcome / finish banner (Inno Setup WizardImageFile), 100/150/200 % DPI
 *   small-<w>x<h>.bmp    page header logo (WizardSmallImageFile), 100/150/200 % DPI
 *   kadai.ico            setup, uninstaller and shortcut icon (16 ... 256 px, PNG entries)
 *
 * The outputs are committed (Inno Setup needs no browser on the Windows build machine). Re-run
 * after a logo or colour change, from the repository root:
 *
 *   node deploy/onprem/windows/installer/assets/render-assets.mjs
 */
/* global document, Image -- used inside page.evaluate (runs in the browser) */
import { Buffer } from 'node:buffer'
import { readFileSync, writeFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath, pathToFileURL } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '../../../../..')
const webModules = path.join(root, 'apps/web/node_modules')
const require = createRequire(path.join(root, 'apps/web/package.json'))
const { chromium } = require('playwright')

const logo = readFileSync(path.join(root, 'apps/web/public/favicon.svg'), 'utf8')
const font = (rel) => pathToFileURL(path.join(webModules, rel)).href
const FONTS = `
@font-face { font-family: Inter; font-weight: 100 900;
  src: url(${font('@fontsource-variable/inter/files/inter-latin-wght-normal.woff2')}) format('woff2'); }
@font-face { font-family: 'Noto Sans Tamil'; font-weight: 600;
  src: url(${font('@fontsource/noto-sans-tamil/files/noto-sans-tamil-tamil-600-normal.woff2')}) format('woff2'); }
@font-face { font-family: 'Noto Sans Tamil'; font-weight: 700;
  src: url(${font('@fontsource/noto-sans-tamil/files/noto-sans-tamil-tamil-700-normal.woff2')}) format('woff2'); }
`

/** Welcome / finish banner, designed at 164 x 314 and scaled with `s`. */
function bannerHtml(w, h) {
  const s = w / 164
  return `<!doctype html><html><head><meta charset="utf-8"><style>${FONTS}
  html,body{margin:0;width:${w}px;height:${h}px;overflow:hidden}
  body{background:linear-gradient(160deg,#14B8A6 0%,#0F766E 46%,#134E4A 100%);font-family:Inter,sans-serif;color:#fff;position:relative}
  .glow{position:absolute;left:${-40 * s}px;top:${-50 * s}px;width:${220 * s}px;height:${220 * s}px;border-radius:50%;
    background:radial-gradient(circle,rgba(255,255,255,.22),rgba(255,255,255,0) 70%)}
  .logo{position:absolute;left:${24 * s}px;top:${30 * s}px;width:${64 * s}px;height:${64 * s}px;
    border-radius:${14.5 * s}px;box-shadow:0 0 0 ${2 * s}px rgba(255,255,255,.4),0 ${4 * s}px ${12 * s}px rgba(4,47,46,.5)}
  .logo svg{width:100%;height:100%}
  .ta{position:absolute;left:${22 * s}px;top:${112 * s}px;font:700 ${40 * s}px/1 'Noto Sans Tamil';letter-spacing:${-0.5 * s}px}
  .en{position:absolute;left:${24 * s}px;top:${164 * s}px;font-weight:700;font-size:${19 * s}px;letter-spacing:${-0.3 * s}px}
  .sub{position:absolute;left:${24 * s}px;top:${190 * s}px;font-weight:500;font-size:${10.5 * s}px;letter-spacing:${0.6 * s}px;
    text-transform:uppercase;color:#CCFBF1}
  .tags{position:absolute;left:${24 * s}px;right:${16 * s}px;top:${220 * s}px;display:flex;flex-wrap:wrap;gap:${5 * s}px}
  .tags span{font-weight:600;font-size:${9.5 * s}px;padding:${3 * s}px ${7 * s}px;border-radius:${999 * s}px;
    background:rgba(255,255,255,.14);border:${1 * s}px solid rgba(255,255,255,.25)}
  .awning{position:absolute;left:0;right:0;bottom:0;height:${26 * s}px;
    background:repeating-linear-gradient(90deg,#F59E0B 0 ${20 * s}px,#FFFBEB ${20 * s}px ${40 * s}px)}
  .awning:after{content:'';position:absolute;left:0;right:0;top:${-6 * s}px;height:${6 * s}px;background:#FDE68A}
  </style></head><body>
  <div class="glow"></div>
  <div class="logo">${logo}</div>
  <div class="ta">கடை</div>
  <div class="en">Kadai Server</div>
  <div class="sub">Shop PC installer</div>
  <div class="tags"><span>Billing</span><span>Stock</span><span>GST</span><span>UPI</span><span>Khata</span></div>
  <div class="awning"></div>
  </body></html>`
}

/** Header logo on the white wizard header. */
function smallHtml(w, h) {
  const size = Math.min(w, h) * 0.9
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;width:${w}px;height:${h}px;overflow:hidden;background:#fff}
  div{position:absolute;left:${(w - size) / 2}px;top:${(h - size) / 2}px;width:${size}px;height:${size}px}
  svg{width:100%;height:100%}</style></head><body><div>${logo}</div></body></html>`
}

function iconHtml(px) {
  return `<!doctype html><html><head><style>
  html,body{margin:0;width:${px}px;height:${px}px;overflow:hidden;background:transparent}
  svg{width:100%;height:100%;display:block}</style></head><body>${logo}</body></html>`
}

/** 24-bit bottom-up BMP from RGBA pixels (alpha ignored: images are opaque). */
function bmp24(w, h, rgba) {
  const rowSize = Math.ceil((w * 3) / 4) * 4
  const size = 54 + rowSize * h
  const b = Buffer.alloc(size)
  b.write('BM', 0)
  b.writeUInt32LE(size, 2)
  b.writeUInt32LE(54, 10)
  b.writeUInt32LE(40, 14)
  b.writeInt32LE(w, 18)
  b.writeInt32LE(h, 22)
  b.writeUInt16LE(1, 26)
  b.writeUInt16LE(24, 28)
  b.writeUInt32LE(rowSize * h, 34)
  b.writeInt32LE(2835, 38)
  b.writeInt32LE(2835, 42)
  for (let y = 0; y < h; y++) {
    const row = 54 + (h - 1 - y) * rowSize
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * 4
      b[row + x * 3] = rgba[i + 2]
      b[row + x * 3 + 1] = rgba[i + 1]
      b[row + x * 3 + 2] = rgba[i]
    }
  }
  return b
}

/** ICO with PNG-compressed entries (Windows Vista and later). */
function ico(pngs) {
  const header = Buffer.alloc(6 + 16 * pngs.length)
  header.writeUInt16LE(0, 0)
  header.writeUInt16LE(1, 2)
  header.writeUInt16LE(pngs.length, 4)
  let offset = header.length
  pngs.forEach(({ px, data }, i) => {
    const e = 6 + 16 * i
    header[e] = px >= 256 ? 0 : px
    header[e + 1] = px >= 256 ? 0 : px
    header.writeUInt16LE(1, e + 4)
    header.writeUInt16LE(32, e + 6)
    header.writeUInt32LE(data.length, e + 8)
    header.writeUInt32LE(offset, e + 12)
    offset += data.length
  })
  return Buffer.concat([header, ...pngs.map((p) => p.data)])
}

const browser = await chromium.launch()
try {
  const page = await browser.newPage({ deviceScaleFactor: 1 })

  async function shoot(html, w, h, transparent = false) {
    await page.setViewportSize({ width: w, height: h })
    await page.setContent(html, { waitUntil: 'load' })
    await page.evaluate(() => document.fonts.ready)
    return page.screenshot({
      type: 'png',
      omitBackground: transparent,
      clip: { x: 0, y: 0, width: w, height: h },
    })
  }

  async function pixels(png, w, h) {
    await page.setViewportSize({ width: w, height: h })
    return page.evaluate(
      async ({ src, w, h }) => {
        const img = new Image()
        img.src = src
        await img.decode()
        const c = document.createElement('canvas')
        c.width = w
        c.height = h
        const ctx = c.getContext('2d')
        ctx.drawImage(img, 0, 0)
        return Array.from(ctx.getImageData(0, 0, w, h).data)
      },
      { src: `data:image/png;base64,${png.toString('base64')}`, w, h },
    )
  }

  // Inno Setup 6 picks the image closest to the DPI: 100 %, 150 %, 200 %.
  for (const [w, h] of [
    [164, 314],
    [246, 459],
    [328, 604],
  ]) {
    const png = await shoot(bannerHtml(w, h), w, h)
    writeFileSync(path.join(here, `wizard-${w}x${h}.bmp`), bmp24(w, h, await pixels(png, w, h)))
  }
  for (const [w, h] of [
    [55, 55],
    [83, 80],
    [110, 106],
  ]) {
    const png = await shoot(smallHtml(w, h), w, h)
    writeFileSync(path.join(here, `small-${w}x${h}.bmp`), bmp24(w, h, await pixels(png, w, h)))
  }
  const icons = []
  for (const px of [16, 24, 32, 48, 64, 128, 256]) {
    icons.push({ px, data: await shoot(iconHtml(px), px, px, true) })
  }
  writeFileSync(path.join(here, 'kadai.ico'), ico(icons))
  // A preview of the banner for reviews (not used by the installer).
  writeFileSync(path.join(here, 'preview-wizard.png'), await shoot(bannerHtml(328, 604), 328, 604))
} finally {
  await browser.close()
}
process.stdout.write(`rendered installer assets into ${path.relative(root, here)}\n`)
