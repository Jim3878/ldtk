# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

LDtk (Level Designer Toolkit) is a 2D level editor written in **Haxe**, compiled to JavaScript, and packaged as an **Electron** desktop app. It can also run as a plugin inside the [Hide](https://github.com/heapsio/hide) editor, or standalone in NW.js.

The project data model, project file format (`.ldtk`, JSON-based) and its schema are the product's core contract — most non-trivial changes touch the data layer (`src/electron.renderer/data/`) and its JSON (de)serialization.

## Build commands

Run from the repo root unless noted. Requires the Haxe compiler and NPM.

```bash
# One-time setup: install Haxe libs (heaps, castle, electron, ldtk-haxe-api, etc.)
haxe setup.hxml

# Install Electron + JS deps (must be run from app/)
cd app && npm i
```

Compile (debug builds — no dead-code elimination, faster iteration):

```bash
haxe main.debug.hxml       # -> app/assets/main.js (Electron main process)
haxe renderer.debug.hxml   # -> app/assets/js/renderer.js (the actual editor UI/logic)
```

Release builds (`main.hxml` / `renderer.hxml`, or `npm run compile` from `app/`) additionally run macros that dump the build version and generate release notes, and use full DCE.

Run the app:

```bash
cd app && npm run start
```

Build the Hide plugin (sources in `src/hide/plugin/`):

```bash
haxe hide-plugin.hxml   # -> app/nwjs/hide-plugin.js
```

Generate docs / JSON schema from the data model (`ldtk/Json.hx` comes from the `ldtk-haxe-api` lib, which mirrors this repo's save format):

```bash
haxe doc.hxml   # -> docs/JSON_DOC.md, docs/JSON_SCHEMA.json, docs/MINIMAL_JSON_SCHEMA.json
```

There is no automated unit test suite. CI (`.github/workflows/test-windows.yml` and the `package-*.yml` workflows) only verifies that `main.hxml`/`renderer.hxml` compile and that packaging succeeds. `tests/` contains sample `.ldtk` project files and fixture assets used for manual testing, not a test runner. Verifying a change means compiling the relevant target(s) above and exercising the feature in the running app.

## Architecture

### Haxe compilation units (each `.hxml` is a separate compile with its own classpath)

- **`src/electron.main/`** (`ElectronMain.hx`) — the Electron **main process**: window/menu management, native OS integration. Compiled by `main.hxml`.
- **`src/electron.renderer/`** — the actual editor: UI, data model, rendering, import/export. Runs in the Electron **renderer process**, compiled by `renderer.hxml` with `-D editor -D electron`.
- **`src/electron.common/`** — code shared between main and renderer (e.g. `Settings.hx`, build macros in `MacroTools.hx`).
- **`src/hide/plugin/`** — adapter that lets the renderer code run embedded inside Hide instead of Electron; compiled separately by `hide-plugin.hxml`.
- **`src/docGenerator/`** — macro-driven generator that turns the `ldtk-haxe-api` JSON type (`ldtk.Json`) into `docs/JSON_DOC.md` and the JSON Schema files. The save-file format is defined once in the external `ldtk-haxe-api` repo and consumed here; changing the save format means coordinating both repos (see `README.md`'s notes on `dev-x.y.z` branches needing a matching `ldtk-haxe-api` branch).
- **`src/externs/`** — typed bindings for JS libraries used from Haxe (jQuery, CodeMirror, sortablejs, simple-color-picker).

### Inside `src/electron.renderer/`

- **`data/`** — the in-memory project model: `Project.hx` (root), `World.hx`, `Level.hx`, `Definitions.hx`, plus `data/def/` (layer/entity/enum/tileset/rule *definitions*, i.e. the project's schema) and `data/inst/` (entity/layer/field *instances*, i.e. actual placed content). Definitions and instances are distinct: editing a definition (e.g. an entity type) cascades to all its instances. Every world/level/entity instance carries an `iid` (unique instance id) separate from its human-readable `identifier`.
- **`page/`** — top-level app pages/screens (`Editor.hx` is the main editor page, `Home.hx` is the project picker/launcher).
- **`ui/`** — editor panels and widgets (modals, palettes, forms, the `CommandPalette.hx` global search). Generally one class per panel/widget.
- **`display/`** — Heaps.io rendering of the level/world canvas.
- **`tool/`** — interactive editing tools (draw, select, entity placement, etc.) used on the canvas.
- **`importer/` / `exporter/`** — conversion to/from other formats (e.g. Tiled, GameMaker — see `tests/gameMaker/`, `tests/tiled*`).
- **`misc/`** — cross-cutting helpers (e.g. `JsTools.hx`).

### Key cross-cutting concepts

- **Definitions vs instances**: almost every editable "thing" in LDtk has a `*Def` (schema, in `data/def/`) and an instance (actual data, in `data/inst/` or on `Level`/`World`). UI code for editing defs generally lives under `ui/modal/panel/Edit*Defs.hx`.
- **`iid`**: a stable unique id assigned to worlds, levels, layers, and entity instances, independent of their (renameable) `identifier`. Used for cross-referencing (e.g. entity reference fields) and external tooling; not the same thing as a definition's `identifier`.
- **Global Search / Command Palette** (`ui/CommandPalette.hx`, `Ctrl+F`/`Ctrl+Shift+P`): indexes definitions, worlds, levels and entity instances into a flat list of `SearchElement`s with precomputed, sanitized `keywords`; matching is an AND of substrings typed in the search box. A separate, simpler `ui/QuickSearch.hx` just filters already-rendered `<li>` lists inside individual panels (defs lists, palettes) — it is not project-wide search.
- **Save format compatibility**: the `.ldtk` JSON format is versioned; see `docs/CHANGELOG.md` for user-facing format/behavior changes across releases, and `docs/archives/` for historical schemas.
