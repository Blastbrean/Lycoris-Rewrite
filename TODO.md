# What do we need to do?
- Combat ❌
    - Auto Defense ❌
        - Failure Rate ❌
        - Fake Mistime Rate ❌
        - Fallback To Counter Mantras ❌
        - Fallback To Blocking ❌
    - Feint Detection ❌
        - Detect M1 Feints ❌
        - Detect Mantra Feints ❌
        - React To Feints ❌
            - Feint Reaction Type ❌
                - Dodge ❌
                - Parry ❌
            - Feint Reaction Chance ❌
    - Combat Assistance ❌
        - Silent Aim ❌
        - Allow Flourish Feints ❌
        - Allow Attacks While Rolling ❌
        - Attack Animation Speed ❌
            - Animation Speed Slider (0.5x - 1x - 2x) ❌ 

- Game ❌
    - Local Character ❌
        - Always Sprint ❌
        - Remove "Loot All" CD ❌
    - Player Monitoring ❌
        - Show All Players in Map ❌
        - Chat Spy ❌
    
    Check out "Hide From Heartbeat Sensor"

    Check out "Reveal Mystery Mantras"

    Check out "Hide Shadowcast Visual"

    Check out "Hide HP Bar Block"

    Check out "Hide Void Spire Visual"

- Visuals ❌
    - Remove Opened Chests from Chest ESP ❌
    - Dropped Bone ESP ❌
    - Bone Altar ESP ❌
        - Don't Show If There Is A Bone ❌

- Automation ❌
    - Maestro Farm ❌
    - Fish Farm ❌

    Add Auto Loot and Account for Innate Stats

- Exploit ❌
    - Mob Exploits ❌
        - Pathfind Breaker ❌
    - Local Character Exploits ❌
        - Extended Item Pickup ❌
        - Extended Job Board Interact ❌

- How should we load internal timings?
- What are the bugs related to the internal builder?
- Work on all the ---@todo comments.
- Figure out lag-compensation for PartDefenders.
- Chaser tween to objective + tween to nearest instead
- Ethiron tween to objective
- Figure out later how to match projectiles to users.
- Config data shuffling + encoding
- Create a scale utility which will calculate how far along a hitbox you are with a percentage. Each percentage will have markers which will determine what time we need to parry at.
- Talent Highlighter -> Build Assistance
    - For traits: red if exceeded or none, green if keep going
    - For mantras: red if not in build, green if in
    - For attributes: red if exceeded or none, green if keep going + shrine of order detection
    - Clean up talent visual
    - Have it work across all types of places that use talent cards
- Finish "Auto Fish"
    - Auto Eat
    - Get Food At Guildbase
    - Server Hop If Players Nearby
    - Webhook Notification
    - Incorporate Auto Loot
- Finish "Auto Loot"
    - Easy to use filters
    - Loot all option
    - Easy to be built into other modules
- Finish "Extra Keybinds"
    - Keybind builder to partial item search find
- Finish "Echo Farm"
- Auto Ragdoll Recover
- Hitbox Visualizer
- Chaser Multi Player Support
- Hide Obelisks That Are Already Turned On
- Bone Altar ESP + Hide Altars With Bones
- PVP Safety
- Fix FOV
- Fix Username Check + Add Ignore Players
- Depths Cathedral TP

# What moves do we need to add?
https://docs.google.com/spreadsheets/d/1jcZFsSF5iSfbYryL9edl5B_r34tlMo0HPwoFqKiPps4/edit?gid=1386834576#gid=1386834576