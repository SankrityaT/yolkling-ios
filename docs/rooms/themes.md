# Room Themes and Presets

Palettes and curated starter rooms for Yolkling. A room is drawn in pure SwiftUI
vector shapes by RoomView.swift. A theme is just a palette: a `RoomTheme` value with
five hex fields plus rarity and cost (see Core/Rooms/RoomTheme.swift).

The wall fills the top ~66% of the room as a vertical gradient from `wallTop` (up) to
`wallBottom` (down). The floor fills the bottom ~34% in `floor`, with a skirting line and
faint floorboard seams drawn in `floorEdge`. The `accent` colours the rug and any decor
accent. Rarity is `common | rare | epic`. Cost is in Yolks: common 0 to 150, rare 250 to
350, epic 450 to 600.

All colours below are real hex, chosen to stay soft, readable, and cozy on screen. The
yolk creature is a warm yellow, so every palette is tested to keep it legible against the
wall and floor. Decor sets are suggestions drawn from the decor vocabulary: window,
wallArt, floorLamp, plant, rug, bookshelf, bed, beanbag, string lights, poster, clock,
balloons, fairy lights, fireplace.

To add a theme to the app: copy a row's five hex values into a new `RoomTheme` in
`RoomThemes` and append it to `RoomThemes.all`. Use the `0x` prefix, e.g. `wallTop:
0xEFEAD8`.

## Themes

| name | id | wallTop | wallBottom | floor | floorEdge | accent | rarity | cost | vibe | decor set |
|------|----|---------|------------|-------|-----------|--------|--------|------|------|-----------|
| forest cabin | room-forest | EFE7D6 | D9C9A8 | 8E6A4C | 6F503A | 7FA56A | common | 120 | warm timber walls and pine green, like a hug in a log cabin | window, plant, bookshelf, rug, fireplace |
| beach day | room-beach | DDF1F4 | BFE3E6 | EAD7B0 | D2BA8C | F2B07A | common | 100 | soft sky over warm sand, salt air and a lazy afternoon | window, plant, rug, beanbag, string lights |
| candy shop | room-candy | FCE3EE | F8C9DD | F6D7C2 | E8B6A2 | F49AB8 | rare | 300 | strawberry milk walls and a sweet sugar glow | wallArt, balloons, rug, string lights, bookshelf |
| night sky | room-night | 2E3A60 | 1C2444 | 3B3A57 | 282741 | 6FA8DC | epic | 500 | deep dusk blues with a quiet starlit calm | window, fairy lights, bed, rug, floorLamp |
| little library | room-library | EFE3CC | D8C2A0 | 7A5A40 | 5E4530 | A8743F | rare | 320 | wood and old paper, the hush of a reading nook | bookshelf, floorLamp, rug, clock, plant |
| greenhouse | room-greenhouse | E9F6E4 | CDE9CC | C9B894 | B19E78 | 6FB58A | rare | 310 | glassy green light and leaves in every corner | window, plant, rug, bookshelf, string lights |
| ocean deep | room-ocean | CFE9EF | A6D3DE | 8FB7B6 | 6F9695 | 4FA0AE | rare | 300 | cool teal tides and a gentle underwater drift | window, wallArt, rug, plant, fairy lights |
| outer space | room-space | 38305C | 211A40 | 332C4E | 231E3A | C9A6E8 | epic | 520 | violet cosmos with soft drifting starlight | fairy lights, poster, rug, floorLamp, bed |
| autumn | room-autumn | F6E4CC | EBC79E | A06A45 | 7E5234 | D98441 | common | 130 | falling leaves, cinnamon, and golden afternoon light | window, plant, rug, bookshelf, clock |
| winter snow | room-winter | EEF4FA | D6E4F0 | C7D2DD | A9B6C4 | 8FB8D8 | rare | 290 | pale frost blue and a soft quiet snowfall hush | window, fireplace, rug, fairy lights, bed |
| sunrise | room-sunrise | FDEAD2 | F8C9A8 | E9B88E | CF9A70 | F2956E | common | 110 | first warm light of morning, peach and honey | window, plant, rug, beanbag, clock |
| lavender fields | room-lavender | F0E8F7 | DCCBEC | C3B0A0 | A8957F | 9C7CC4 | rare | 300 | endless purple blooms and a breezy calm | window, plant, rug, wallArt, string lights |
| mushroom cottage | room-mushroom | F2E2D6 | E0C2AE | 8C5A3F | 6E432D | D26A5A | rare | 330 | toadstool reds and cozy earthen burrow walls | window, plant, bookshelf, rug, fireplace |
| paper origami | room-paper | F7F2E9 | E7DECB | D8CDB8 | BEB199 | E0976E | common | 90 | clean folded paper world, soft cream and crisp creases | wallArt, poster, rug, plant, clock |
| pastel arcade | room-arcade | EDE6FA | D6C9F2 | B7AECF | 968CB0 | F58FB0 | epic | 480 | retro neon softened into dreamy cotton pastels | poster, string lights, beanbag, rug, fairy lights |
| rainy day | room-rainy | DCE3E8 | C2CCD4 | A7AEB4 | 878E94 | 7C9AB0 | common | 120 | grey window light, warm blanket, the patter of rain | window, beanbag, rug, floorLamp, string lights |

## Presets

A preset is a named starter bundle: one theme plus a chosen decor list. These are the rooms
a player can aim to build out, shown as goals in the room shop. Each preset references a
theme id above and lists the decor pieces to place.

### cozy reading nook
- theme: room-library
- decor: bookshelf, floorLamp, rug, clock, plant
- vibe: a quiet corner of warm wood and old paper, one lamp on, made for slow afternoons.
- rarity feel: rare. A calm, grown-up first upgrade from the starter room.

### pine retreat
- theme: room-forest
- decor: fireplace, bookshelf, plant, rug, window
- vibe: a log cabin in the woods, fire crackling, pine light through the window.
- rarity feel: common. Approachable and warm, a great early goal.

### starlit bedroom
- theme: room-night
- decor: bed, fairy lights, window, rug, floorLamp
- vibe: deep blue dusk, fairy lights strung up, the yolk tucked in under a starry window.
- rarity feel: epic. The dreamy bedtime room, a prestige goal worth saving for.

### sweet shop
- theme: room-candy
- decor: balloons, string lights, wallArt, rug, bookshelf
- vibe: strawberry milk walls, balloons and lights, everything soft and sugary.
- rarity feel: rare. Playful and bright, a crowd favourite.

### little greenhouse
- theme: room-greenhouse
- decor: plant, plant, window, rug, string lights
- vibe: glassy green light and leaves everywhere, a tiny indoor garden to potter in.
- rarity feel: rare. For the plant lovers, calm and alive.

### rainy afternoon
- theme: room-rainy
- decor: beanbag, floorLamp, rug, string lights, window
- vibe: grey window light, a soft beanbag, warm lamp glow, rain tapping the glass.
- rarity feel: common. The lazy-day comfort room, cozy on a budget.
