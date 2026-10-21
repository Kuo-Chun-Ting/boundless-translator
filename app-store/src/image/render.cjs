const fs = require('node:fs');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const {chromium} = require('playwright');
const {PNG} = require('pngjs');

const root = path.resolve(__dirname, '../..');
const write = process.argv.includes('--write');
const legacy = process.argv.includes('--legacy');
const dictionaryDust = process.argv.includes('--dictionary-dust');
const spaceGray = process.argv.includes('--space-gray');

/** @returns {string | undefined} */
function createOutputDirectory() {
  if (legacy && (spaceGray || dictionaryDust || process.argv.includes('--recording'))) {
    throw Error('--legacy renders both old themes; do not combine it with current-layout options.');
  }
  if ((legacy || spaceGray) && !write) throw Error('Alternate layouts require --write --out <new-directory>.');
  const index = process.argv.indexOf('--out');
  const value = index === -1 ? undefined : process.argv[index + 1];
  if (!write && index !== -1) throw Error('--out requires --write.');
  if (!write) return undefined;
  if (!value || value.startsWith('--')) throw Error('--write requires --out <new-directory>.');
  const directory = path.resolve(root, value);
  if (fs.existsSync(directory)) throw Error(`Refusing to overwrite existing directory: ${directory}`);
  fs.mkdirSync(path.dirname(directory), {recursive: true});
  fs.mkdirSync(directory);
  return directory;
}

/** @param {string} output @param {string | undefined} directory @returns {string} */
function outputPath(output, directory) {
  if (!directory) return path.join(root, output);
  // A full legacy set contains two themes with matching filenames.
  const relative = legacy ? path.relative('image', output) : path.basename(output);
  return path.join(directory, relative);
}

/** @returns {Array<{source: string, output: string, kind?: string}>} */
function listPages() {
  if (dictionaryDust) return [{
    source: 'src/image/glass/dictionary-blur-options.html', selector: '#option-2-dust',
    output: 'image/03-dictionary.png',
  }];
  if (!legacy) {
    return [
      ...[['selection', '01-selection'], ['screenshot', '02-screenshot']].map(([selector, name]) => ({
        source: 'src/image/glass/recording.html', selector: `#${selector}`,
        output: `image/${name}.png`,
        kind: selector === 'screenshot' ? 'recording-menu' : undefined,
      })),
      {source: 'src/image/glass/dictionary-blur-options.html', selector: '#option-2-dust', output: 'image/03-dictionary.png'},
      {source: 'src/image/glass/04-settings.html', output: 'image/04-settings.png'},
    ];
  }
  const pages = [];
  for (const theme of ['glass', 'space-gray']) {
    const folder = `image/${theme}`;
    for (const [source, output] of [
      ['01-selected-text-02-preview-aligned', '01-selection-2-preview'],
      ['04-settings', '04-settings'],
    ]) {
      pages.push({source: `src/image/${theme}/${source}.html`, output: `${folder}/${output}.png`});
    }
    pages.push({
      source: `src/image/${theme}/dictionary.html`,
      output: `${folder}/03-dictionary.png`,
    });
    for (const [kind, name] of [['lettering', '1-cant-select']]) {
      pages.push({kind, source: `src/image/${theme}/screenshot-${kind}.html`,
        output: `${folder}/02-screenshot-${name}.png`});
    }
  }
  return pages;
}

/** @param {import('playwright').Page} page @param {string} source @returns {Promise<Buffer>} */
async function renderLayout(page, source, selector = '.slide', selectedScreenshot) {
  await page.goto(pathToFileURL(path.join(root, source)).href);
  if (spaceGray && (source.endsWith('/recording.html') || source.endsWith('/dictionary-blur-options.html'))) {
    const themeSource = fs.readFileSync(path.join(__dirname, 'space-gray/dictionary.html'), 'utf8');
    await page.evaluate(themeHTML => {
      const theme = new DOMParser().parseFromString(themeHTML, 'text/html');
      for (const id of ['blue', 'ice', 'glass-fill', 'glass-edge', 'pane-shadow', 'glass']) {
        document.getElementById(id).replaceWith(document.importNode(theme.getElementById(id), true));
      }
      const css = theme.querySelector('style').textContent;
      const style = document.createElement('style');
      style.textContent = ['body', '.slide', 'p'].map(selector => {
        const escaped = selector.replace('.', '\\.');
        return css.match(new RegExp(`${escaped} \\{[^}]+\\}`))[0];
      }).join('\n') + `
        .action,.context-tag {color:#d8d5d3;}
        .window-cutout,.source-window {filter:drop-shadow(0 12px 18px #00000045);}
        .capture {box-shadow:0 18px 45px #00000045;}
      `;
      document.head.appendChild(style);
      for (const stop of document.querySelectorAll('.caption-wash stop')) {
        stop.setAttribute('stop-color', '#d8d5d3');
        stop.setAttribute('stop-opacity', Number(stop.getAttribute('stop-opacity')) * .75);
      }
    }, themeSource);
  }
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.querySelectorAll('img, image')].map(element => {
      const image = new Image();
      image.src = element.getAttribute('src') || element.getAttribute('href');
      return image.decode();
    }));
  });
  if (selectedScreenshot) await arrangeScreenshot(page);
  return page.locator(selector).screenshot();
}

function screenshotLayout() {
  const resultWidth = 450;
  const scale = resultWidth / 2000;
  const sourceWidth = Math.sqrt(2 * resultWidth * resultWidth * 1360 / 2000 / (1794 / 3024));
  const sourceX = 80;
  const sourceY = 405;
  const resultX = 1030;
  const resultY = [325, 325 + resultWidth * 1360 / 2000 + 44];
  const wizard = {x: sourceX + sourceWidth - 125, y: sourceY + sourceWidth * 1794 / 3024 - 150, width: 250};
  return {sourceX, sourceY, sourceWidth, resultWidth, resultX, scale, resultY, wizard,
    cards: [
      {sx: 132, sy: 575, sw: 375, sh: 100, px: 319, py: 695, ix: resultX, iy: resultY[0], scale},
      {sx: 344, sy: 575, sw: 850, sh: 100, px: 769, py: 695, ix: resultX, iy: resultY[1], scale},
    ],
    wand: {x: wizard.x + 227.7 * wizard.width / 278, y: wizard.y + 28.1 * wizard.width / 278},
  };
}

/** @param {import('playwright').Page} page */
async function arrangeScreenshot(page) {
  await page.locator('#screenshot').evaluate((slide, layout) => {
    const position = (element, x, y, width, height) => {
      Object.assign(element.style, {left: `${x}px`, top: `${y}px`});
      if (width) element.style.width = `${width}px`;
      if (height) element.style.height = `${height}px`;
    };
    const sourceScale = layout.sourceWidth / 760;
    position(slide.querySelector('.source-window'), layout.sourceX, layout.sourceY, layout.sourceWidth, layout.sourceWidth * 1794 / 3024);
    position(slide.querySelector('.capture-frame'), layout.sourceX + 440 * sourceScale, layout.sourceY + 117 * sourceScale, 280 * sourceScale, 183 * sourceScale);
    const labels = slide.querySelectorAll('.action');
    position(labels[0], layout.sourceX, layout.sourceY - 34);
    const results = slide.querySelectorAll('.window-cutout');
    [1360, 1360].forEach((height, index) => {
      position(results[index], layout.resultX, layout.resultY[index], layout.resultWidth, height * layout.scale);
      position(labels[index + 1], layout.resultX, layout.resultY[index] - 34);
    });
    position(slide.querySelector('.wizard'), layout.wizard.x, layout.wizard.y, layout.wizard.width);
  }, screenshotLayout());
}

/** @param {import('playwright').Page} page @param {Buffer} base @param {string} kind @returns {Promise<Buffer>} */
async function renderBeams(page, base, kind) {
  await page.addScriptTag({path: path.join(__dirname, 'components/beams.js')});
  const result = await page.evaluate(options => window.drawBeams(options), {
    url: 'data:image/png;base64,' + base.toString('base64'), kind,
    layout: kind === 'recording-menu' ? screenshotLayout() : undefined,
  });
  const image = PNG.sync.read(Buffer.from(result.split(',')[1], 'base64'));
  return PNG.sync.write(image, {colorType: 2});
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
  const directory = createOutputDirectory();
  const browser = await chromium.launch({headless: true});
  try {
    const page = await browser.newPage({viewport: {width: 1600, height: 1000}, deviceScaleFactor: 1.6});
    let failures = 0;
    for (const originalJob of listPages()) {
      const job = spaceGray ? {...originalJob,
        source: originalJob.source.replace('glass/04-settings.html', 'space-gray/04-settings.html'),
      } : originalJob;
      let output = await renderLayout(page, job.source, job.selector, job.kind === 'recording-menu');
      if (job.kind) output = await renderBeams(page, output, job.kind);
      const destination = outputPath(job.output, directory);
      if (write) {
        fs.mkdirSync(path.dirname(destination), {recursive: true});
        fs.writeFileSync(destination, output, {flag: 'wx'});
        console.log(`Wrote ${path.relative(root, destination)}`);
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
