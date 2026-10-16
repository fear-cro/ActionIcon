ActionIcon 0.1.1
================

ActionIcon is a stripped-down WoW Forever beta spell test environment derived
from ActionLITE's main and mini icon concept. It contains no rotations, class
configuration pages, glow engine, or debug subsystem.

INSTALL
-------
1. Exit World of Warcraft.
2. Copy the ActionIcon folder into Interface\AddOns\.
3. Start the WoW Forever beta and enable ActionIcon at the character screen.

OPENING THE TEST WINDOW
-----------------------
- Use /actionicon or /ai.
- You can also right-click the movable main icon.
- The window does not open automatically when the addon loads.

TEST MACRO
----------
ActionIcon creates one character-specific macro named ActionIconTest. Open
/macro and drag that macro to an action bar. The Create / Update Macro button
can recreate it if the character macro list was full when the addon loaded.

When you select a castable spell outside combat, ActionIcon updates that one
macro to this form:

    #showtooltip Spell Name
    /cast Spell Name
    /run ActionIcon_MacroSuccess()

The callback is intentionally the only success signal. It does not inspect the
combat log. Clicking the macro within two seconds records SUCCESSFUL and prints
"a spell was successfully cast" in chat. If it is not clicked in two seconds,
the newest result becomes UNSUCCESSFUL. Clicking the catalog entry again starts
a fresh test, and its newest result replaces the earlier result.

WoW protects macro changes during combat. Select/configure a spell before
entering combat. The already-configured macro can then be used in combat, but a
different spell cannot replace it until combat ends.

Universal entries are ActionLITE texture FileDataIDs rather than spells. Their
macro is callback-only, so they test icon display and the return path without a
/cast line.

TABS
----
- Universal Icons: the 10 Universal(x) textures from ActionLITE, three columns.
- Racial Icons: two active racials per Forever race, grouped alphabetically in
  two columns.
- Class Icons: Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock,
  and Warrior subtabs, alphabetized and displayed in three columns.
- CustomID Icons: enter a client spell ID, resolve its name/icon, and test it.
  Clear Results clears only CustomID attempts from the current session.
- Report: Show Results lists every static catalog entry as SUCCESSFUL,
  UNSUCCESSFUL, or UNTESTED, plus custom IDs attempted in this session. The
  report is automatically selected for copying.

STATUS COLORS
-------------
- Blue: UNTESTED
- Gold: waiting for the macro return
- Green: SUCCESSFUL
- Red: UNSUCCESSFUL

SESSION AND MEMORY BEHAVIOR
---------------------------
Only the newest result for each spell/icon key is stored. Test results are
session-only and reset on logout or /reload. The addon recycles one pool of
catalog buttons for the visible tab instead of constructing frames for all 582
catalog rows at once. ActionIconDB stores only display/menu preferences.

DATA SOURCES
------------
Originally captured 2026-10-15 and updated 2026-10-16 from:
- https://www.wowhead.com/forever/spells/racial-traits
- https://www.wowhead.com/forever/spells/abilities

The class catalog was crawled through the class-specific Forever ability pages
with Passive Spell = No. Removed records, rows named "Engrave ...", and active
racials already present in the Racial Icons tab were excluded. Rank rows with
the same spell name and icon were collapsed to the lowest rank. A rank was kept
when its icon changed, including Mage conjured food/water variants.

Version 0.1.1 adds Mage Frost Blast and Paladin Revoke, and updates the renamed
Paladin entries Salvation and Mass Salvation without duplicating their IDs.

COMMANDS
--------
/actionicon or /ai       Open/close the test window
/ai macro                Create/update ActionIconTest
/ai reset                Reset the main icon and menu positions
