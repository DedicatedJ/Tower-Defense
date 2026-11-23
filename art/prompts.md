# Art prompt pack

Generated from `art/assets.lua` by `tools/artkit`. Do not edit by hand: change the data and rebuild.
Workflow, file naming and the accept checklist are in `art/README.md`.

Every image prompt below already ends with the style block:

```text
Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 1. Set the look first

Run these two, pick one of each, and send them to me before anything else. Everything after redraws from them.
The map look is set by the first map in section 11.

### tower_archer

- Save as: `art/incoming/tower_archer_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A single archer tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A round tower of fitted grey stone topped by a wooden lookout platform with a ring of pointed wooden stakes along its edge and a bare wooden flagpole with a gold finial. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### enemy_zombie

- Save as: `art/incoming/enemy_zombie_v2.png` (next try `_v3`; never overwrite). Format: png.
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

## 2. Other towers

### tower_cannon

- Save as: `art/incoming/tower_cannon_v3.png` (next try `_v4`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single cannon tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A squat square stone bastion with thick crenellated walls and one short black iron mortar on top pointing straight up, gold bands around its muzzle. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_magic

- Save as: `art/incoming/tower_magic_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single mage tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A slender tower of pale stone with smooth carved bands, open at the top, where one large violet crystal floats upright above the rim. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_frost

- Save as: `art/incoming/tower_frost_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single frost tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A tower of blue-grey stone whose crown is a cluster of tall pale ice-blue crystals, with frost on the upper stones. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_crossbow

- Save as: `art/incoming/tower_crossbow_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single crossbow tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A sturdy tower of dark timber over stone, bound with iron straps, with a roofed firing deck on top and narrow firing slits on all four sides. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_bombard

- Save as: `art/incoming/tower_bombard_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single bombard tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A low, wide round drum tower of stone wrapped in iron bands, with one fat iron mortar on top pointing straight up and a small stack of round iron bombs beside it. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 3. Other enemies

### enemy_skeleton

- Save as: `art/incoming/enemy_skeleton_v2.png` (next try `_v3`; never overwrite). Format: png.
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

- Save as: `art/incoming/enemy_orc_v2.png` (next try `_v3`; never overwrite). Format: png.
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

- Save as: `art/incoming/enemy_necromancer_v2.png` (next try `_v3`; never overwrite). Format: png.
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

- Save as: `art/incoming/enemy_dragon_v2.png` (next try `_v3`; never overwrite). Format: png.
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

- Save as: `art/incoming/bg_hub_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, the inner courtyard of a fortified border keep at dusk, stone walls, braziers and stacked supply crates. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_level_select

- Save as: `art/incoming/bg_level_select_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, seen from above, a weathered campaign map spread on a heavy wooden table, its land drawn as painted hills, forests and roads with no writing on it, held flat by a dagger and a candle stub. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_shop

- Save as: `art/incoming/bg_shop_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, the interior of a quartermaster's armory with shelves of potions, crossbow bolts and shields lit by a warm lantern. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_tower_upgrade

- Save as: `art/incoming/bg_tower_upgrade_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, a stonemason's workshop with small carved tower models on a workbench, chisels and blueprint sheets showing only drawn lines. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### bg_pause

- Save as: `art/incoming/bg_pause_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: nothing

```text
A wide painted backdrop for a game menu screen, a quiet night view from castle battlements over a misty valley, cold blue moonlight. The center of the image is calm and slightly darker so menu panels can sit over it; detail is at the edges. Evening light with mist. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 5. Level thumbnails

### thumb_training_grounds

- Save as: `art/incoming/thumb_training_grounds_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality medium, 1K.
- Attach: nothing

```text
A small painted preview of a tower defense battlefield, top-down three-quarter view: a tidy training field with straw targets and a fenced dirt road, with a winding road crossing it. Strong simple shapes that read at small size. No people, no text.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### thumb_wilderness

- Save as: `art/incoming/thumb_wilderness_v2.png` (next try `_v3`; never overwrite). Format: png.
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

- Save as: `art/incoming/icons_achievements_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 16:9. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = `art/guides/icon_sheet_8_guide.png`

```text
Scene: An icon sheet of exactly 8 separate game icons on a transparent background, laid out as in image 1. Image 1 is the layout guide: 8 empty boxes in two rows of four. Put one icon in each box, centered, with clear space around it. Every icon sits on the same round bronze medallion with a thin gold rim, front-facing, all the same size. No ground under them and no shadows.

Icons, left to right, top row then bottom: one small stone tower; exactly three small stone towers side by side; a battered round shield with a crack across it; a gold crown resting on a laurel wreath; a tidy stack of gold bars; an unbroken round shield with a gold star on its face; two small stone towers joined by a gold beam of light; three crossed swords, gold, silver and violet.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 7. Sound effects

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

### sfx_shot_holy

- Save as: `art/incoming/sfx_shot_holy_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a single soft bright chime with a quick airy swish, like a beam of light
```

### sfx_shot_fire

- Save as: `art/incoming/sfx_shot_fire_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a quick whoosh of a fireball launching, with a short crackle
```

### sfx_shot_poison

- Save as: `art/incoming/sfx_shot_poison_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a short wet hiss and a bubbling splash, like a glob of acid
```

### sfx_shot_void

- Save as: `art/incoming/sfx_shot_void_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a short deep warbling hum that drops in pitch, dark and hollow
```

### sfx_shot_soul

- Save as: `art/incoming/sfx_shot_soul_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a short ghostly whispering whoosh with a faint eerie tone, no words
```

### sfx_shot_hybrid

- Save as: `art/incoming/sfx_shot_hybrid_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a quick shimmer that is half a high bright chime and half a low dark hum, together
```

### sfx_shot_frost

- Save as: `art/incoming/sfx_shot_frost_v1.wav` (next try `_v2`; never overwrite). Format: wav or mp3.
- Model: Mirelo SFX (text to audio). Duration: 1 s.
- Attach: nothing

```text
a quick icy crystalline shatter and hiss
```

## 8. Faction towers (Model C)

Attach the approved `tower_archer` final as image 1. Cut each with `tools/artcut tower` to
`sprites/towers/<tower id>.png`; the game uses it in place of the stand-in sprite automatically.

### tower_holy_bastion

- Save as: `art/incoming/tower_holy_bastion_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single healing shrine tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A round tower of white stone with gold trim, topped by an open gold-domed shrine holding a softly glowing pale gold orb. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_seraphim_altar

- Save as: `art/incoming/tower_seraphim_altar_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single holy fire altar tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A square stone tower topped by a gold altar bowl holding a tall steady white-gold flame, with two small carved stone wings at its sides. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_seraphs_watch

- Save as: `art/incoming/tower_seraphs_watch_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single tall sniper watchtower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A tall slender white stone spire with a gold-roofed lookout at the very top and a long gold crossbow mounted pointing straight forward. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_cursed_spire

- Save as: `art/incoming/tower_cursed_spire_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single cursed poison spire for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A narrow black stone spire with cracked surfaces, sickly green crystals set into its sides and a hollow top holding still pale green mist. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_oblivion_engine

- Save as: `art/incoming/tower_oblivion_engine_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single necromantic summoning tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A dark violet stone tower ringed with bone ribs, a round summoning circle carved on its flat top, and a violet crystal floating above it. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_soul_forge

- Save as: `art/incoming/tower_soul_forge_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single soul forge tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A squat dark iron forge tower with a glowing teal furnace mouth on its front, a short chimney, and chains hanging from iron hooks. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_dawn_dusk_nexus

- Save as: `art/incoming/tower_dawn_dusk_nexus_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single dawn and dusk tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A round tower split down the middle: the left half pale stone with gold trim, the right half dark slate with silver trim, topped by an orb that is half gold and half deep blue. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_eclipse_monolith

- Save as: `art/incoming/tower_eclipse_monolith_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single eclipse monolith for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A tall black obsidian monolith with a ring-shaped opening near its top, and a dark disc with a thin bright rim floating inside the ring. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### tower_elemental_nexus

- Save as: `art/incoming/tower_elemental_nexus_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 1:1. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `tower_archer` final

```text
Image 1 is an approved tower from the same set. Draw a different tower in the same set: keep exactly the square stone base, its size and shape, the camera angle, the scale, the light and the painting style. Change only the tower above the base. A single fire and ice tower for a tower defense game, alone and centered on a transparent background, top-down three-quarter view. A round tower of blue-grey stone crowned with two crystals side by side: one ember orange, one ice blue. It stands on a square grey stone base that fills the lower third. The whole tower is in frame with clear space on all sides. No ground, no shadow under it, no people. Use the colors and materials described here for the tower above the base, even where they differ from the rest of the set; only the base stays grey stone.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 9. Hero walk sheets (Model C)

Attach the approved `enemy_zombie` sheet as image 1. Cut each with `tools/artcut sheet` (feet anchor)
to `sprites/heroes/<hero id>.png` and `.lua`; the hero is drawn from it automatically.

### hero_sir_galahad

- Save as: `art/incoming/hero_sir_galahad_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different holy knight. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A young man with short spiky blond hair. One dominant color: white with gold trim.

Gear: White plate armor with gold edges and a gold sun emblem on the chest, large gold feathered shoulder guards, a long white cape lined with blue, and a longsword with a gold hilt in his right hand. Plain surfaces throughout.

Not carried over: No hood, no green skin, no torn clothing, no wings. He is a healthy human man.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_lady_celestia

- Save as: `art/incoming/hero_lady_celestia_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different priestess. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A tall woman with very long flowing silver-white hair. One dominant color: white with gold trim.

Gear: A long white gown with gold embroidery, gold shoulder armor, white gloves, a light blue cape, and a tall gold staff topped with a ring around a glowing orb in her right hand. Plain surfaces throughout.

Not carried over: No hood, no green skin, no torn clothing. She is a healthy human woman.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_archangel_michael

- Save as: `art/incoming/hero_archangel_michael_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different archangel. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A tall man with long dark brown hair and very large white feathered wings folded behind him. One dominant color: gold.

Gear: Gleaming gold plate armor over a white tunic, a gold longbow in his left hand and a quiver on his back between the wings. Plain surfaces throughout.

Not carried over: No hood, no helmet, no green skin, no torn clothing. His hair is dark brown, never blond or golden.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_malachi

- Save as: `art/incoming/hero_malachi_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different necromancer lord. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A pale gaunt man with straight shoulder-length white hair. One dominant color: dark blue with blood red accents.

Gear: A long dark blue robe with a few thin red lines, black spiked shoulder armor set with red gems, a skull clasp on the chest, a black cape, and a staff topped with a skull holding a red crystal in his right hand. Plain surfaces throughout.

Not carried over: No green skin, no torn clothing, no hood.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_morgana

- Save as: `art/incoming/hero_morgana_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different dark sorceress. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A slim woman with long straight black hair. One dominant color: black with silver.

Gear: A long black high-collared robe and cape with silver edges and three small white skull ornaments down the front, white gloves, and a tall gold staff with a ring top in her right hand. Plain surfaces throughout.

Not carried over: No green skin, no torn clothing, no hood.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_dark_lord_malak

- Save as: `art/incoming/hero_dark_lord_malak_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different dark warlord. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A towering armored warlord with glowing violet eyes behind a horned helm. One dominant color: black with violet.

Gear: Spiked black plate armor, a black cape, a large two-handed black greatsword held in both hands. Plain surfaces throughout.

Not carried over: No green skin, no hood.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_zephyr

- Save as: `art/incoming/hero_zephyr_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different knight duelist. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A lean young man with short messy black hair. One dominant color: silver steel with crimson.

Gear: Engraved silver plate armor over a crimson tunic and crimson sash, a long white cape, and one long straight silver sword in his right hand. Plain surfaces throughout.

Not carried over: No green skin, no torn clothing, no hood.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_lyra

- Save as: `art/incoming/hero_lyra_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different star mage. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: A young woman with short straight silver-white hair. One dominant color: deep navy blue with gold.

Gear: A long deep navy robe and cape with a few large silver moons and gold stars, gold edges, white gloves, and a tall gold staff with a ring top in her right hand. Plain surfaces throughout.

Not carried over: No green skin, no torn clothing, no hood.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### hero_elemental_sage

- Save as: `art/incoming/hero_elemental_sage_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6. Aspect 3:4. Background: transparent.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = the approved `enemy_zombie` sheet

```text
Scene: Image 1 is an approved walk sheet. Redraw the whole sheet as a different elemental sage. Keep exactly: the grid, the place of every figure, every pose and facing, the camera, the height of the figures, the proportions, the painting style and the transparent background. Change only the creature and its gear.

Character: An old man with a long white beard. One dominant color: half orange, half ice blue.

Gear: A long robe whose left half is ember orange and right half is ice blue, and a staff topped with one orange and one blue crystal. Plain surfaces throughout.

Not carried over: No green skin, no torn clothing, no hood.

Style: Painterly 2D game art in a clean hand-painted style, top-down three-quarter view, warm light from the upper left. A dark-fantasy borderland of mossy grass, packed earth roads, grey stone and weathered timber. The defenders' towers are grey stone and warm wood with gold trim; the invaders are undead and monsters in sickly green, bone white, rust red, violet and ember orange. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

## 10. Missing hero portraits

Attach an existing portrait (for example `assets/hero images/radiant order/Galahad/Sir Galahad.jpg`)
as image 1. Opaque, 4:3. Each goes to its `file` in `art/assets.lua` (A.portraits).

### portrait_archangel_michael

- Save as: `art/incoming/portrait_archangel_michael_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = an existing hero portrait

```text
A character portrait in exactly the same art style, line work, coloring, framing and light as image 1 (an approved portrait from the same set), but a different person: an archangel with long dark brown hair, very large white feathered wings spread behind him, gleaming gold plate armor over a white tunic, holding a gold longbow. Shown from the thighs up, facing the viewer, with the head near the top center of the frame as in image 1. Behind: a bright sky with soft clouds and a distant white stone tower, painted the same way as the background of image 1. Do not copy the person, armor or weapon from image 1. No text, no logos, no watermark.
```

### portrait_dark_lord_malak

- Save as: `art/incoming/portrait_dark_lord_malak_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = an existing hero portrait

```text
A character portrait in exactly the same art style, line work, coloring, framing and light as image 1 (an approved portrait from the same set), but a different person: a towering warlord in spiked black plate armor and a horned helm with glowing violet eyes, a black greatsword resting on his shoulder. Shown from the thighs up, facing the viewer, with the head near the top center of the frame as in image 1. Behind: a dusk violet sky over dark mountains, painted the same way as the background of image 1. Do not copy the person, armor or weapon from image 1. No text, no logos, no watermark.
```

### portrait_elemental_sage

- Save as: `art/incoming/portrait_elemental_sage_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6 or Nano Banana Pro. Aspect 4:3. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K.
- Attach: image 1 = an existing hero portrait

```text
A character portrait in exactly the same art style, line work, coloring, framing and light as image 1 (an approved portrait from the same set), but a different person: an old sage with a long white beard in a robe that is half ember orange and half ice blue, holding a staff topped with one orange and one blue crystal. Shown from the thighs up, facing the viewer, with the head near the top center of the frame as in image 1. Behind: a bright sky with soft clouds over distant green hills, painted the same way as the background of image 1. Do not copy the person, armor or weapon from image 1. No text, no logos, no watermark.
```

## 11. Level maps

Attach the level's layout from `art/guides/` as image 1. Make `map_sunlit_meadows` first and send it to me before the rest: it sets the look of every map, and each other map attaches its approved final as image 2. I check each painting against the layout (road in place and 80 px wide, plots in their rectangles); once a level's painted road matches, the game stops drawing its own road over it.

Check before sending: the road is as wide as the gray band everywhere and its bends are rounded; the plots are the lightest ground and sit in their rectangles; nothing that looks like a tower, a unit or a button; the corners and the top middle are plain.

### map_sunlit_meadows

- Save as: `art/incoming/map_sunlit_meadows_v1.png` (next try `_v2`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_sunlit_meadows_blockout.png`

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Place: Sunlit Meadows, the first level a new player sees: friendly farmland on a clear late morning, calm and inviting.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There is one road. It enters at the left edge near the top, bends eight times and ends at a point inside the map, near the bottom and toward the right. Leave that rounded end plain: the game marks the goal on it.

Road: packed brown earth with two faint cart ruts. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: short, even meadow grass in fresh light green. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: leafy hedgerows, round oak trees, patches of wildflowers, low dry-stone field walls and one small still pond; wilder and more overgrown where the road enters, neat farmland toward its end. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_crystal_spires

- Save as: `art/incoming/map_crystal_spires_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_crystal_spires_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Crystal Spires: a windswept highland plateau where pale crystals grow out of the rock.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There are two roads. The first road enters at the left edge near the top, bends six times and leaves at the right edge in the middle. A second road enters at the left edge near the bottom, bends twice and joins the first road at the center of the map; from there they are one road.

Road: warm tan packed earth. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: short pale-green upland grass. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: grey granite outcrops with clusters of tall pale-blue crystal spires, heather, scree and a few hardy pines; the crystals are dark and cracked where the two roads enter on the left and clear and bright toward the right, where the road leaves. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_celestial_citadel

- Save as: `art/incoming/map_celestial_citadel_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_celestial_citadel_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Celestial Citadel: the inner courts of a white and gold holy fortress, the Radiant Order's last stand, grand and solemn.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There is one road. It enters at the left edge near the top, bends six times and ends at a point inside the map, halfway down and toward the left. Leave that rounded end plain: the game marks the goal on it.

Road: warm grey-brown sandstone flagstones. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: trimmed lawns of bright green grass. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: white stone walls with gold trim, gold-tiled rooftops seen from above, marble terraces, tall cypress trees and formal flowerbeds. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_haunted_forest

- Save as: `art/incoming/map_haunted_forest_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_haunted_forest_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Haunted Forest: a cold, dead wood at dusk, the first level of the Shadow Covenant, eerie but quiet.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There is one road. It enters at the left edge near the top, bends six times and leaves at the left edge near the bottom.

Road: a dark brown dirt trail packed hard. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: clearings of soft green moss over level ground. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: a dense dead forest seen from above: grey twisted trees with bare branches, tangled roots, ferns, fallen logs, mossy boulders and pale mushrooms. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_obsidian_caves

- Save as: `art/incoming/map_obsidian_caves_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_obsidian_caves_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Obsidian Caves: a great cavern of black volcanic glass, lit through openings far above.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There is one road. It enters at the left edge in the middle, bends six times and leaves at the right edge in the middle.

Road: grey-brown packed gravel. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: level ledges of pale sand with patches of dull green lichen. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: walls and heaps of black obsidian rock with sharp glassy edges, faint amber glints deep in the cracks, and dark chasms. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_necropolis

- Save as: `art/incoming/map_necropolis_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_necropolis_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Necropolis: a vast walled city of the dead under a grey sky, the Shadow Covenant's last stand, grim and dramatic.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There is one road. It enters at the left edge near the top, bends seven times and leaves at the right edge near the bottom. Part way along, the road stops at a point inside the map, near the bottom and toward the left, and starts again at a point inside the map, near the top and in the middle; there is no road between those two points. Paint each of those two road ends as a round dais of dark carved stone as wide as the road: the game draws a portal on each.

Road: worn grey-brown paving stones. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: overgrown cemetery lawns of dark sage-green grass with a few flat stones set level in it. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: crypts and mausoleum roofs seen from above, rows of headstones behind low iron railings, bare black trees and cracked stone walls. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_misty_borderlands

- Save as: `art/incoming/map_misty_borderlands_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_misty_borderlands_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Misty Borderlands: a quiet fen on the border between day and night, the first level of the Twilight Balance, soft and still.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There is one road. It enters at the left edge in the middle, bends six times and leaves at the right edge near the top.

Road: a raised causeway of packed brown earth. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: firm islands of blue-green grass. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: still marsh water in shades of slate blue, reed beds, mossy hummocks, a few bare silver trees and old weathered border stones. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_ethereal_ruins

- Save as: `art/incoming/map_ethereal_ruins_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_ethereal_ruins_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Ethereal Ruins: the overgrown remains of an ancient city, quiet and sunlit.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There are two roads. The first road enters at the left edge near the top, bends six times and leaves at the right edge near the top. A second road enters at the left edge near the bottom, bends twice and joins the first road at a point inside the map, halfway down and toward the left; from there they are one road.

Road: warm cracked sandstone paving. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: level courtyards of short green grass. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: collapsed walls, broken columns and toppled carved blocks of grey stone darkened by moss, half buried in grass, roots and ivy. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```

### map_nexus_of_balance

- Save as: `art/incoming/map_nexus_of_balance_v2.png` (next try `_v3`; never overwrite). Format: png.
- Model: GPT Image 2.6; if it moves, bends or narrows the road, try Nano Banana Pro. Aspect 16:9. Background: opaque.
- Draft: quality low, 1K. Final: quality high, 2K (4K if offered).
- Attach: image 1 = `art/guides/map_nexus_of_balance_blockout.png`; image 2 = the approved `map_sunlit_meadows` final

```text
Scene: Repaint image 1 as the finished painted ground of one level of a tower defense game, filling the whole wide frame, seen from directly above. Image 1 is a layout in three grays, and each gray has one job. Keep every shape exactly where it is, at the same size, with the same outline.

Image 2 is the approved map of another level of the same game. Paint this one the same way: the same painting style, camera, light and level of detail, and the same way of painting the road, the plots and the scenery. Take nothing else from image 2: not its layout, its places or its colors.

Place: Nexus of Balance: where night and day meet, the Twilight Balance's last stand, strange and dramatic.

The mid gray band is the road the enemies walk: the same path, the same width and the same smoothly rounded bends. Do not add, move, straighten, widen or narrow any part of it. There are two roads. The first road enters at the left edge near the top, bends eight times and leaves at the right edge near the bottom. A second road enters at the top edge near the right, bends four times and joins the first road at the center of the map; from there they are one road.

Road: pale grey-brown stone paving, the same on both sides. The surface fills the band from edge to edge: one material, matte, in a calm middle tone, with soft low-contrast wear and nothing lying on it. Any edging is a thin line at the very edge of the band.

The light gray rectangles are build plots, where the player places towers. Plots: level grass, lavender-grey on the left half of the map and pale gold on the right half. Each fills its rectangle edge to edge: flat, open and even, the lightest ground on the map, with fine texture only, so a tower can stand anywhere on it.

The dark gray is scenery, where nothing stands: on the left, a violet night land with dark standing stones and still pools; on the right, a golden day land with dry grass and sun-bleached rocks; the two blend through a grey band in the middle of the map, where the roads meet. It fills every dark gray area up to the road and the plots and holds the rich detail of the map. It is darker and busier than the plots, and nothing in it reaches over the road or a plot.

Game view: the map is shown at 1280 by 720 pixels, with towers about 60 pixels wide on the plots and enemies about 60 pixels tall on the road, so the road and the plots stay calm and readable at that size. Warm light from the upper left, even across the road and the plots, with no large shadows falling over them. The four corners and the middle of the top edge sit under the game's buttons: keep them plain, dark scenery. Nothing on the map is a tower, a person, a creature, a flag, fire, smoke, a frame, a box or lettering.

Style: Painterly 2D game art in a clean hand-painted style, seen from directly above; tall scenery such as trees, walls and cliffs shows a little of its south side, as in a top-down three-quarter game. Warm light from the upper left. Muted natural palette with warm gold accents, crisp edges, readable at small size. No text, no logos.
```
