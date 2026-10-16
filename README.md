# ActionIcon

ActionIcon is a lightweight spell-icon and macro-return test environment for the World of Warcraft: Forever beta.

Current version: **0.1.1**

## Features

- Movable and scalable main spell icon with a persistent mini icon
- Universal, Racial, Class, CustomID, and Report tabs
- 582 static catalog entries across nine playable classes, active racials, and ActionLITE universal textures
- Two-second macro-return test window with green success and red failure states
- Latest-result-only session reporting with automatic text selection
- No rotations, class configuration panels, glow engine, or debug subsystem

## Installation

1. Exit World of Warcraft.
2. Place the repository folder at `World of Warcraft\_forever_beta_\Interface\AddOns\ActionIcon`.
3. Confirm that `ActionIcon.toc` is directly inside that folder.
4. Start the Forever beta and enable ActionIcon at the character-selection screen.

## Usage

Open ActionIcon with `/actionicon` or `/ai`. You can also right-click the movable main icon.

ActionIcon creates one character-specific macro named `ActionIconTest`. Open `/macro` and drag it to an action bar. Selecting a castable catalog spell outside combat updates the macro to cast that spell and return a test signal to the addon.

Clicking the configured macro within two seconds records `SUCCESSFUL`. If no callback is received within two seconds, the newest result becomes `UNSUCCESSFUL`. Retesting a spell replaces its previous result.

> WoW protects macro changes during combat. Select and configure the spell before entering combat. A successful result means the generated macro returned its callback; ActionIcon intentionally does not use combat-log validation.

## Commands

- `/actionicon` or `/ai` — open or close the test window
- `/ai macro` — create or update `ActionIconTest`
- `/ai reset` — reset the main-icon and menu positions

## Version 0.1.1

- Added Mage **Frost Blast** (`1326053`)
- Added Paladin **Revoke** (`1325499`)
- Renamed Paladin **Blessing of Salvation** to **Salvation** (`1038`)
- Renamed Paladin **Greater Blessing of Salvation** to **Mass Salvation** (`25895`)

Spell records were verified against the WoW Forever database for patch 1.60.1.
