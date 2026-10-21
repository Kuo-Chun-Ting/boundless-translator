const fs = require('node:fs');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const {chromium} = require('playwright');

const kit = path.resolve(__dirname, '../../../assets/original-kit');

/** @param {import('playwright').Page} page @param {string} file */
async function load(page, file) {
  await page.goto(pathToFileURL(file).href);
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.querySelectorAll('img, image')].map(element => {
      const image = new Image();
      image.src = element.getAttribute('src') || element.getAttribute('href');
      return image.decode();
    }));
  });
}

/** @returns {Promise<void>} */
async function main() {
  const browser = await chromium.launch({headless: true});
  try {
    const page = await browser.newPage({viewport: {width: 1600, height: 1040}, deviceScaleFactor: 1});
    for (const [source, output] of [
      ['menu.html', 'menu.png'],
    ]) {
      await load(page, path.join(__dirname, source));
      await page.locator('.art').screenshot({path: path.join(kit, output), omitBackground: false});
    }
    await page.setViewportSize({width: 1440, height: 1000});
    for (const source of ['screenshot-menu']) {
      await load(page, path.join(kit, source + '.html'));
      await page.screenshot({path: path.join(kit, source + '-preview.png'), fullPage: true});
    }
    await load(page, path.join(kit, 'screenshot-menu.html'));
    const menu = await page.locator('.menu-image').evaluate(element => ({tag: element.tagName, loaded: element.naturalWidth > 0}));
    if (menu.tag !== 'IMG' || !menu.loaded) throw Error('Menu must be a loaded raster image');
    if ((await page.locator('body').innerText()).includes('香ばしく焼いた野菜と')) throw Error('Menu text must not be HTML text');
    const checks = {menuIsRasterImage: true, renderer: 'Headless Chromium', safariChecked: false};
    fs.writeFileSync(path.join(kit, 'checks.json'), JSON.stringify(checks, null, 2) + '\n');
    console.log(JSON.stringify(checks, null, 2));
  } finally { await browser.close(); }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
