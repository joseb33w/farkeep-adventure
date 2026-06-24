#!/usr/bin/env bash
# Fetch the CC0 low-poly library assets used by Far Keep into models/.
# (models/monument.glb is the unique AI-generated centrepiece, baked into the live build.)
set -euo pipefail
B="https://preview.myapping.com/godot-assets"
cd "$(dirname "$0")/models"

declare -A M=(
  [kk_Barbarian.glb]=characters/kk_Barbarian.glb
  [kk_Knight.glb]=characters/kk_Knight.glb
  [kk_Mage.glb]=characters/kk_Mage.glb
  [kk_Rogue_Hooded.glb]=characters/kk_Rogue_Hooded.glb
  [kk_Ranger.glb]=characters/kk_Ranger.glb
  [anim_general.glb]=animations/kk_rig_medium_general.glb
  [anim_move.glb]=animations/kk_rig_medium_movementbasic.glb
  [anim_combat.glb]=animations/kk_rig_medium_combatmelee.glb
  [building_castle.glb]=props/kk_hex/building_castle_blue.glb
  [building_church.glb]=props/kk_hex/building_church_blue.glb
  [building_blacksmith.glb]=props/kk_hex/building_blacksmith_blue.glb
  [building_market.glb]=props/kk_hex/building_market_blue.glb
  [building_tavern.glb]=props/kk_hex/building_tavern_blue.glb
  [building_home_A.glb]=props/kk_hex/building_home_A_blue.glb
  [building_home_B.glb]=props/kk_hex/building_home_B_blue.glb
  [building_well.glb]=props/kk_hex/building_well_blue.glb
  [building_tower.glb]=props/kk_hex/building_tower_A_blue.glb
  [building_barracks.glb]=props/kk_hex/building_barracks_blue.glb
  [wall_straight.glb]=props/kk_hex/wall_straight.glb
  [wall_gate.glb]=props/kk_hex/wall_straight_gate.glb
  [wall_corner.glb]=props/kk_hex/wall_corner_A_outside.glb
  [floor_wood.glb]=props/kk_dungeon/floor_wood_large.glb
  [d_wall.glb]=props/kk_dungeon/wall.glb
  [d_wall_doorway.glb]=props/kk_dungeon/wall_doorway.glb
  [d_wall_corner.glb]=props/kk_dungeon/wall_corner.glb
  [torch.glb]=props/kk_dungeon/torch_lit.glb
  [chest.glb]=props/kk_dungeon/chest.glb
  [key.glb]=props/kk_dungeon/key.glb
  [coin_stack.glb]=props/kk_dungeon/coin_stack_medium.glb
  [banner.glb]=props/kk_dungeon/banner_red.glb
  [barrel.glb]=props/mega_fantasy/barrel.glb
  [bench.glb]=props/mega_fantasy/bench.glb
  [tree_1.glb]=props/kk_nature/Tree_1_A_Color1.glb
  [tree_2.glb]=props/kk_nature/Tree_2_A_Color1.glb
  [tree_3.glb]=props/kk_nature/Tree_3_A_Color1.glb
  [bush_1.glb]=props/kk_nature/Bush_1_A_Color1.glb
  [bush_2.glb]=props/kk_nature/Bush_2_A_Color1.glb
  [grass.glb]=props/kk_nature/Grass_1_A_Color1.glb
  [sky.hdr]=skies/ph_kloofendal_38d_partly_cloudy_puresky.hdr
)
for name in "${!M[@]}"; do
  echo "fetch $name"
  curl -sfL "$B/${M[$name]}" -o "$name"
done
echo "done."
