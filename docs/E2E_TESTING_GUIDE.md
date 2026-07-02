# Sting Engine: End-to-End Visual Testing Guide

This guide outlines the standards and procedures for creating deterministic End-to-End (E2E) visual tests for games built on the Sting engine. Because Sting games involve heavy use of custom Canvas rendering and ECS loops, standard Flutter widget testing is insufficient. We rely on Playwright to take visual snapshots of the rendered `<flutter-view>` and verify internal state logic.

## 1. Updating Engine Components

When updating core engine components or rendering logic:
1. **Zero Allocations:** Always verify your changes maintain the zero-allocation per frame constraint. Do not instantiate objects (like `Rect` or `Offset`) in rendering loops.
2. **Visual Contracts:** Any changes to `SpriteRenderSystem`, `TilemapRenderSystem`, or `CameraSystem` must be backwards compatible with visual regression snapshots.
3. **Run E2E Tests:** Run the Playwright test suite (`npx playwright test`) before merging any engine changes to ensure no unexpected visual shifting or artifacting occurs.

## 2. Deterministic Testing Environment

To ensure E2E screenshots are perfectly consistent across CI/CD runs, games must provide a deterministic entry point (e.g., `showcase/lib/test_main.dart`).

### Fixing the Game Loop
Real-time delta-time (`dt`) loops cause flakiness depending on machine performance. The test entry point must:
* Disable the real-time VSync callback (`PlatformDispatcher.instance.onBeginFrame = (_) {}`).
* Manually tick the engine's fixed time accumulator a specific number of times (e.g., 10 frames at `16666` microseconds).
* Schedule exactly one final frame draw (`dispatcher.scheduleFrame()`) after state is settled.

### Fixed Placements and RNG
* **No Randomness:** Use fixed seeds for any random number generators (RNG).
* **Static Entities:** Spawners should be disabled or hardcoded to spawn enemies at exact coordinates relative to the player.
* **Deterministic Layout:** Player, enemies, and UI elements must always resolve to the exact same screen coordinates by the time the final draw frame is called.

## 3. Exposing Internal State via JS Interop

Playwright cannot inspect the internals of the opaque `<flutter-view>` canvas. To assert that game logic (like HP, score, or entity positions) is functioning correctly before taking a snapshot, we expose internal state to JavaScript.

Use `dart:js_interop` to bind a Dart function that serialize game state to JSON:

```dart
import 'dart:js_interop';

@JS('getGameState')
external set _getGameState(JSFunction func);

void registerTestHooks(GameEngine engine) {
  _getGameState = () {
    // Extract entity positions, health, score, etc.
    return jsonEncode({
      'player': {'x': 100.0, 'y': 100.0},
      'enemies': [{'x': 150.0, 'y': 150.0}],
      'score': 100,
    }).toJS;
  }.toJS;
}
```

## 4. Writing Playwright Visual Regression Tests

Playwright tests (located in `test/e2e/`) should navigate to the local server, await the `<flutter-view>`, verify the internal state, and finally capture a screenshot.

```typescript
import { test, expect } from '@playwright/test';

test('Gameplay renders correctly and state is accurate', async ({ page }) => {
  await page.goto('/');

  // 1. Wait for the Flutter canvas to initialize
  const flutterView = page.locator('flutter-view');
  await expect(flutterView).toBeAttached();

  // Wait a short moment for the deterministic manual ticks to finish
  await page.waitForTimeout(1000);

  // 2. Assert Internal Logic State
  const gameStateStr = await page.evaluate(() => {
    return (window as any).getGameState();
  });
  const state = JSON.parse(gameStateStr);
  expect(state.player.x).toBeGreaterThan(0);
  expect(state.enemies.length).toBeGreaterThan(0);

  // 3. Visual Snapshot Regression
  await expect(flutterView).toHaveScreenshot('gameplay-deterministic-snapshot.png');
});
```

## 5. Summary Checklist for QA / SDET
- [ ] Has `test_main.dart` completely frozen real-time updates?
- [ ] Are all entity placements hardcoded and RNG seeded?
- [ ] Does `getGameState` expose the necessary variables to Playwright?
- [ ] Do Playwright snapshots target `flutter-view` directly?
- [ ] Are CI/CD pipelines configured to serve the compiled web test build locally?
