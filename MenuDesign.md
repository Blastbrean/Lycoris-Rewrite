# Menu Design Markers
- ✅ - Finished working on it
- ⚠️ - Done or partially done and working on it, needs rewrite, or has edge cases
    - ⚠️⚠️ - Indicates that it is not tested at all
    - ⚠️⚠️⚠️ - Indicates that it is broken but written
- ❌ - Not doing it right now or not done at all

Tabs have a marker to desiginate whether or not the menu elements are finished.

# Ordered Menu Design
- Combat ✅
    - Combat Targeting ✅
        - Player Selection Type ✅
            - Closest In Distance ✅ 
            - Closest To Crosshair ✅
            - Least Health ✅
        - Player Whitelist ✅
            - Username List ✅
            - Username Input Box ✅
            - Add Username To Whitelist ✅
            - Remove Selected Username ✅
        - FOV Limit ✅
        - Distance Limit ✅
        - Ignore Mobs ✅
        - Ignore Friends ✅
        - Max Targets ✅
    - Auto Defense ✅
        - Enable Auto Defense ❌
        - Auto Defense Configuration ❌
        - Auto Defense Notifications ❌
        - Auto Defense Visualizations ❌
    - Feint Detection ✅
        - Detect M1 Feints ❌
        - Detect Mantra Feints ❌
        - React To Feints ❌
            - Feint Reaction Type ❌
                - Dodge ❌
                - Parry ❌
            - Feint Reaction Chance ❌
    - Attack Assistance ✅
        - Feint M1 While Defending ❌
        - Feint Mantras While Defending ❌
        - Block Punishable M1s ❌
        - Block Punishable Criticals❌
        - Block Punishable Mantras ❌
    - Combat Assistance ✅
        - Silent Aim ❌
        - Allow Flourish Feints ❌
        - Allow Attacks While Rolling ❌
        - Attack Animation Speed ❌
            - Animation Speed Slider (0.5x - 1x - 2x) ❌ 
            - Side note: Current animation speed is multiplied instead of being incremental. Solves any pausing and is more consistent.
        - Maximum Momentum ❌
        - Perfect Mantra Cast ❌

    Use Counter Mantras When Avaliable

    Account for Hyperarmor in Auto Defense

    Hold Block For Auto Defense

- Builder ✅
    - Save Manager ✅
        - Config Name ✅
        - Config List ✅
        - Create Config & Load Config ✅
        - Overwrite Config ✅
        - Refresh Config List ✅
        - Set To Auto Load ✅
    - Merge Manager ✅
        - Config List ✅
        - Merge Config Type
            - Add New Timings ✅
            - Overwrite Timings ✅
        - Merge With Current Config ✅
    - Logger ✅
        - Show Logger ✅
        - Show Animation Visualizer ❌
        - Animation Visualizer ID ❌
    - Animation ✅
        - Timing List ✅
        - Timing Name ✅
        - Timing Tag ✅
            - Undefined ✅
            - Critical ✅
            - Mantra ✅
            - M1 ✅
        - Hitbox Length ✅
        - Hitbox Width ✅
        - Hitbox Height ✅
        - Delay Until In Hitbox ✅
        - Animation ID ✅
        - Repeat Parry Until Animation End ✅
            - Repeat Parry Delay ✅
        - No Repeat Parry Until Animation End ✅
            - Animation Actions ✅
            - Animation Action Name ✅
            - Animation Action Delay ✅
            - Animation Action Type ✅
                - Parry ✅
                - Dodge ✅
                - Start Block ✅
                - End Block ✅
            - Add Action To List ✅
            - Remove Action From List ✅
        - Write Timing To List ✅
        - Remove Selected Timing ✅
    - Part ✅
        - Timing List ✅
        - Timing Name ✅
        - Timing Tag ✅
            - Undefined ✅
            - Critical ✅
            - Mantra ✅
            - M1 ✅
        - Hitbox Length ✅
        - Hitbox Width ✅
        - Hitbox Height ✅
        - Delay Until In Hitbox ✅
        - No Delay Until In Hitbox ✅
            - Timing Delay ✅
        - Part Name ✅
        - Part Content Filter ✅
        - Part Content Name ✅
        - Add Name To Filter ✅
        - Remove Selected From Filter ✅
        - Initial Minimum Distance ✅
        - Initial Maximum Distance ✅
        - Part Actions ✅
        - Part Action Name ✅
        - Part Action Delay ✅
        - Part Action Type ✅
            - Parry ✅
            - Dodge ✅
            - Start Block ✅
            - End Block ✅
        - Add Action To List ✅
        - Remove Action From List ✅
        - Write Timing To List ✅
        - Remove Selected Timing ✅
    - Sound ✅
        - Timing List ✅
        - Timing Name ✅
        - Timing Tag ✅
            - Undefined ✅
            - Critical ✅
            - Mantra ✅
            - M1 ✅
        - Hitbox Length ✅
        - Hitbox Width ✅
        - Hitbox Height ✅
        - Delay Until In Hitbox ✅
        - Sound ID ✅
        - Repeat Parry Until Sound End ✅
            - Repeat Parry Delay ✅
        - No Repeat Parry Until Sound End ✅
            - Sound Actions ✅
            - Sound Action Name ✅
            - Sound Action Delay ✅
            - Sound Action Type ✅
                - Parry ✅
                - Dodge ✅
                - Start Block ✅
                - End Block ✅
            - Add Action To List ✅
            - Remove Action From List ✅
        - Write Timing To List ✅
        - Remove Selected Timing ✅
    - Effect ✅
        - Timing List ✅
        - Timing Name ✅
        - Timing Tag ✅
            - Undefined ✅
            - Critical ✅
            - Mantra ✅
            - M1 ✅
        - Hitbox Length ✅
        - Hitbox Width ✅
        - Hitbox Height ✅
        - Delay Until In Hitbox ✅
        - Effect Name ✅
        - Repeat Parry Until Effect End ✅
            - Repeat Parry Delay ✅
        - No Repeat Parry Until Effect End ✅
            - Effect Actions ✅
            - Effect Action Name ✅
            - Effect Action Delay ✅
            - Effect Action Type ✅
                - Parry ✅
                - Dodge ✅
                - Start Block ✅
                - End Block ✅
            - Add Action To List ✅
            - Remove Action From List ✅
        - Write Timing To List ✅
        - Remove Selected Timing ✅

- Game ✅
    - Local Character ✅
        - Fly ✅
            - Fly Speed ✅
        - No Clip ✅ 
            - Allow Collisions While Knocked ✅
        - Speedhack ✅
            - Speedhack Speed ✅
        - Infinite Jump ✅
            - Infinite Jump Speed ✅
        - Auto Sprint ✅
        - Agility Spoofer ✅
            - Agility Value ✅
        - Tween To Objective ✅
        - Attach To Back ✅
            - Height Offset ✅
            - Back Offset ✅
        - Freestylers Band Spoofer ✅
        - Konga's Clutch Ring Spoofer ✅
            - Side note: Add these into a inventory spoofer option.
        - Emote Spoofer ✅ 
        - Remove "Loot All" CD ❌
    - Effect Removals ✅
        - No Speed Debuff ✅
        - No Stun ✅
        - No Acid Damage ✅
        - No Fall Damage ✅
        - No Wind ✅
        - No Jump Cooldown ✅
    - Instance Removals ✅
        - Remove Kill Bricks ✅
        - Remove Echo Modifiers ✅
    - Player Monitoring ✅
        - Player List Spectating ✅
        - Player Proximity Notifications ✅
            - Proximity Distance (50m - 350m - 1000m) ✅
            - Only Allow Voidwalkers ✅
        - Void Walker Contract Notifications ✅
        - Legendary Weapon Notifications ✅
        - Mod Notifications ✅
        - Show Roblox Chat ✅
        - Show All Players in Map ❌
        - Chat Spy ❌
    
    Check out "Hide From Heartbeat Sensor"

    Check out "Reveal Mystery Mantras"

    Check out "Hide Shadowcast Visual"

    Check out "Hide HP Bar Block"

    Check out "Hide Void Spire Visual"

    Check out "Remove Castle Light Gate"

- Visuals ✅
    - ESP Customization ✅
        - Text Font Size ✅
        - Text Font Selection ✅
    - ESP Optimizations ✅
        - Object Split Updates ✅
            - Update Frames ✅
        - Object Check Delay ✅
            - Ignore Humanoids ✅
            - Delay Time ✅
    - World Visuals ✅
        - Modify Field Of View ✅
            - FOV Slider ✅
        - Modify Ambience ✅
            - Use Original Ambience Color ✅
            - Ambience Brightness ✅
    - Visual Removals ✅
        - No Blind ✅
        - No Fog ✅
        - No Blur ✅
        - No Shadows ✅
    - Other ESP Groupboxes ✅
    - Player ESP Groupbox ✅
        - Ally ESP ✅
            - Ally ESP Color ✅
    - Bag ESP Groupbox ✅
    - Ingredient ESP Groupbox ✅
        - Filter Ingredients ✅
            - Filter Ingredients List ✅
            - Filter List Type ✅
                - Hide Other Names ✅
                - Hide Names ✅
            - Filter Ingredient Name ✅
            - Add Ingredient To Filter ✅
            - Remove Selected Ingredient ✅
    - Area Marker ESP Groupbox ✅
        - Filter Area Marker ✅
            - Filter Area Marker List ✅
            - Filter Area Marker Name ✅
            - Filter List Type ✅
                - Hide Other Names ✅
                - Hide Names ✅
            - Add Area Marker To Filter ✅
            - Remove Selected Area Marker ✅

    Remove Opened Chests from Chest ESP

    Check out "Danger Timer ESP"

- Automation ✅
    - Maestro Farm ⚠️⚠️ (auto-eat and optimize route)
        - Use Critical ✅
        - Webhook Link ✅
        - Auto Sell ❌
            - Inventory Threshold (10% - 100%) ❌
            - Sell to Guild Base Antiquarian ❌
            - Side Note: As a default, it should tween below the antiquarian near the training area.
    - Fish Farm ⚠️⚠️⚠️ (rework fish farm)
        - Hold Time ✅
        - Kill Caught Mudskippers ✅
        - Webhook Notification ✅
            - Webhook Link ✅
    - Attribute Farm ✅
        - Auto Charisma Farm ✅
            - Charsima Cap ✅
        - Auto Intelligence Farm ✅
            - Intelligence Cap ✅
    - Effect Automation ✅
        - Auto Extinguish Fire ✅

    Add Auto Loot and Account for Innate Stats

- Exploit ✅
    - Mob Exploits ✅
        - Void Mobs ✅
        - Pathfind Breaker ✅
            - Bring Mobs ✅
            - Real Body Visible ✅
            - Real Body Chams Color ✅
    - Local Character Exploits ✅
        - Move While Knocked ✅

    Check out "Extended Item Pickup"
    - Side Note: We can do this with "firetouchdetector" and find "ItemPickup" tags for quick item searching

- Lycoris ✅
    - Cheat Settings ✅
        - Unload Cheat ✅
    - UI Settings ✅
        - Menu Bind ✅
        - Keybind List Bind ✅
    - Theme Manager ✅
    - Save Manager ✅

There are way more features from the old script that are left out.

This is what we have to do right now.
