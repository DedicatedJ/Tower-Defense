# Art prompt pack

Generated from `art/assets.lua` by `tools/artkit`. Do not edit by hand: change the data and rebuild.
Workflow, file naming and the accept checklist are in `art/README.md`.

Every image prompt below already ends with the style block:

```text
Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 1. Set the look first

Run these three, pick one of each, and send them to me before anything else. Everything after redraws from them.

### tower_archer

- Save as: `art/incoming/tower_archer_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A single archer tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A round tower of fitted grey stone topped by a wooden lookout platform with a ring of pointed wooden stakes along its edge and a bare wooden flagpole with a gold finial. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### enemy_zombie

- Save as: `art/incoming/enemy_zombie_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = `art/guides/walk_sheet_guide.png`

```text
Scene: A character walk sheet for a 2D game: twelve full-body drawings of the same zombie in a grid of 4 rows and 3 columns on a transparent background, laid out exactly as in image 1. Image 1 is the pose and layout guide: twelve gray mannequins. Replace each mannequin with the zombie, in the same cell, the same pose, the same facing and the same size.

Layout: Row 1 walks toward the camera. Row 2 walks right. Row 3 walks left. Row 4 walks away, seen from behind. Each row is left foot forward, standing still, right foot forward. Big, obvious strides with arms swinging. One figure per cell, centered, every foot in a row on one line, wide clear space between figures. The same zombie, the same gear and the same height in all twelve.

Character: A hunched, shambling zombie with sickly green skin, sunken dark eyes and thin limbs. One dominant color: sickly green.

Gear: A ragged brown hooded tunic with a torn hem and bare green feet. Plain surfaces throughout.

Details: Drawn from slightly above, to match a top-down three-quarter game map. Large head, compact body. Transparent background, with empty space under the feet.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_level1

- Save as: `art/incoming/map_level1_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves the road again, try Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_level1_blockout.png`

```text
Scene: Repaint image 1 as a finished painted map for a tower defense game, seen from directly above. Image 1 is a gray layout: the dark gray band is the road and the light gray is grass. Keep the road exactly where the dark band is: the same path, the same width, the same square corners, in the same places across the whole image. Do not add, move, straighten, widen or smooth any part of it.

Road: packed brown earth. Any stone edging lies inside the dark band, so the road with its edging is no wider than the band. The road runs along the very top edge from the top left corner and has exactly eight right-angle turns. Its far end is the short stretch in the lower part of the image, right of center, where a small ruined stone gate stands across the road.

Ground: open, flat mossy grass, even and uncluttered so a tower can stand on any patch of it, with small rocks, wildflowers and short tufts only. No trees, no buildings, no towers, no units, no animals, no smoke, no flags.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 2. Other towers

### tower_cannon

- Save as: `art/incoming/tower_cannon_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single cannon tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A squat square stone bastion with thick crenellated walls and one short black iron mortar on top pointing straight up, gold bands around its muzzle. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_magic

- Save as: `art/incoming/tower_magic_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single mage tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A slender tower of pale stone with smooth carved bands, open at the top, where one large violet crystal floats upright above the rim. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_frost

- Save as: `art/incoming/tower_frost_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single frost tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A tower of blue-grey stone whose crown is a cluster of tall pale ice-blue crystals, with frost on the upper stones. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_crossbow

- Save as: `art/incoming/tower_crossbow_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single crossbow tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A sturdy tower of dark timber over stone, bound with iron straps, with a roofed firing deck on top and narrow firing slits on all four sides. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_bombard

- Save as: `art/incoming/tower_bombard_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single bombard tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A low, wide round drum tower of stone wrapped in iron bands, with one fat iron mortar on top pointing straight up and a small stack of round iron bombs beside it. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 3. Other enemies

### enemy_skeleton

- Save as: `art/incoming/enemy_skeleton_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different skeleton warrior. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: An upright skeleton with bone-white bones and a grinning skull. One dominant color: bone white.

Gear: A small round wooden shield on its left forearm and a rusted short sword in its right hand. No armor. Plain surfaces throughout.

Not carried over: No hood, no tunic, no green skin. The skull is bare.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### enemy_orc

- Save as: `art/incoming/enemy_orc_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different orc brute. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A broad, heavy orc with rust-red skin, small tusks and a thick neck, taller and wider in the shoulders than the zombie. One dominant color: rust red.

Gear: A dented iron helmet with two short horns, a leather kilt and a heavy wooden club in its right hand. Plain surfaces throughout.

Not carried over: No hood, no tunic. Skin is rust red, not green.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### enemy_necromancer

- Save as: `art/incoming/enemy_necromancer_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different necromancer. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A gaunt pale figure whose face is in deep shadow under a tall pointed hood. One dominant color: violet.

Gear: A long violet robe that reaches the ankles with a bone-white trim, and a tall dark staff in its right hand topped with a pale green orb. Plain surfaces throughout.

Not carried over: No green skin, no torn hem. The hood is tall and pointed and the robe is whole.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### enemy_dragon

- Save as: `art/incoming/enemy_dragon_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different young dragon flying. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A young dragon with ember-orange scales, a cream belly, two short horns and a long tail, flying with its wings spread. In each row the three frames are wings raised, wings level, wings lowered, instead of footsteps. It hovers with empty space below it and no feet on a line. One dominant color: ember orange.

Gear: No gear. Plain surfaces throughout.

Not carried over: No hood, no clothing, no human body. It is a four-legged winged dragon.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 4. Screen backdrops

### bg_hub

- Save as: `art/incoming/bg_hub_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, the inner courtyard of a fortified border keep at dusk, stone walls, braziers and stacked supply crates. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_level_select

- Save as: `art/incoming/bg_level_select_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, seen from above, a weathered campaign map spread on a heavy wooden table, its land drawn as painted hills, forests and roads with no writing on it, held flat by a dagger and a candle stub. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_shop

- Save as: `art/incoming/bg_shop_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, the interior of a quartermaster's armory with shelves of potions, crossbow bolts and shields lit by a warm lantern. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_tower_upgrade

- Save as: `art/incoming/bg_tower_upgrade_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, a stonemason's workshop with small carved tower models on a workbench, chisels and blueprint sheets showing only drawn lines. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_pause

- Save as: `art/incoming/bg_pause_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, a quiet night view from castle battlements over a misty valley, cold blue moonlight. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 5. Level thumbnails

### thumb_training_grounds

- Save as: `art/incoming/thumb_training_grounds_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: a tidy training field with straw targets and a fenced dirt road, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_wilderness

- Save as: `art/incoming/thumb_wilderness_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: rolling green wilderness with scattered rocks and a stream, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_ancient_ruins

- Save as: `art/incoming/thumb_ancient_ruins_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: crumbling grey stone ruins and broken columns overgrown with moss, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_sunlit_meadows

- Save as: `art/incoming/thumb_sunlit_meadows_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: bright golden meadows with several forking roads, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_crystal_spires

- Save as: `art/incoming/thumb_crystal_spires_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: raised rock plateaus crowned with pale crystals, joined by wooden bridges, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_celestial_citadel

- Save as: `art/incoming/thumb_celestial_citadel_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: a round white-stone citadel at the center of a ring road under a gold sky, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_haunted_forest

- Save as: `art/incoming/thumb_haunted_forest_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: a dark twisted forest with a narrow winding road and pale green fog, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_obsidian_caves

- Save as: `art/incoming/thumb_obsidian_caves_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: black glassy cave tunnels lit by thin orange lava seams, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_necropolis

- Save as: `art/incoming/thumb_necropolis_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: a maze of tombs and mausoleums with two glowing violet portal arches, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_misty_borderlands

- Save as: `art/incoming/thumb_misty_borderlands_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: grey moorland half hidden by drifting banks of fog, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_ethereal_ruins

- Save as: `art/incoming/thumb_ethereal_ruins_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: pale floating stone ruins with broken walls over a soft blue glow, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_nexus_of_balance

- Save as: `art/incoming/thumb_nexus_of_balance_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: ground split into a sunlit half and a shadowed violet half, meeting at a stone circle, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 6. Achievement icons

### icons_achievements

- Save as: `art/incoming/icons_achievements_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 16:9. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = `art/guides/icon_sheet_8_guide.png`

```text
Scene: An icon sheet of exactly 8 separate game icons on a transparent background, laid out as in image 1. Image 1 is the layout guide: 8 empty boxes in two rows of four. Put one icon in each box, centered, with clear space around it. Every icon sits on the same round bronze medallion with a thin gold rim, front-facing, all the same size. No ground under them and no shadows.

Icons, left to right, top row then bottom: one small stone tower; exactly three small stone towers side by side; a battered round shield with a crack across it; a gold crown resting on a laurel wreath; a tidy stack of gold bars; an unbroken round shield with a gold star on its face; two small stone towers joined by a gold beam of light; three crossed swords, gold, silver and violet.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 7. Sound effects

### sfx_enemy_death

- Save as: `art/incoming/sfx_enemy_death_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a short hollow crunch and a dry rattle as a small monster collapses, no voice
```

### sfx_player_damage

- Save as: `art/incoming/sfx_player_damage_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a heavy wooden gate being struck once, a dull thud with a short creak
```

### sfx_hero_ability

- Save as: `art/incoming/sfx_hero_ability_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 2 s.
- Attach: nothing

```text
a bright magical whoosh rising into a short shimmering chime
```

### sfx_purchase

- Save as: `art/incoming/sfx_purchase_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a few gold coins dropped into a leather pouch, short and crisp
```

### sfx_level_up

- Save as: `art/incoming/sfx_level_up_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 2 s.
- Attach: nothing

```text
a short triumphant rising harp glissando ending on a bell
```

### sfx_shot_arrow

- Save as: `art/incoming/sfx_shot_arrow_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a single bowstring twang and an arrow whoosh
```

### sfx_shot_cannon

- Save as: `art/incoming/sfx_shot_cannon_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a single deep mortar boom with a short echo
```

### sfx_shot_magic

- Save as: `art/incoming/sfx_shot_magic_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a quick crackling arcane zap
```

### sfx_shot_frost

- Save as: `art/incoming/sfx_shot_frost_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a quick icy crystalline shatter and hiss
```

### sfx_shot_bolt

- Save as: `art/incoming/sfx_shot_bolt_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a heavy crossbow thunk and a bolt whoosh
```

### sfx_shot_bomb

- Save as: `art/incoming/sfx_shot_bomb_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a hollow mortar thump followed by a short fizzing fuse
```
