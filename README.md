<img src="assets/AppIcon.png" width="128" alt="Pathways Into Mischief icon">

# Pathways Into Mischief

A native macOS save editor for **Pathways Into Darkness**, inspired by Alain Roy’s classic **Pathways Into Cheating**.

**Experimental beta — 0.7.0-beta.1.** Developed against the Mac App Store port, version 2.2. Keep an independent copy of any save you care about. Some deliberately unusual combinations can trigger errors in the game.

## Download and install

Download the macOS application ZIP from this repository’s **Releases** section. Unzip it and move **Pathways Into Mischief.app** into Applications, or another folder of your choice.

The supplied beta is locally ad-hoc signed. It is **not Developer ID signed or Apple notarized**. macOS may block the first launch. Follow [Apple’s guidance for opening apps from an unidentified developer](https://support.apple.com/en-us/102445) only if you trust the download. Do not disable Gatekeeper system-wide.

Requirements: macOS 11.5 or later. The application is a Universal binary for Apple Silicon and Intel. The game must be installed separately. Testing so far covers the modern port on Apple Silicon; automated backend tests also pass under Rosetta. Native Intel GUI testing is still welcome.

## What it does

- Edit current and maximum health, including a 1,000-health preset.
- Inspect nested bags, boxes, weapons and magazines.
- Select items by category, tick a checkbox for one copy, or choose/type a total quantity.
- Add all six crystal colours, weapons with large ammunition reserves, or potion bundles.
- Remove a container while preserving its contents.
- Change seven weapon proficiencies, or set all to Expert.
- Set the game clock, reset it, or rewind by one or 24 hours.
- Choose a floor and click a tile to prepare a teleport destination.
- Remember the last file and preserve original and intermediate backups.

## Open the real save

Quit the game before saving or restoring edits. In the editor’s Open dialog, press **Command–Shift–G** and paste:

```text
~/Library/Containers/com.manuptimestudios.pathwaysintodarkness/Data/Library/Application Support/Pathways Into Darkness/
```

Choose **Saved Games.pathways**. If macOS requests folder access when saving, select the containing **Pathways Into Darkness** folder and click **Allow this folder**.

The renamed English app uses separate preferences from the French prototypes. When upgrading, select your save again and keep earlier backup files; the new app records its own original-backup baseline.

Select a saved-game slot, make changes, click **Apply** in the relevant panel, then **Save** in the main window. Launch the game and load that slot to try the changes. The editor never edits the game executable.

### Quantities and ammunition

An item quantity is the **total number of copies wanted**, not the number to add. The inventory format has 256 slots in total. Magazines occupy slots too. A magazine’s ammunition is edited separately, up to 32,767 rounds in the editor; acceptance of extreme values by the game is not guaranteed.

The six-crystal button fills in missing colours without reducing existing stocks. Newly created containers are empty. The arsenal bundle fills matching magazines and loads empty weapons. The Colt remains experimental: using it with supplied ammunition has triggered a historical error message. A functional M16 is not fabricated from the broken M16 object.

Equipped items must be unequipped in the game before removal. Removing the inventory root is not supported yet.

### Saving and restoring

**Save edits the file you opened**, even if that file is a Desktop copy rather than the game’s live file. Before replacement, its previous version is renamed alongside it. The editor checks whether another application changed the file since it was opened and refuses to overwrite that newer state.

**Restore original** restores the version preserved before this editor’s first save for that file path. The version being replaced during restoration is preserved too. **Export** writes an edited copy under another name. Backups and file-location bookmarks are stored locally; do not delete a backup that you may need later.

### Clock and teleport limits

Rewinding the clock does not reschedule every independent game timer or scripted event. Teleporting does not complete prerequisites or solve quests. The map is a sector overview, not a full depiction of dynamic objects. Ordinary floor and save-rune tiles are selectable; walls, pillars, doors and level transitions are not.

The 25 maps are read at runtime from the separately installed game. None are included in this download.

## Build and test

Install Apple’s Xcode Command Line Tools, then run:

```sh
./build.sh
./build/Pathways\ Into\ Mischief.app/Contents/MacOS/PathwaysIntoMischief --self-test
```

The tests generate synthetic records; no personal saves or game files are required. They cover inventory links, all item categories, 200 duplicate crystals, exact quantities, capacity rejection, container removal, bundles, proficiency bounds, clock conversion, teleport coordinates, backup/restore, and external-change detection.

To inspect a local save without modifying it:

```sh
./build/Pathways\ Into\ Mischief.app/Contents/MacOS/PathwaysIntoMischief --inspect "/path/to/Saved Games.pathways"
```

The build script produces a Universal application and release ZIP. A Developer ID identity can optionally be supplied through `PIM_SIGN_IDENTITY`; notarization is a separate publisher step.

## Credits and licence

In tribute to **Alain Roy’s Pathways Into Cheating**. This is an independently implemented modern companion, not an official update of that program.

See [CREDITS.md](CREDITS.md) for historical format references. Code, documentation and the original icon are distributed under the [MIT licence](LICENSE). No original game code, maps, resources, or personal saves are bundled. Game names and other third-party material remain associated with their respective owners.

Created with assistance from OpenAI Codex; the icon was generated using OpenAI image generation. Not affiliated with or endorsed by Bungie or the developers of the macOS port.
