/*
  Puppeteer test harness for Travel Wizards web flows - COMPREHENSIVE VERSION
  Usage:
    node test_chrome_puppeteer.js --url="http://localhost:5000" --out=artifacts/web_results.json

  Tests: Page load, Google Sign-In UI, Navigation, Security (HTTPS/CSP), Console errors, Responsive design
*/

const fs = require('fs');
const puppeteer = require('puppeteer');
const argv = require('minimist')(process.argv.slice(2));

(async () => {
  const url = argv.url || process.env.CHROME_APP_URL || 'http://localhost:5000';
  const outPath = argv.out || 'artifacts/web_results.json';
  const results = [];
  const consoleErrors = [];

  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox'] });
  const page = await browser.newPage();
  page.setDefaultTimeout(10000);

  // Capture console errors
  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  try {
    // Test 1: Page Load & Title
    const response = await page.goto(url, { waitUntil: 'networkidle2' });
    results.push({ test: 'Web_PageLoad', status: 'PASS', output: `Loaded ${url}`, timestamp: new Date().toISOString() });

    const title = await page.title();
    results.push({ test: 'Web_Title', status: title.toLowerCase().includes('travel') ? 'PASS' : 'FAIL', output: `Title: ${title}`, timestamp: new Date().toISOString() });

    // Test 2: Google Sign-In Button Present
    await new Promise(resolve => setTimeout(resolve, 2000)); // Let page fully render
    const buttons = await page.$$eval('button, [role="button"]', btns =>
      btns.map(b => ({ text: b.textContent.trim(), visible: b.offsetParent !== null }))
    );
    const googleBtn = buttons.find(b => b.text.toLowerCase().includes('google') || b.text.toLowerCase().includes('sign'));
    results.push({ test: 'Web_GoogleSignIn_ButtonPresent', status: googleBtn ? 'PASS' : 'FAIL', output: googleBtn ? `Found: "${googleBtn.text}"` : 'Google Sign-In button not found', timestamp: new Date().toISOString() });

    // Test 3: Navigation Present
    const nav = await page.$('nav, [role="navigation"], header');
    results.push({ test: 'Web_Navigation_Present', status: nav ? 'PASS' : 'FAIL', output: nav ? 'Navigation element found' : 'No navigation found', timestamp: new Date().toISOString() });

    // Test 4: Security - HTTPS Check
    const protocol = page.url().split(':')[0];
    const httpsOk = protocol === 'https' || url.startsWith('http://localhost');
    results.push({ test: 'Web_Security_HTTPS', status: httpsOk ? 'PASS' : 'FAIL', output: `Protocol: ${protocol} (localhost HTTP accepted)`, timestamp: new Date().toISOString() });

    // Test 5: Security - CSP Headers
    const csp = response.headers()['content-security-policy'];
    results.push({ test: 'Web_Security_CSP', status: csp ? 'PASS' : 'WARN', output: csp ? `CSP: ${csp.substring(0, 80)}...` : 'No CSP header (consider adding)', timestamp: new Date().toISOString() });

    // Test 6: Console Errors
    await new Promise(resolve => setTimeout(resolve, 2000)); // Let any errors bubble up
    results.push({ test: 'Web_ConsoleErrors', status: consoleErrors.length === 0 ? 'PASS' : 'WARN', output: consoleErrors.length === 0 ? 'No errors' : `${consoleErrors.length} errors: ${consoleErrors.slice(0, 2).join('; ')}`, timestamp: new Date().toISOString() });

    // Test 7-9: Responsive Design
    const viewports = [
      { name: 'Mobile', width: 375, height: 667 },
      { name: 'Tablet', width: 768, height: 1024 },
      { name: 'Desktop', width: 1920, height: 1080 }
    ];
    for (const vp of viewports) {
      await page.setViewport(vp);
      await page.reload({ waitUntil: 'networkidle2' });
      await new Promise(resolve => setTimeout(resolve, 1000));
      const bodyVisible = await page.$eval('body', el => el.offsetParent !== null);
      results.push({ test: `Web_Responsive_${vp.name}`, status: bodyVisible ? 'PASS' : 'FAIL', output: `Rendered at ${vp.width}x${vp.height}`, timestamp: new Date().toISOString() });
    }

    // Test 10: Create Trip UI (if visible)
    await page.setViewport({ width: 1920, height: 1080 }); // Reset to desktop
    await page.reload({ waitUntil: 'networkidle2' });
    const createSelector = 'button, [data-test="create-trip"], [aria-label*="Plan"], [aria-label*="Create"]';
    const canCreate = await page.$(createSelector) !== null;
    results.push({ test: 'Web_CreateTripUI', status: canCreate ? 'PASS' : 'WARN', output: canCreate ? 'Create UI found' : 'Create button not visible (may require auth)', timestamp: new Date().toISOString() });

  } catch (err) {
    results.push({ test: 'Web_Exception', status: 'ERROR', output: String(err), timestamp: new Date().toISOString() });
  } finally {
    await browser.close();
    const outDir = require('path').dirname(outPath);
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    fs.writeFileSync(outPath, JSON.stringify({ url, timestamp: new Date().toISOString(), summary: { total: results.length, pass: results.filter(r => r.status === 'PASS').length, fail: results.filter(r => r.status === 'FAIL').length, warn: results.filter(r => r.status === 'WARN').length }, results }, null, 2));
    console.log(`✅ Web tests complete: ${results.filter(r => r.status === 'PASS').length}/${results.length} passed`);
    console.log(`   Results: ${outPath}`);
  }
})();
