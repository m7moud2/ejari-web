import puppeteer from 'puppeteer-core';
import fs from 'fs';
import path from 'path';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const BASE_URL = process.env.FLUTTER_URL || 'http://localhost:53621';
const OUT_DIR = path.resolve(process.cwd(), 'captures');
const VIEWPORT = { width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true };

fs.mkdirSync(OUT_DIR, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function screenshot(page, name) {
  const file = path.join(OUT_DIR, `${name}.png`);
  await page.screenshot({ path: file, type: 'png' });
  console.log(`SAVED:${file}`);
  return file;
}

async function clearAppState(page) {
  try {
    await page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });
  } catch (_) {
    // ignore if not on app origin yet
  }
}

async function clickTextArea(page, textHints = []) {
  // Flutter web often exposes semantics in DOM after enabling accessibility
  const clicked = await page.evaluate((hints) => {
    const all = Array.from(document.querySelectorAll('*'));
    for (const el of all) {
      const label = (el.getAttribute('aria-label') || el.textContent || '').trim();
      if (!label) continue;
      for (const hint of hints) {
        if (label.includes(hint)) {
          const rect = el.getBoundingClientRect();
          if (rect.width > 0 && rect.height > 0) {
            el.click();
            return label;
          }
        }
      }
    }
    return null;
  }, textHints);
  return clicked;
}

async function clickAt(page, x, y) {
  await page.mouse.click(x, y);
}

async function typeIntoFlutter(page, text) {
  await page.keyboard.type(text, { delay: 30 });
}

async function enableFlutterAccessibility(page) {
  await page.evaluate(() => {
    const btn = document.querySelector('[aria-label="Enable accessibility"]');
    if (btn) btn.click();
  });
  await sleep(500);
}

async function main() {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
    defaultViewport: VIEWPORT,
  });

  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);

  const results = [];

  try {
    // 1. Splash — fresh load, screenshot ASAP
    await page.goto(BASE_URL, { waitUntil: 'networkidle2', timeout: 90000 });
    await clearAppState(page);
    await page.reload({ waitUntil: 'networkidle2', timeout: 90000 });
    await sleep(800);
    results.push({ screen: 'splash', file: await screenshot(page, '01-splash') });

    // 2. Onboarding first slide
    await sleep(3500);
    await enableFlutterAccessibility(page);
    results.push({ screen: 'onboarding', file: await screenshot(page, '02-onboarding') });

    // 3. Login via تخطي
    let clicked = await clickTextArea(page, ['تخطي', 'Skip']);
    if (!clicked) await clickAt(page, 340, 55);
    await sleep(2000);
    results.push({ screen: 'login', file: await screenshot(page, '03-login') });

    // 4. Signup — try link on login
    clicked = await clickTextArea(page, ['إنشاء حساب', 'حساب جديد', 'Signup', 'Register']);
    if (!clicked) await clickAt(page, 195, 720);
    await sleep(2000);
    results.push({ screen: 'signup', file: await screenshot(page, '04-signup') });

    // Back to login
    clicked = await clickTextArea(page, ['تسجيل الدخول', 'لديك حساب', 'Login']);
    if (!clicked) await clickAt(page, 195, 780);
    await sleep(1500);

    // 5. Login as tenant
    await enableFlutterAccessibility(page);
    // Tap email field area
    await clickAt(page, 195, 320);
    await sleep(300);
    await page.keyboard.down('Control');
    await page.keyboard.press('KeyA');
    await page.keyboard.up('Control');
    await typeIntoFlutter(page, 'tenant@ejari.app');
    await clickAt(page, 195, 400);
    await sleep(300);
    await typeIntoFlutter(page, 'user123');
    clicked = await clickTextArea(page, ['تسجيل الدخول', 'دخول', 'Login']);
    if (!clicked) await clickAt(page, 195, 500);
    await sleep(4000);
    results.push({ screen: 'home', file: await screenshot(page, '05-home-tenant') });

    // 6. Payment — booking alert or quick action
    clicked = await clickTextArea(page, ['ادفع', 'الدفع', 'عربون', 'المتبقي', 'إكمال الدفع']);
    if (!clicked) {
      await clickAt(page, 195, 420);
      await sleep(1500);
      clicked = await clickTextArea(page, ['ادفع', 'الدفع', 'عربون']);
      if (!clicked) await clickAt(page, 195, 300);
    }
    await sleep(2500);
    results.push({ screen: 'payment', file: await screenshot(page, '06-payment') });

    console.log('RESULTS:' + JSON.stringify(results));
  } catch (err) {
    console.error('ERROR:' + err.message);
    await screenshot(page, 'error-state').catch(() => {});
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
}

main();
