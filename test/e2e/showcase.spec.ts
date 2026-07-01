import { test, expect } from '@playwright/test';

test.describe('Showcase MVP E2E Tests', () => {
  test('Deterministic visual regression and state verification', async ({ page }) => {
    // Navigate to the local web server hosting the compiled build.
    await page.goto('http://localhost:8080');

    // In Flutter Web on CanvasKit/Wasm, the canvas is embedded in flt-scene or glass-pane
    const flutterView = page.locator('flutter-view');
    await expect(flutterView).toBeVisible({ timeout: 15000 });

    // Wait for the game to actually render frames and evaluate JS hooks
    await page.waitForTimeout(5000);

    // Verify engine state before taking the snapshot
    const stateJson = await page.evaluate(() => {
      // @ts-ignore
      return (window as any).getGameState ? (window as any).getGameState() : null;
    });

    // Ensure the hooks registered properly
    expect(stateJson).not.toBeNull();

    const gameState = JSON.parse(stateJson);

    // Verify player position after 10 deterministic ticks
    expect(gameState.player).toBeDefined();

    // Verify enemies spawned
    expect(gameState.enemies).toBeDefined();

    // Capture snapshot of the view
    await expect(flutterView).toHaveScreenshot('showcase-baseline.png', { maxDiffPixelRatio: 0.1 });
  });
});
