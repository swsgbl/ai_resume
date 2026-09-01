import { chromium } from 'playwright';

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  const { spawn } = await import('child_process');
  const vite = spawn('npx', ['vite', 'preview', '--port', 3000], {
    cwd: '/mnt/d/ai_resume/ai-resume-web',
    stdio: 'ignore'
  });
  
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  await page.goto('http://localhost:3000/resume/login');
  await page.waitForTimeout(2000);
  
  const emailInput = page.getByTestId('email-input');
  const hasId = await emailInput.evaluate(el => el.hasAttribute('id'));
  const idValue = await emailInput.evaluate(el => el.getAttribute('id'));
  const outerHTML = await emailInput.evaluate(el => el.outerHTML);
  
  console.log('Has id attribute:', hasId);
  console.log('Id value:', idValue);
  console.log('Outer HTML:', outerHTML);
  
  await browser.close();
  vite.kill();
})();
