# Level 1 story opening

Run level 1 normally, either from level select or with F6. Read the Persian
opening and press **Space** to pan into the existing level. Gameplay is held
at its original starting state throughout the opening and camera movement.
If Space is held, release it to begin play; the opening press cannot charge
or launch the rocket. The existing music continues.

The opening plays once per application session. Deaths, Repeat and later
visits to level 1 start gameplay immediately. A fresh game process shows the
opening again. No save-game fields were added or changed.

The only addition to level_1.tscn is an instance of
`scenes/Levels/story_opening.tscn`. Its existing nodes, geometry, tutorials,
camera settings and gameplay scripts are unchanged. The new scene sits at
x = -1152, outside the playable level, and removes itself after the handoff.

To edit the text, select **StoryOpening** in level 1 and edit **Story Text**
in the Inspector. It supports RichTextLabel BBCode; `[b]...[/b]` emphasizes
the final sentence. **Pan Duration** controls the movement time, and
**Play Once Per Session** controls whether retries repeat the opening.
The existing Persian font is reused with explicit Persian/RTL shaping.

Validation:

    Godot.exe --headless --fixed-fps 60 --path PATH_TO_PROJECT --script res://tests/test_story_opening.gd

The 31 checks cover the frozen starting state, Persian text, layout, blocked
input, actual camera movement, held/released Space, original camera/HUD
restoration, resumed physics, pause/resume, retry and an unchanged level 2
startup. A byte comparison also verified that removing the two new scene
declarations restores the original level 1 file exactly.

The project already references missing SpaceShip2.png, SpaceShip3.png and
SpaceShip4.png files in the rocket scene. Those references are unchanged.
