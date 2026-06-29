# Sting

A bare-metal, high-performance 2D game engine for Dart, designed for massive entity counts and uncompromising performance.

## Core Philosophy

* **Zero Flutter Framework**: Sting does not use `runApp()`, `Widgets`, or `BuildContext`. It binds directly to `PlatformDispatcher.instance.onBeginFrame` and `dart:ui` to talk directly to the underlying graphics engine (Impeller/Skia).
* **Strict ECS**: Data-oriented Entity Component System. Entities are purely `int` IDs. Components are flat data classes. Systems handle all logic.

## Tech Stack

* **Language**: Dart 3.x (Utilizing Records, Patterns, and Extension Types for memory efficiency and ergonomics).
* **Rendering**: Pure `dart:ui` (`Canvas`, `PictureRecorder`, `SceneBuilder`, `drawAtlas` for batch rendering).
* **Target**: Cross-platform (iOS, Android, Web, Desktop).

## AI-Driven Development

This project is built using AI-driven development practices.
All AI agents contributing to this repository must follow the strict rules outlined in `AGENTS.md`.
Architectural decisions, failed attempts, and historical context are maintained in the `shared_memories/` directory to ensure agents learn from past iterations and do not repeat mistakes.

## Engine Status

Sting has completed its foundational core (Phase 7) and is currently deemed **ready for MVP game production**. The robust Data-Oriented Design (DOD) constraints guarantee zero-allocation game loops, handling batch rendering, spatial hashing, UI, tilemaps, and state management flawlessly.

## Project Structure

* `docs/` - System design and architectural documentation.
* `lib/` - Engine source code.
* `showcase/` - Showcase games and prototypes built using the engine.
* `test/` - 100% test coverage requirement for all engine features.
* `shared_memories/` - Structured memory for AI agents (JSON format) to track decisions and avoided paths.
