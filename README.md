# HollowGardoon / Void

## Game jam judges

On the main menu, choose **Game Jam Judges — Unlock All 15 Levels**.
This opens level select with every level available, so judges can review any
part of the game without completing earlier levels. A **GAME JAM JUDGE MODE**
banner identifies this shortcut on the level-select screen.

The shortcut does not award stars or currency or mark levels completed.
Actual play still records results normally. Choose **Start** on the main
menu to return to normal progression. Judge access is session-only and is
not stored in the save file.

## Story

Level 1 starts with the Persian opening. Press **Space** to move into play.
The opening appears once per application session, so deaths and retries
return directly to gameplay.

In **level 15**, crossing the invisible line beyond the last regular planets
starts the final automatic flight. The rocket travels through a gradual
vignette fade into a black void toward the distant flag planet. Keyboard,
mouse, touch and pause controls are blocked during this voyage; hazards and
wormholes cannot interrupt it. The rocket and final planet retain a faint glow.

Reaching the flag planet holds an arrival shot, then displays the current
Persian ending after saving the normal level result. Use
**Main Menu**, **Level Select**, or **Space** to leave the ending. There is
no nonexistent level 16 to advance to.

The default flight lasts **18 seconds**, fades to full black in **6 seconds**,
and holds the arrival for **1.4 seconds**. In level 15, move **FinalFlight** to
change the invisible trigger (currently x = 7400), or edit its **Flight
Duration**, **Darken Duration** and **Arrival Hold** in the Inspector. The
flag planet is **goal planet/Planet8**, now at (17500, 432). Keep the fade
shorter than the flight so the void becomes fully black before arrival.
Only this final planet's position was moved; the other level objects retain
their authored placements.

Story text is editable in the Inspector through the exported **Story Text**
on `scenes/Levels/story_opening.tscn` and
`scenes/Levels/story_ending.tscn`. Both reuse the project's Persian font.

## Verification

    Godot.exe --headless --fixed-fps 60 --path PATH_TO_PROJECT --script res://tests/test_story_opening.gd
    Godot.exe --headless --fixed-fps 60 --path PATH_TO_PROJECT --script res://tests/test_ending_judge.gd
    Godot.exe --headless --fixed-fps 60 --path PATH_TO_PROJECT --script res://tests/test_final_flight.gd

The ending/judge tests use in-memory save storage, leaving the real save
file untouched. They exercise the real final planet's gravity-well entry,
result recording, repeated-goal protection, story layout and exit controls,
all 15 unlocked choices, and normal progression/completion behavior.
The final-flight test also checks fast trigger crossings, keyboard/mouse/touch
lockout, gradual and complete darkness, safe movement, real goal-area arrival,
the arrival hold, held-input handling, reload cleanup and unaffected levels.
