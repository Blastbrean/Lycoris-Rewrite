-- PlayerTab module.
local PlayerTab = {}

---Initialize movement section.
---@param groupbox table
function PlayerTab.initMovementSection(groupbox)
	groupbox
		:AddToggle("Speedhack", {
			Text = "Speedhack",
			Tooltip = "Modify your character's velocity while moving.",
			Default = false,
		})
		:AddKeyPicker("SpeedhackKeybind", { Default = "X", SyncToggleState = true, Text = "Speedhack" })

	local speedDepBox = groupbox:AddDependencyBox()

	speedDepBox:AddSlider("SpeedhackSpeed", {
		Text = "Speedhack Speed",
		Default = 200,
		Min = 0,
		Max = 300,
		Suffix = "studs",
		Rounding = 0,
	})

	groupbox
		:AddToggle("Fly", {
			Text = "Fly",
			Tooltip = "Set your character's velocity while moving to imitate flying.",
			Default = false,
		})
		:AddKeyPicker("FlyKeybind", { Default = "CapsLock", SyncToggleState = true, Text = "Fly" })

	local flyDepBox = groupbox:AddDependencyBox()

	flyDepBox:AddSlider("FlySpeed", {
		Text = "Fly Speed",
		Default = 200,
		Min = 0,
		Max = 300,
		Suffix = "studs",
		Rounding = 0,
	})

	flyDepBox:AddSlider("FlyUpSpeed", {
		Text = "Spacebar Fly Speed",
		Default = 150,
		Min = 0,
		Max = 300,
		Suffix = "studs",
		Rounding = 0,
	})

	groupbox
		:AddToggle("NoClip", {
			Text = "NoClip",
			Tooltip = "Disable collision(s) for your character.",
			Default = false,
		})
		:AddKeyPicker("NoClipKeybind", { Default = "CapsLock", SyncToggleState = true, Text = "NoClip" })

	local noclipDepBox = groupbox:AddDependencyBox()

	noclipDepBox:AddToggle("NoClipCollisionsKnocked", {
		Text = "Collisions While Knocked",
		Tooltip = "Enable collisions while knocked.",
		Default = false,
	})

	groupbox
		:AddToggle("AttachToBack", {
			Text = "Attach To Back",
			Tooltip = "Start following the nearest entity based on a distance and height offset.",
			Default = false,
		})
		:AddKeyPicker("AttachToBackKeybind", { Default = "[", SyncToggleState = true, Text = "Attach To Back" })

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

	groupbox:AddToggle("InfiniteJump", {
		Text = "Infinite Jump",
		Tooltip = "Boost your velocity while the jump key is held.",
		Default = false,
	})

	local infiniteJumpDepBox = groupbox:AddDependencyBox()

	infiniteJumpDepBox:AddSlider("InfiniteJumpBoost", {
		Text = "Infinite Jump Boost",
		Default = 50,
		Min = 0,
		Max = 500,
		Suffix = "studs",
		Rounding = 0,
	})

	groupbox:AddToggle("AgilitySpoof", {
		Text = "Agility Spoofer",
		Tooltip = "Set your Agility investment points to boost movement realistically.",
		Default = false,
	})

	local agilitySpoofDepBox = groupbox:AddDependencyBox()

	agilitySpoofDepBox:AddSlider("AgilitySpoof", {
		Text = "Agility Value",
		Default = 0,
		Min = 0,
		Max = 200,
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
			{ Default = "V", SyncToggleState = true, Text = "Tween To Objectives" }
		)

	groupbox:AddToggle("AutoSprint", {
		Text = "Auto Sprint",
		Tooltip = "Instantly invoke a sprint when pressing a key in any direction.",
		Default = false,
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

---Initialize removal section.
---@param groupbox table
function PlayerTab.initRemovalSection(groupbox)
	local umacDepBox = groupbox:AddDependencyBox()

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

	groupbox:AddToggle("NoAcid", {
		Text = "Anti Acid",
		Tooltip = "Remove any 'Acid Damage' requests to the server.",
		Default = false,
	})

	groupbox:AddToggle("AntiFire", {
		Text = "Anti Fire",
		Tooltip = "Attempt to remove 'Burning' effects through automatic sliding.",
		Default = false,
	})

	groupbox:AddToggle("AntiWind", {
		Text = "Anti Wind",
		Tooltip = "Remove any 'Wind' effects from the server.",
		Default = false,
	})

	groupbox:AddToggle("NoFog", {
		Text = "No Fog",
		Tooltip = "Atmosphere and Fog effects are hidden.",
		Default = false,
	})

	groupbox:AddToggle("NoBlind", {
		Text = "No Blind",
		Tooltip = "Blinding effects are hidden.",
		Default = false,
	})

	groupbox:AddToggle("NoBlur", {
		Text = "No Blur",
		Tooltip = "Blurry effects are hidden.",
		Default = false,
	})

	groupbox:AddToggle("NoJumpCooldown", {
		Text = "No Jump Cooldown",
		Tooltip = "Remove any 'Jump Cooldown' effects from the server.",
		Default = false,
	})

	groupbox:AddToggle("NoShadows", {
		Text = "No Shadows",
		Tooltip = "Shadow effects are hidden.",
		Default = false,
	})

	groupbox
		:AddToggle("ModifyAmbience", {
			Text = "Modify Ambience",
			Tooltip = "Modify the ambience of the game.",
			Default = false,
		})
		:AddColorPicker("AmbienceColor", {
			Default = Color3.fromHex("FFFFFF"),
		})

	groupbox:AddToggle("OriginalAmbienceColor", {
		Text = "Original Ambience Color",
		Tooltip = "Use the game's original ambience color instead of a custom one.",
		Default = false,
	})

	umacDepBox:AddSlider("OriginalAmbienceColorBrightness", {
		Text = "Original Ambience Brightness",
		Default = 0,
		Min = 0,
		Max = 255,
		Suffix = "br",
		Rounding = 0,
	})

	umacDepBox:SetupDependencies({
		{ Toggles.OriginalAmbienceColor, true },
	})
end

---Initialize tab.
function PlayerTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Player")

	-- Initialize sections.
	PlayerTab.initMovementSection(tab:AddLeftGroupbox("Movement"))
	PlayerTab.initRemovalSection(tab:AddRightGroupbox("Removal"))
end

-- Return PlayerTab module.
return PlayerTab
