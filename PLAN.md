# Goal
A seamless, single-scene open-world fantasy adventure (Godot 4.6.3, web/Compatibility, nothreads).
Roam from a forest through a walled town (walk through gates and into buildings) to a great keep
at the far edge. Guards to fight, townsfolk to talk to (LLM-driven), chests to find — one holds the
key to the keep's locked gate. A Meshy-generated signature monument is the town centerpiece.
Backed by Supabase: per-user cloud save (position, inventory, opened gates) + a shared fastest-time
leaderboard for everyone who reaches the keep.

# Files to touch
- `project.godot` — app name, input map, mobile fill.
- `export_presets.cfg` — viewport-fit=cover (safe-area), load Supabase SDK + `web/bridge.js`.
- `main.gd` + `scripts/*.gd` — player, follow-cam, world builder, guards, NPCs, chests, gates,
  HUD/touch controls, NPC chat panel, save system, Supabase client, leaderboard UI.
- `shaders/*.gdshader` — inverted-hull outline, toon ramp, hdri sky, wind sway.
- `models/` — curled KayKit/library `.glb` assets + `monument.glb` (Meshy).
- `web/bridge.js` — Supabase client (client-UUID identity, RPC gateway).
- `.env.example`, `README.md`, `.gitignore`.

# Backend (already provisioned + verified)
- Tables `usr_nmexs7bytxq2_farkeep_save` (per-user) and `_leaderboard` (shared), RLS enabled,
  locked to RPC-only access (anon auth is disabled + email confirmation required on this project,
  so the frontend uses a client-generated UUID identity persisted in localStorage).
- SECURITY DEFINER RPCs (anon EXECUTE): `farkeep_load`, `farkeep_upsert_save`,
  `farkeep_submit_score` (keeps fastest); leaderboard read is public SELECT.

# Verification approach
- Apply schema + drive every RPC as anon (done). Headless Godot import asserts animation clips
  resolve (no T-pose). Smoke verifier (engine boots, frames). Targeted checks: facing, combat
  delta + JUICE, chest/gate triggers fire (layer/mask), collision matches mesh, mobile fill at
  portrait + landscape, NPC-chat contract + panel opens. Independent QA pass before PR.

# Out of scope
- Multiplayer/Realtime (single-player; leaderboard is shared but not live).
- Real-device GPU/touch feel, audio playback, and email-account auth (project constraints).
