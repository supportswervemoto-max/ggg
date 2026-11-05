# Start Your Own AI Bot — V3 / The Neighborhood Update

## Open this version
1. Download and extract **StartYourOwnAIBot-V3.zip**.
2. In Roblox Studio select **File → Open from File → StartYourOwnAIBot-V3.rbxlx**.
3. Press **Play**. Do not open the old V2 file.
4. The introduction has Next and Skip story buttons. Afterward, follow the mint guide into the warehouse, interact at the workbench, buy the $10 course and invest $10 to launch your bot.

No plugins, npm, imported model assets, external HTTP access or API keys are required. All prices are fictional in-game cash, not Robux or real payments.

## Important fix for the floating map
V2's XML exporter incorrectly mapped Block to 0 and Ball to 1. Roblox defines Ball=0, Block=1, Cylinder=2. This converted structural floors into ellipsoids. V3 corrects the export and independently compares every part shape and material against a saved snapshot of Roblox's public API enum definitions. The main land is now a 640 × 600 stud anchored, collidable BLOCK, 16 studs deep, with its flat top at Y=0. A safe spawn is included. V2 has not been silently overwritten.

## The map
- A complete starter-house exterior surrounding the furnished story bedroom.
- A warehouse with brick/concrete walls, industrial windows, trusses, work lights, a tool wall, rug, desk, laptop, crates and plants.
- A residential neighborhood: four additional houses with pitched roofs, chimneys, windows, porches, paths, gardens and mailboxes.
- Connected streets with sidewalks, kerbs, zebra crossings, road markings, signs, streetlamps and a bus shelter.
- Accessible shops: Byte & Brew café, Circuit computer store, and Foundry hardware shop. Counters, seating, displays, shelving and patio furniture are modeled.
- Signal Park: fountain, benches, paths, pond, footbridge and planting.
- Midrise offices/library buildings with window grids, cornices and rooftop ventilation.
- A loading yard with three depot bays, pallets, freight, tanks, a forklift and service-road access.
- Surrounding trees, rooted hills and rocks keep the playable area from looking like objects suspended in the sky.

The map is intentionally stylized and made from original procedural geometry, not purchased meshes. Most background buildings are scenery; only the shops and starter house/warehouse have relevant interior areas.

## New exploration gameplay
Once your first bot is earning money, press **M** or use **Neighborhood map**. Select a district to set a walking waypoint. The client asks Roblox PathfindingService for a route around buildings; actual route quality requires Studio testing.

Find three research notebooks in the café, computer shop and park. Each grants $35 once per session. Their rewards and proximity checks are server-owned. The notebook disappears after collection on your own plot.

## Bot progression
- Starting money: $25. Course: $10. Training starts at $10 and increases by $8 per existing level.
- Base capacity: 3 levels. Base income: $3 per bot level every 4 seconds.
- Dual displays: $75, capacity +4 and earnings +25%.
- Server rack: $200, capacity +6 and earnings ×2.
- Studio lounge: $125, earnings +50%.
- Upgrade purchases physically reveal the appropriate models.

Close the laptop with its close/leave button, or Space. Interact using E on keyboard or the on-screen proximity prompt on touch devices. Cutscenes can be advanced or skipped. The dashboard scrolls on small screens.

## Validation and limitations
Verified locally: Lua-compatible syntax; XML structure/source parity; shape/material IDs against Roblox API definitions; flat collidable ground; clear initial walking corridor; actual server source run in an offline Roblox-service test double for story/tutorial progression, spending, training, income, upgrade visibility, three single-use research rewards, proximity rejection, duplicate-purchase rejection, plot isolation and cleanup; ZIP integrity.

The geometry previews are Blender renders of the EXPORTED XML shapes, not Roblox Studio screenshots. They show geometry/layout and can catch export errors; they do not reproduce Roblox lighting, SurfaceGui text, UI, animations or runtime asset behavior.

Roblox Studio is unavailable here. Opening, visual inspection and gameplay/camera/pathfinding/multiplayer/touch behavior still require a real Studio playtest. The bot is a tycoon simulation, not a live chatbot. Progress resets on rejoining; DataStore saving, audio/voice acting and production character animation are not included.

## Optional installer
The included `Install-AIBot-V3.luau` recreates this version in Studio Edit mode through the Command Bar. It replaces only the named AI Bot prototype objects, including the old V2 scripts. Opening the provided place file is recommended to avoid old geometry or unrelated scripts conflicting with the new map.

## Source
The GitHub `roblox-v3` folder contains the source scene builder, city geometry, scripts and validation harness. V2 downloads remain available for history; use V3 for the fixed map.
