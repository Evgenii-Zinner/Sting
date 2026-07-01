import { test, expect } from '@playwright/test';

test.describe('E2E Visual Tests', () => {
  test('Canvas rendering baseline snapshot', async ({ page }) => {
    // Navigate to the local web server hosting the compiled build.
    await page.goto('http://localhost:8080');

    // In Flutter Web on CanvasKit/Wasm, the canvas is embedded in flt-scene or glass-pane
    const flutterView = page.locator('flutter-view');
    await expect(flutterView).toBeVisible({ timeout: 15000 });

    // Wait for the game to actually render frames
    await page.waitForTimeout(5000);

    // Capture snapshot of the view
    await expect(flutterView).toHaveScreenshot('canvas-baseline.png', { maxDiffPixelRatio: 0.1 });
  });
});
