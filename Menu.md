# Deepwoken Rewrite

```md
# Combat Tab
+ Auto Defense
  - Enable Notifications
  - Enable Visualizations
  - Roll On Parry Cooldown
  - Vent Fallback
  - Deflect Block Fallback
  - Blatant Roll
  - Allow Failure
    - Failure Rate
    - Dash Instead Of Parry Rate
    - Ignore Animation End Rate (react to feint)
  - Auto Defense Filters
    - Filter Out M1s
    - Filter Out Mantras
    - Filter Out Criticals
    - Filter Out Undefined
    - Disable When Textbox Focused
    - Disable When Window Not Active
    - Disable While Holding Block
    - Disable While Using Sightless Beam
    - Disable During Chime Cooldown

+ Combat Assistance
  - Auto Wisp
  - Auto Golden Tongue
  - Delayed Feints
  - Animation Speed Changer
    - Limit To AP Animations
    - Switch Between Speeds
    - Minimum / Maximum
  - Action Rolling
    - Roll On M1
    - Roll On Critical
    - Roll On Cast
    - Roll On Parry
    - Roll Cancel Delay
    - Roll Cooldown

+ Attack Assistance
  - Auto Feint
    - Passive (check before feinting, will attack hit through first)
    - Aggressive (ignore checks, always feint on other move, like Legacy)

+ Timing Probabilities
    - Timing Override List (per timing allow-failure)
        - Failure Rate
        - Dash Instead of Parry Rate
        - Ignore Animation End Rate (react to feint)
    - Timing Override Name

+ Targeting + Whitelisting
  - Player Selection Type
  - Player FOV Limit
  - Distance Limit
  - Max Targets
  - Ignore Players
  - Ignore Mobs
  - Ignore Allies
  - Username Whitelist
  - Player List Whitelisting
```
```md
# Game Tab
1. (caveat) Ragdolls do not get prevented.
2. It will start tweening when you get within 300 studs of an entity. That is the seraching radius.
3. When using this feature, you will experience up to a 10-15 second delay of lag when loading the script.

+ Debugging
  - Show Debug Information (currently hovered part, position, etc)
  - Effect Logging
  - Stop Game Logging

+ Effect Removals
  - No Stun
  - No Speed Debuff
  - No Fall Damage
  - No Acid Water
  - No Wind (see 1.)
  - No Attacking Client Checks (fast swing)
  - Always Allow Jump

+ Player Monitoring
  - Mod Notifications
  - Mod Notification Sound 
  - Void Walker Notifications
  - Player List Spectating
  - Build Stealer
  - Show Hidden Players
  - Show Roblox Chat
  - Show Network Ownership
  - Player Proximity Notifications
    - Player Proximity DIstance
    - Only Allow Voidwalkers
    - Play Beep Sound

+ Local Character
  - Speedhack
  - Noclip
  - Infinite Jump
  - Tween To Back (see 2.)
    - Sticky Attach
    - Ignore Players
    - Distance To Entity (-100 studs - 100 studs)
    - Height Offset (-100 studs - 30 studs)
  - Fly
  - Agility Spoofer
    - Boost Agility Directly (legacy-like)
    - Agility Value 
  - Auto Sprint
    - Sprint On Crouch
    - Sprint Delay
  - Freestyler's Band Spoofer
  - Konga's Clutch Ring Spoofer
  - Max Momentum Spoofer
  - Emote Spoofer
  - Respawn Character
  - Deal Fall Damage to Self
    - Fall Damage Amount

+ Tweening Customization
  - Tween Speed

+ Instance Removals
  - No Echo Modifiers
  - No Kill Bricks
  - No Castle Light Barrier
  - No Yun Shul Barrier
  - No Hive Gate

+ Info Spoofing (see 3.)
  - Spoof Other Players
  - Hide Dealth Information
  - Spoofed Slot String
  - Spoofed Date String
  - Spoofed Game Version
  - Spoofed First Name
  - Spoofed Last Name
  - Spoofed Guild Name
  - Spoofed Server Name
  - Spoofed Server Region
  - Spoofed Server Age
```
```md
# Visuals Tab
1. (caveat) Since switching to our new ESP design, the scaling has ran into issues where you will see randomly huge characters. It will be fixed later.

+ ESP Customization
  - ESP Font Size (4-24)
  - ESP Split Line Length (0-100)
  - ESP Fonts (Roblox Fonts)

+ ESP Optimizations
  - ESP Limit Updates (1-144 FPS)
  - ESP Split Updates (split frames 1f - 64f)
  - No Persistent ESP

+ World Visuals
  - Modify Field Of View
  - Modify Ambience
  - Original Ambience Color

+ Visual Removals
  - No Fog
  - No Blind
  - No Blur
  - No Shadows
  - No Animated Sea

+ Player ESP (see 1.)
  - Enable ESP
  - Show Distance
    - Distance Threshold
  - Show Bounding Box
  - Show Health Bar
  - Show Health Changes
  - Mark Allies
    - Hide Allies On ESP
  - Mark Oath Users
  - Show Dnager Time
  - Show Armor Bar
  - Show Blood Bar
  - Show Sanity Bar
  - Show Tempo Bar
  - Show Posture Bar
  - Player Name Type
    - Character Name
    - Roblox Display Name
    - Roblox Username

+ Mob ESP (see 1.)
  - Enable ESP
  - Show Distance
    - Distance Threshold
  - Show Bounding Box
  - Show Health Bar
  - Show Health Changes
  - Filter Objects

+ Bag ESP
+ NPC ESP
+ Job Board ESP
+ Windrunner Orb ESP
+ Explosive Barrel ESP
+ Owl Feathers ESP
+ Guild Banner ESP
+ Bone Spear ESP
+ Bell Meteor ESP
+ Heal Brick ESP
+ BR Weapon ESP
+ Artifact ESP
+ Whirlpool ESP
+ Ministry Cache ESP
+ Guild Door ESP
+ Armor Brick ESP
+ Rare Obelisk ESP
+ Mantra Obelisk ESP
+ Bell Key ESP
  - Enable ESP
  - Show Distance

+ Chest
  - Enable ESP
  - Show Distance
  - Hide If Opened

+ Obelisk ESP
  - Enable ESP
  - Show Distance
  - Hide If Turned On

+ Area Marker ESP
  - Enable ESP
  - Show Distance
    - Distance Threshold
  - Filter Objects

+ Bone Altar ESP
  - Enable ESP
  - Show Distance
  - Hide If Bone Inside

+ Ingredient ESP
  - Enable ESP
  - Show Distance
    - Distance Threshold
  - Filter Objects

```
```md
# Automation Tab
+ Fish Farm
  - Auto Fish Farm

+ Effect Automation
  - Auto Extinguish Fire

+ Auto Loot
  - Loot All Items
  - Minimum Stars
  - Maximum Stars
  - Item Name List

+ Attribute Farm
  - Auto Charisma Farm
    - Charisma Cap
  - Auto Intelligence Farm
    - Intelligence Cap

# Exploits Tab
1. (caveat) If you are teleporting, it will not notify you if it could not find a door under that name. It will keep trying. If you change the name, it will try looking for it in real-time. 

Also, make sure you press "Stop Teleporting" if you get stuck. These teleports can be buggy. They also make you respawn repeatedly. Do not be in danger.

+ Mob Exploits
  - Void Mobs

+ Local Character Exploits
  - Move While Knocked
  - Pathfind Breaker

+ Teleports (depending on luminant)
  - Eastern Luminant
  - Trial Of One
  - Depths
  - Voidheart
  - Stop Teleporting

+ Guild Door
  - Guild Door Name (see 1.)
  - Teleport To Guild Door

# Settings Tab
+ Cheat Settings
  - Toggle Silent Mode
  - Toggle Player Scanning
  - Toggle Bloxstrap RPC
  - Unload Cheat

+ Generic Linoria Theme Manager
+ Generic Config Manager

+ UI Settings
  - Menu Bind (always/hold/toggle/off)
  - Keybind List (always/hold/toggle/off)
  - Watermark Bind (always/hold/toggle/off)
```