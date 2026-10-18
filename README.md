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

Reaching the goal planet in **level 15** displays the Persian ending after
saving the normal level result. The final sentence is emphasized. Use
**Main Menu**, **Level Select**, or **Space** to leave the ending. There is
no nonexistent level 16 to advance to.

Story text is editable in the Inspector through the exported **Story Text**
on `scenes/Levels/story_opening.tscn` and
`scenes/Levels/story_ending.tscn`. Both reuse the project's Persian font.

## Verification

    Godot.exe --headless --fixed-fps 60 --path PATH_TO_PROJECT --script res://tests/test_story_opening.gd
    Godot.exe --headless --fixed-fps 60 --path PATH_TO_PROJECT --script res://tests/test_ending_judge.gd

The ending/judge tests use in-memory save storage, leaving the real save
file untouched. They exercise the real final planet's gravity-well entry,
result recording, repeated-goal protection, story layout and exit controls,
all 15 unlocked choices, and normal progression/completion behavior.
