-- GameTab module.
local GameTab = {}

---@module Features.Game.Bestiary
local Bestiary = require("Features/Game/Bestiary")

-- Services.
local players = game:GetService("Players")

---Initialize local character section.
---@param groupbox table
function GameTab.initLocalCharacterSection(groupbox)
	local speedHackToggle = groupbox:AddToggle("Speedhack", {
		Text = "Speedhack",
		Tooltip = "Modify your character's velocity while moving.",
		Default = false,
	})

	speedHackToggle:AddKeyPicker("SpeedhackKeybind", { Default = "N/A", SyncToggleState = true, Text = "Speedhack" })

	local speedDepBox = groupbox:AddDependencyBox()

	speedDepBox:AddSlider("SpeedhackSpeed", {
		Text = "Speedhack Speed",
		Default = 200,
		Min = 0,
		Max = 300,
		Suffix = "/s",
		Rounding = 0,
	})

	local flyToggle = groupbox:AddToggle("Fly", {
		Text = "Fly",
		Tooltip = "Set your character's velocity while moving to imitate flying.",
		Default = false,
	})

	flyToggle:AddKeyPicker("FlyKeybind", { Default = "N/A", SyncToggleState = true, Text = "Fly" })

	local flyDepBox = groupbox:AddDependencyBox()

	---@see updateAAGunBypass function in Movement.lua
	--[[
	flyDepBox:AddToggle("AAGunBypass", {
		Text = "Anti Air Gun Bypass",
		Tooltip = "This feature does not work with the 'Brick Wall' talent. It abuses the fact that being knocked disables AA-Gun.",
		Default = false,
	})
	]]
	--

	flyDepBox:AddSlider("FlySpeed", {
		Text = "Fly Speed",
		Default = 200,
		Min = 0,
		Max = 450,
		Suffix = "/s",
		Rounding = 0,
	})

	flyDepBox:AddSlider("FlyUpSpeed", {
		Text = "Spacebar Fly Speed",
		Default = 150,
		Min = 0,
		Max = 300,
		Suffix = "/s",
		Rounding = 0,
	})

	local noclipToggle = groupbox:AddToggle("NoClip", {
		Text = "NoClip",
		Tooltip = "Disable collision(s) for your character.",
		Default = false,
	})

	noclipToggle:AddKeyPicker("NoClipKeybind", { Default = "N/A", SyncToggleState = true, Text = "NoClip" })

	local noclipDepBox = groupbox:AddDependencyBox()

	noclipDepBox:AddToggle("NoClipCollisionsKnocked", {
		Text = "Collisions While Knocked",
		Tooltip = "Enable collisions while knocked.",
		Default = false,
	})

	local atbToggle = groupbox:AddToggle("AttachToBack", {
		Text = "Attach To Back",
		Tooltip = "Start following the nearest entity based on a distance and height offset.",
		Default = false,
	})

	atbToggle:AddKeyPicker("AttachToBackKeybind", { Default = "N/A", SyncToggleState = true, Text = "Attach To Back" })

	local atbDepBox = groupbox:AddDependencyBox()

	atbDepBox:AddSlider("BackOffset", {
		Text = "Distance To Entity",
		Default = 5,
		Min = -30,
		Max = 30,
		Suffix = "studs",
		Rounding = 0,
	})

	atbDepBox:AddSlider("HeightOffset", {
		Text = "Height Offset",
		Default = 0,
		Min = -30,
		Max = 30,
		Suffix = "studs",
		Rounding = 0,
	})

	local infJumpToggle = groupbox:AddToggle("InfiniteJump", {
		Text = "Infinite Jump",
		Tooltip = "Boost your velocity while the jump key is held.",
		Default = false,
	})

	infJumpToggle:AddKeyPicker(
		"InfiniteJumpKeybind",
		{ Default = "N/A", SyncToggleState = true, Text = "Infinite Jump" }
	)

	local infiniteJumpDepBox = groupbox:AddDependencyBox()

	infiniteJumpDepBox:AddSlider("InfiniteJumpBoost", {
		Text = "Infinite Jump Boost",
		Default = 50,
		Min = 0,
		Max = 500,
		Suffix = "/s",
		Rounding = 0,
	})

	groupbox:AddToggle("AgilitySpoof", {
		Text = "Agility Spoofer",
		Tooltip = "Set your Agility investment points to boost movement.",
		Default = false,
	})

	local agilitySpoofDepBox = groupbox:AddDependencyBox()

	agilitySpoofDepBox:AddToggle("BoostAgilityDirectly", {
		Text = "Boost Agility Directly",
		Tooltip = "Boost your Agility directly instead of using investment points.",
		Default = false,
	})

	agilitySpoofDepBox:AddSlider("AgilitySpoof", {
		Text = "Agility Value",
		Default = 0,
		Min = 0,
		Max = 400,
		Suffix = "pts",
		Rounding = 0,
	})

	groupbox
		:AddToggle("TweenToObjectives", {
			Text = "Tween To Objectives",
			Tooltip = "Smoothly move to objectives inside of Ethiron and Chaser's boss fights.",
			Default = false,
		})
		:AddKeyPicker(
			"TweenToObjectivesKeybind",
			{ Default = "N/A", SyncToggleState = true, Text = "Tween To Objectives" }
		)

	groupbox:AddToggle("AutoSprint", {
		Text = "Auto Sprint",
		Tooltip = "Instantly invoke a sprint when pressing a key in any direction.",
		Default = false,
	})

	local asDepBox = groupbox:AddDependencyBox()

	asDepBox:AddToggle("AutoSprintDelay", {
		Text = "Auto Sprint Delay",
		Tooltip = "Delay the automated sprint activation after pressing a key.",
		Default = false,
	})

	local asdDepBox = asDepBox:AddDependencyBox()

	asdDepBox:AddSlider("AutoSprintDelayTime", {
		Text = "Auto Sprint Delay Time",
		Default = 0.2,
		Min = 0,
		Max = 5,
		Suffix = "s",
		Rounding = 2,
	})

	groupbox:AddToggle("FreestylersBandSpoof", {
		Text = "Freestylers Band Spoofer",
		Tooltip = "Use the Freestylers Band without equipping it.",
		Default = false,
	})

	groupbox:AddToggle("KongaClutchRingSpoof", {
		Text = "Konga Clutch Ring Spoofer",
		Tooltip = "Use the Konga Clutch Ring without equipping it.",
		Default = false,
	})

	groupbox:AddToggle("EmoteSpoofer", {
		Text = "Emote Spoofer",
		Tooltip = "Unlock all emotes and use them without owning them.",
		Default = false,
	})

	groupbox:AddButton({
		Text = "Respawn Character",
		DoubleClick = true,
		Func = function()
			local character = players.LocalPlayer.Character
			if not character then
				return
			end

			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				return
			end

			character:PivotTo(humanoidRootPart.CFrame * CFrame.new(0, 10000000, 0))
		end,
	})

	agilitySpoofDepBox:SetupDependencies({
		{ Toggles.AgilitySpoof, true },
	})

	asdDepBox:SetupDependencies({
		{ Toggles.AutoSprintDelay, true },
	})

	asDepBox:SetupDependencies({
		{ Toggles.AutoSprint, true },
	})

	infiniteJumpDepBox:SetupDependencies({
		{ Toggles.InfiniteJump, true },
	})

	speedDepBox:SetupDependencies({
		{ Toggles.Speedhack, true },
	})

	flyDepBox:SetupDependencies({
		{ Toggles.Fly, true },
	})

	noclipDepBox:SetupDependencies({
		{ Toggles.NoClip, true },
	})

	atbDepBox:SetupDependencies({
		{ Toggles.AttachToBack, true },
	})
end

---Initialize player monitoring section.
---@param groupbox table
function GameTab.initPlayerMonitoringSection(groupbox)
	groupbox:AddToggle("NotifyMod", {
		Text = "Mod Notifications",
		Default = true,
	})

	local nmDepBox = groupbox:AddDependencyBox()

	nmDepBox:AddToggle("NotifyModBeep", {
		Text = "Play Beep Sound",
		Tooltip = "Use a beep sound along with the mod notification.",
		Default = false,
	})

	local nmbDepBox = nmDepBox:AddDependencyBox()

	nmbDepBox:AddSlider("NotifyModBeepVolume", {
		Text = "Beep Sound Volume",
		Default = 10,
		Min = 0,
		Max = 20,
		Suffix = "v",
		Rounding = 2,
	})

	nmbDepBox:SetupDependencies({
		{ Toggles.NotifyModBeep, true },
	})

	nmDepBox:SetupDependencies({
		{ Toggles.NotifyMod, true },
	})

	groupbox:AddToggle("NotifyVoidWalker", {
		Text = "Void Walker Notifications",
		Tooltip = "This will notify you when a player has a Void Walker contract.",
		Default = false,
	})

	groupbox:AddToggle("NotifyMythic", {
		Text = "Legendary Weapon Notifications",
		Tooltip = "This will notify you when a player has a Legendary Weapon in their inventory.",
		Default = false,
	})

	groupbox:AddToggle("PlayerSpectating", {
		Text = "Player List Spectating",
		Tooltip = "Click on a player on the player list to spectate them.",
		Default = false,
	})

	groupbox:AddToggle("ShowHiddenPlayers", {
		Text = "Show Hidden Players",
		Tooltip = "Show hidden players on the player list.",
		Default = false,
	})

	groupbox:AddToggle("ShowRobloxChat", {
		Text = "Show Roblox Chat",
		Default = true,
	})

	groupbox:AddToggle("ShowOwnership", {
		Text = "Show Network Ownership",
		Default = false,
	})

	local bestiaryToggle = groupbox:AddToggle("ShowBestiary", {
		Text = "Show Bestiary UI",
		Default = false,
		Callback = Bestiary.visible,
	})

	bestiaryToggle:AddKeyPicker("BestiaryKeybind", { Default = "N/A", SyncToggleState = true, Text = "Bestiary UI" })

	groupbox:AddToggle("PlayerProximity", {
		Text = "Player Proximity Notifications",
		Tooltip = "When other players are within specified distance, notify the user.",
		Default = false,
	})

	local ppDepBox = groupbox:AddDependencyBox()

	ppDepBox:AddSlider("PlayerProximityRange", {
		Text = "Player Proximity Distance",
		Default = 1000,
		Min = 50,
		Max = 2500,
		Suffix = "studs",
		Rounding = 0,
	})

	ppDepBox:AddToggle("PlayerProximityVW", {
		Text = "Only Allow Voidwalkers",
		Tooltip = "The other players must have a Voidwalker Contract for us to be warned.",
		Default = false,
	})

	ppDepBox:AddToggle("PlayerProximityBeep", {
		Text = "Play Beep Sound",
		Tooltip = "Use a beep sound along with the proximity notification.",
		Default = false,
	})

	local ppbDepBox = ppDepBox:AddDependencyBox()

	ppbDepBox:AddSlider("PlayerProximityBeepVolume", {
		Text = "Beep Sound Volume",
		Default = 0.1,
		Min = 0,
		Max = 10,
		Suffix = "v",
		Rounding = 2,
	})

	ppbDepBox:SetupDependencies({
		{ Toggles.PlayerProximityBeep, true },
	})

	ppDepBox:SetupDependencies({
		{ Toggles.PlayerProximity, true },
	})
end

---Initialize effect removals section.
---@param groupbox table
function GameTab.initEffectRemovalsSection(groupbox)
	groupbox:AddToggle("NoStun", {
		Text = "No Stun",
		Tooltip = "Remove any incoming 'Stun' effects from the server.",
		Default = false,
	})

	groupbox:AddToggle("NoSpeedDebuff", {
		Text = "No Speed Debuff",
		Tooltip = "Remove any incoming 'Speed Debuff' effects from the server.",
		Default = false,
	})

	groupbox:AddToggle("NoFallDamage", {
		Text = "No Fall Damage",
		Tooltip = "Remove any 'Fall Damage' requests to the server.",
		Default = false,
	})

	groupbox:AddToggle("NoAcidWater", {
		Text = "No Acid Water",
		Tooltip = "Remove any 'Acid Water Damage' requests to the server.",
		Default = false,
	})

	groupbox:AddToggle("NoWind", {
		Text = "No Wind",
		Tooltip = "Remove any 'Wind' effects from the server.",
		Default = false,
	})

	groupbox:AddToggle("NoJumpCooldown", {
		Text = "No Jump Cooldown",
		Tooltip = "Remove any 'Jump Cooldown' effects from the server.",
		Default = false,
	})
end

---Initialize instance removals.
---@param groupbox table
function GameTab.initInstanceRemovalsSection(groupbox)
	groupbox:AddToggle("NoEchoModifiers", {
		Text = "No Echo Modifiers",
		Tooltip = "Remove any 'Echo Modifiers' instances on the client.",
		Default = false,
	})

	groupbox:AddToggle("NoKillBricks", {
		Text = "No Kill Bricks",
		Tooltip = "Remove any 'Kill Brick' parts on the client.",
		Default = false,
	})

	groupbox:AddToggle("NoCastleLightBarrier", {
		Text = "No Castle Light Barrier",
		Tooltip = "Remove any 'Castle Light Barrier' parts on the client.",
		Default = false,
	})

	groupbox:AddToggle("NoYunShulBarrier", {
		Text = "No Yun Shul Barrier",
		Tooltip = "Remove any 'Yun Shul Barrier' parts on the client.",
		Default = false,
	})
end

---Debugging section.
---@param groupbox table
function GameTab.initDebuggingSection(groupbox)
	local irltSlider = nil

	local irlToggle = groupbox:AddToggle("IncomingReplicationLag", {
		Text = "Incoming Replication Lag",
		Default = false,
		Callback = function(value)
			if not irltSlider then
				return
			end

			settings().Network.IncomingReplicationLag = value and irltSlider.Value or 0
		end,
	})

	local irltDepBox = groupbox:AddDependencyBox()

	irltSlider = irltDepBox:AddSlider("IncomingReplicationLagTime", {
		Text = "Incoming Replication Lag Time",
		Default = 0.1,
		Min = 0,
		Max = 5,
		Suffix = "s",
		Rounding = 2,
		Callback = function(value)
			settings().Network.IncomingReplicationLag = value
		end,
	})

	irltDepBox:SetupDependencies({
		{ irlToggle, true },
	})
end
---Initialize tab.
function GameTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Game")

	-- Initialize sections.
	GameTab.initDebuggingSection(tab:AddDynamicGroupbox("Debugging"))
	GameTab.initLocalCharacterSection(tab:AddDynamicGroupbox("Local Character"))
	GameTab.initEffectRemovalsSection(tab:AddDynamicGroupbox("Effect Removals"))
	GameTab.initInstanceRemovalsSection(tab:AddDynamicGroupbox("Instance Removals"))
	GameTab.initPlayerMonitoringSection(tab:AddDynamicGroupbox("Player Monitoring"))
end

-- Return GameTab module.
return GameTab
