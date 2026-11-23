# Art pipeline

You generate on Higgsfield (site or Claude chat, where the free unlimited generations work). Claude Code
cuts, sizes and wires the results into the game. Claude Code cannot use the unlimited generations.

| File | What it is |
|---|---|
| `art/prompts.md` | Ready-to-paste prompts, one per asset, with model, settings, what to attach and the file name to save as |
| `art/assets.lua` | The data `prompts.md` is built from. Change prompts here, never in `prompts.md` |
| `art/guides/` | Gray layout guides to attach as image 1 |
| `art/incoming/` | Drop folder for what you generate |
| `art/manifest.md` | Record of every accepted and rejected file (kept by Claude Code when processing) |
| `tools/artkit/` | Rebuilds the guides and `prompts.md` |

Rebuild after editing `art/assets.lua` (run from the repo root):

```bash
"/c/Program Files/LOVE/lovec.exe" tools/artkit "$(pwd -W)"
```

## Order of work

1. **Set the look.** Run section 1 of `prompts.md`: `tower_archer`, `enemy_zombie`, `map_level1`. Draft at low
   quality first, then run the final of the pick. Drop the picks in `art/incoming/` and tell Claude Code.
   These three get cut and put in the game first, so the look can be judged on the real map at real size.
2. **Towers.** Each remaining tower attaches the approved `tower_archer` final as image 1, so the base and
   scale match.
3. **Enemies.** Each remaining sheet attaches the approved `enemy_zombie` sheet as image 1.
4. **Screens, thumbnails, icons, sound.** Sections 4 to 7, any order.
5. **Level maps.** Section 11. `map_sunlit_meadows` first; once it is approved, every other map attaches it
   as image 2. The layouts in `art/guides/` are drawn from `data/levels.lua`: dark gray is scenery, mid
   gray is the 80 px road with rounded bends, light gray is the build plots (the level's zones). Rebuild
   them with `tools/artkit` whenever a level's paths or zones change.

## Saving files

- Name: `<id>_v<N>.<ext>`, for example `tower_cannon_v2.png`. The id is the heading in `prompts.md`.
- Never overwrite. A redo is the next version number. Rejected versions stay until you say to delete them.
- Download the full-size file, not a preview or a screenshot. Sprites and sheets must be PNG with transparency.
- Higgsfield share links work too: Claude Code downloads the full image from the link and files it here.
- `art/incoming/` is not committed to git (originals run to several MB each). It lives on the local
  disk only; `art/manifest.md` records the share link for every file so it can be fetched again.

## Settings that matter

- Transparent background for towers, walk sheets and icons. If the result has a solid or checkerboard
  background baked in, it is not transparent: run it again, or run Higgsfield's background remover on it.
- Walk sheets at 3:4 and 2K. At 1K a figure ends up too small to cut cleanly.
- The size of an object inside the image does not matter. Size is set in code per asset.

## Redos

Attach the last output as image 1 and change one thing: "Image 1 is the previous version. Change only one
thing: [the change]. Keep everything else exactly." Rewriting the whole prompt loses what was right.

## Accept checklist

- [ ] Full size (not silently dropped to 1K when 2K was asked)
- [ ] Transparent where it should be
- [ ] Right count: 12 figures on a walk sheet, 8 icons, one tower
- [ ] Nothing copied from the guide: no gray boxes or mannequin shapes left in
- [ ] Nothing leaked from the reference that was not asked for (the zombie's hood on the skeleton)
- [ ] Nothing painted that should move: no flames, smoke, waving cloth or ripples with fish
- [ ] No lettering or numerals anywhere
- [ ] Enemies tell apart by color and outline at a glance

## Processing (Claude Code)

`tools/artcut` turns files in `art/incoming/` into runtime assets. Run from the repo root with
`"/c/Program Files/LOVE/lovec.exe" tools/artcut <command> ...` and absolute paths.

| Command | Use | Output |
|---|---|---|
| `info <in> [floor]` | Size, transparency report, bounding box | report only |
| `tower <in> <out> <width>` | One transparent object: strip glow below alpha 200, trim, scale | `sprites/towers/*.png`, 96 px wide |
| `sheet <in> <out.png> <out.lua> <figureH> [floor] [rows] [cols] [feet\|mass]` | 4x3 walk sheet: find figures by shape, align (feet for walkers, body for flyers), scale | sheet PNG plus frame layout `.lua` |
| `backdrop <in> <out> <w> <h> [--stretch]` | Opaque image: center crop to aspect (or stretch the whole image), scale | `assets/backgrounds/*.png` at 1280x960; `sprites/maps/*.png` at 1280x720 |
| `mapcheck <map> <blockout> <cols> <rows>` | Cell-by-cell road match against the old 24 x 18 cell blockouts. Not updated for the 16:9 three-gray layouts yet | report and grid |
| `mapfix <map> <blockout> <out> <w> <h>` | Stretch the painted road onto the old 24 x 18 cell grid. From before the 16:9 map; until a 16:9 painting is checked, the game draws the road over it | was `sprites/maps/*.png` at 1536x1152 |
| `icons <in> <outDir> <size> <rows> <cols> <names>` | Round icons on a sheet; keys out a painted-in checkerboard | one PNG per icon |

## Rights

The anime hero portraits and some backdrops already in the repo carry a "Grok" watermark. They should be
replaced before anything is published. Higgsfield's terms on ownership and training were not reviewed here.
