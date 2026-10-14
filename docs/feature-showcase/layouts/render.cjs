const fs = require('node:fs');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const {chromium} = require('playwright');
const {PNG} = require('pngjs');

const root = path.resolve(__dirname, '..');
const write = process.argv.includes('--write');

/** @returns {Array<{source: string, output: string, kind?: string, mode?: string}>} */
function listPages() {
  const pages = [];
  for (const theme of ['glass', 'space-gray']) {
    const folder = `output/${theme}`;
    for (const name of ['01-selected-text-01-vscode-aligned', '01-selected-text-02-preview-aligned', '04-settings']) {
      pages.push({source: `layouts/${theme}/${name}.html`, output: `${folder}/${name}.png`});
    }
    pages.push({
      source: `layouts/${theme}/dictionary.html`,
      output: `${folder}/03-dictionary-graphite.png`,
    });
    for (const kind of ['general', 'lettering']) {
      const prefix = kind === 'general' ? '02-screenshot-01-general-beam' : '02-screenshot-02-lettering-wizard-beam';
      for (const mode of ['gold', 'connected']) {
        pages.push({kind, mode, source: `layouts/${theme}/screenshot-${kind}.html`,
          output: `${folder}/${prefix}-${mode}-graphite.png`});
      }
    }
  }
  return pages;
}

/** @param {import('playwright').Page} page @param {string} source @returns {Promise<Buffer>} */
async function renderLayout(page, source) {
  await page.goto(pathToFileURL(path.join(root, source)).href);
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.querySelectorAll('img, image')].map(element => {
      const image = new Image();
      image.src = element.getAttribute('src') || element.getAttribute('href');
      return image.decode();
    }));
  });
  return page.locator('.slide').screenshot();
}

/** @param {import('playwright').Page} page @param {Buffer} base @param {string} kind @param {string} mode @returns {Promise<Buffer>} */
async function renderBeams(page, base, kind, mode) {
  await page.addScriptTag({path: path.join(__dirname, 'components/beams.js')});
  const result = await page.evaluate(options => window.drawBeams(options), {
    url: 'data:image/png;base64,' + base.toString('base64'), kind, mode,
  });
  return Buffer.from(result.split(',')[1], 'base64');
}

/** @param {Buffer} actual @param {Buffer} expected @returns {number} */
function countDifferentPixels(actual, expected) {
  const a = PNG.sync.read(actual);
  const b = PNG.sync.read(expected);
  if (a.width !== b.width || a.height !== b.height) return a.width * a.height;
  let different = 0;
  for (let i = 0; i < a.data.length; i += 4) {
    if (!a.data.subarray(i, i + 4).equals(b.data.subarray(i, i + 4))) different++;
  }
  return different;
}

/** @returns {Promise<void>} */
async function main() {
  const browser = await chromium.launch({headless: true});
  try {
    const page = await browser.newPage({viewport: {width: 1600, height: 1000}, deviceScaleFactor: 1.6});
    let failures = 0;
    for (const job of listPages()) {
      let output = await renderLayout(page, job.source);
      if (job.kind) output = await renderBeams(page, output, job.kind, job.mode);
      const destination = path.join(root, job.output);
      if (write) {
        fs.writeFileSync(destination, output);
        console.log(`Wrote ${job.output}`);
      } else {
        const different = countDifferentPixels(output, fs.readFileSync(destination));
        if (different) failures++;
        console.log(`${job.output}: ${different} different pixels`);
      }
    }
    if (failures) process.exitCode = 1;
  } finally {
    await browser.close();
  }
}

main().catch(error => {console.error(error); process.exitCode = 1;});
