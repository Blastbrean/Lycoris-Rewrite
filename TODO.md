# What do we need to do?
- Combat ❌
    - Auto Defense ❌
        - Failure Rate ❌
        - Fake Mistime Rate ❌
        - Fallback To Counter Mantras ❌
        - Fallback To Blocking ❌
        - Blatant Roll ❌
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
- Figure out lag-compensation for other defender types and projectiles.
- Chaser tween to objective + tween to nearest instead
- Ethiron tween to objective
- Figure out later how to match projectiles to users.
- Config data shuffling + encoding
- Create a scale utility which will calculate how far along a hitbox you are with a percentage. Each percentage will have markers which will determine what time we need to parry at.
- Talent Highlighter -> Build Assistance
    - Talent GUI Modification
        - Show all mantras that are missing from the build in red or pink if pre-shrine missing
        - Show all talents that are missing from the build in the same color as above
    - Hand GUI Modification
        - Traits are red if exceeded or none and green if we need to keep going
        - Mantras are red if not in build and green if inside
        - Make it work wherever any type of trait or mantra is shown to you
    - Inventory GUI Modification
        - Change color of attributes to be red if exceeded or none and green if keep going
        - Change color of attributes to the same as above
        - Automatically swap to new stats when we shrine of order
    - Campfire GUI Modification
        - Change color of backgrounds to be red if exceeded or none and green if keep going
    - Make it look good and clean up the visuals
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
- PVP Safety
- Fix FOV

# What moves do we need to add?
https://docs.google.com/spreadsheets/d/1jcZFsSF5iSfbYryL9edl5B_r34tlMo0HPwoFqKiPps4/edit?gid=1386834576#gid=1386834576