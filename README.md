# Far Keep

A seamless, single-scene open-world fantasy adventure built with **Godot 4.6.3** (web export,
Compatibility / WebGL2, single-threaded) and backed by **Supabase**. No loading screens, no
separate rooms -- roam freely from a forest, through the walled town of **Vellmoor** (walk through
the gates and into its buildings), all the way to the **Great Keep** at the far edge of the land.

## What you can do
- **Roam** a continuous world: forest -> walled town -> keep, all in one scene.
- **Fight guards** -- melee combat with hit feedback (particles, hit-flash, camera shake).
- **Talk to townsfolk** -- three NPCs with live, LLM-driven dialogue (the innkeeper, a trader, a
  hooded stranger).
- **Find chests** -- one in the guardhouse holds the **key** to the keep's locked gate.
- **Open the keep's gate** with the key and reach the Great Keep to win.
- A **unique signature monument** (AI-generated) stands at the town's centre.

## Backed by Supabase
- **Cloud save / resume** -- your position, what you've collected, opened gates, and elapsed time
  are saved to Supabase. Close the game and pick up exactly where you left off (per-device identity).
- **Shared leaderboard** -- everyone who reaches the keep is ranked by fastest time.

Identity: this project's Supabase instance has anonymous auth disabled and email confirmation
required, so the game uses a **client-generated UUID** persisted in `localStorage` as the per-device
identity. The `save` and `leaderboard` tables are **locked down** (RLS enabled, no direct table
access) and reached only through `SECURITY DEFINER` RPCs (`farkeep_load`, `farkeep_upsert_save`,
`farkeep_submit_score`) plus a public read on the leaderboard. The Supabase URL + publishable anon
key live in `web/bridge.js` (public client credentials by design); the service-role key is never
shipped.

## Controls
- **Move:** on-screen left stick (drag the left side) / `WASD`
- **Look:** drag the right side of the screen / hold-drag the mouse
- **Attack:** the Attack button / `J` or `Space`
- **Use / talk / open:** the Use button (appears when something's in reach) / `E`
- **Leaderboard:** the Board button / `L`

## Build (locally)
```bash
# 1. Fetch the CC0 library assets into models/ (the unique monument.glb is the live centrepiece)
bash fetch_assets.sh
# 2. Open in Godot 4.6.3 and export with the "Web" preset, OR headless:
godot --headless --import
godot --headless --export-release "Web" out/index.html
cp web/bridge.js out/bridge.js   # the export's <script src="bridge.js"> needs it alongside index.html
# 3. Serve out/ over http (the .wasm needs the application/wasm MIME type)
```

The game must be served (not opened via `file://`) and runs in mobile + desktop Safari, Chrome,
and Firefox. The Web export is single-threaded (`thread_support=false`) so it loads without
COOP/COEP headers.

## Assets
All world/character art is CC0 from the shared low-poly library (KayKit, Quaternius) -- see
`fetch_assets.sh` for the exact files (run it to populate `models/`). The town's signature
centerpiece, `models/monument.glb`, is a **unique AI-generated** model (a heroic statue on a tiered
fountain pedestal); it is baked into the deployed/live build. If `models/monument.glb` is absent for
a local build, the game gracefully falls back to a simple stone obelisk in the same spot.
