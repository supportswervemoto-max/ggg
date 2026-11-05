# Start Your Own Clothing Company — V4

You play as a 16-year-old founder building an online fashion company from a small warehouse. The clothing labels are original fictional brands—Crest & Row, Northline Polo, and Atelier 16—so the game has a premium designer style without copying real trademarks.

## Open the game

1. Extract `StartYourOwnClothingCompany-V4.zip`.
2. In Roblox Studio choose **File → Open from File**.
3. Select `StartYourOwnClothingCompany-V4.rbxlx`, then press **Play**.
4. Use the computer beside your spawn or click the COMPUTER button.

Do not open an older AI Bot V2/V3 place. V4 is a separate game concept and file.

## Tutorial and first day

You start with $500 in fictional company cash.

1. At the computer, click **Create website**. The server waits 15 real seconds before unlocking the next step.
2. Click **BUILD** and purchase the $100 clothing sorting desk. The desk and folded clothing physically appear in the warehouse.
3. Click **HIRE** and employ a $75 clothing sorter. A worker holding a package appears.
4. Return to the computer and purchase the $100 local social ad. Day 1 begins automatically.
5. Sales arrive every three seconds. After 60 seconds, a **DAY 1 COMPLETED** report shows revenue, wages, profit, cash, and total company value.
6. Start the next day, expand the warehouse, hire more roles, and buy stronger advertising until company cash or company value reaches $1,000,000.

The top-right card always shows `[Username]'s Company` and the live company balance. The second card shows the current day, remaining time, and current-day sales.

## Progression

- Builds: sorting desk, packing station, designer clothing racks, product photo studio, luxury showroom.
- Jobs: clothing sorter, order packer, product photographer, warehouse manager.
- Advertising: local social post, influencer package, city campaign, national campaign, global fashion campaign.
- Employees increase throughput but charge wages at the end of each day.
- Builds increase order capacity. Ads permanently multiply store traffic. Every new day adds modest brand growth.
- The UI and server reject locked items, insufficient cash, repeat builds, out-of-order ads, remote purchases before the tutorial, and actions outside their required location.

## Controls

- E / touch prompt: use the warehouse computer.
- B: Build menu.
- H: Hire menu.
- C: Computer menu.
- Escape: close a menu.
- All actions also have large on-screen buttons for mobile.

## Validation and limitations

The package is checked for script syntax, XML/source parity, correct Roblox Block/Ball/Material enum values, flat anchored ground, ZIP integrity, and the complete server tutorial/economy sequence in an offline Roblox-service test double. That test covers the 15-second website timer, build/hire/ad gating, day sales, wages, day completion, unlocks, duplicate rejection, company naming, and player plot isolation.

Roblox Studio is unavailable in the build environment. Visual layout, Roblox runtime compatibility, mobile scaling, multiplayer replication and camera behavior still require a real Studio Play test. Progress resets when the server closes; DataStore saving is not included in this first version. The business is a simulation and all prices are in-game cash, not Robux or real money.

The included `Install-ClothingCompany-V4.luau` can replace the named old prototype objects through Studio's Command Bar in Edit mode, but opening the supplied V4 place is recommended.
