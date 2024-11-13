-- Visuals tab.
local VisualsTab = {}

---Create a groupbox with the proper alignment based on if the amount of groupboxes is even or odd.
---@param tab table
---@param title string
---@return table
local function createGroupbox(tab, title)
	if #tab.Groupboxes % 2 == 0 then
		return tab:AddLeftGroupbox(title)
	else
		return tab:AddRightGroupbox(title)
	end
end

---Create identifier based on proper identifier name based on top-level identifier.
---@param identifier string
---@param topLevelIdentifier string
function VisualsTab.identify(identifier, topLevelIdentifier)
	return ("ESP_%s_%s"):format(identifier, topLevelIdentifier)
end

---Initialize basic ESP section.
---@param identifier string
---@param groupbox table
function VisualsTab.initBasicESPSection(identifier, groupbox)
	groupbox
		:AddToggle(VisualsTab.identify(identifier, "Enable"), {
			Text = "Enable ESP",
			Default = false,
		})
		:AddColorPicker(VisualsTab.identify(identifier, "Color"), {
			Default = Color3.new(1, 1, 1),
		})

	groupbox:AddToggle(VisualsTab.identify(identifier, "Distance"), {
		Text = "Show Distance",
		Default = false,
	})

	groupbox:AddSlider(VisualsTab.identify(identifier, "DistanceThreshold"), {
		Text = "Distance Threshold",
		Tooltip = "If the distance is greater than this value, the ESP object will not be shown.",
		Default = 2000,
		Min = 0,
		Max = 10000,
		Suffix = "studs",
		Rounding = 0,
	})
end

---Initialize humanoid ESP section.
---@param identifier string
---@param groupbox table
function VisualsTab.initHumanoidESPSection(identifier, groupbox)
	VisualsTab.initBasicESPSection(identifier, groupbox)

	groupbox:AddToggle(VisualsTab.identify(identifier, "HealthBar"), {
		Text = "Show Health Bar",
		Default = false,
	})

	groupbox
		:AddToggle(VisualsTab.identify(identifier, "Box"), {
			Text = "Show Boxes",
			Default = false,
		})
		:AddColorPicker(VisualsTab.identify(identifier, "BoxColor"), {
			Default = Color3.new(1, 1, 1),
		})
end

-- Initialize tab.
---@param window table
function VisualsTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Visuals")

	-- Initialize ESP sections.
	VisualsTab.initHumanoidESPSection("Player", createGroupbox(tab, "Player ESP"))
	VisualsTab.initHumanoidESPSection("Mob", createGroupbox(tab, "Mob ESP"))
	VisualsTab.initHumanoidESPSection("NPC", createGroupbox(tab, "NPC ESP"))
	VisualsTab.initBasicESPSection("Chest", createGroupbox(tab, "Chest ESP"))
	VisualsTab.initBasicESPSection("AreaMarker", createGroupbox(tab, "Area Marker ESP"))
	VisualsTab.initBasicESPSection("JobBoard", createGroupbox(tab, "Job Board ESP"))
	VisualsTab.initBasicESPSection("Artifact", createGroupbox(tab, "Artifact ESP"))
	VisualsTab.initBasicESPSection("Whirlpool", createGroupbox(tab, "Whirlpool ESP"))
	VisualsTab.initBasicESPSection("ExplosiveBarrel", createGroupbox(tab, "Explosive Barrel ESP"))
	VisualsTab.initBasicESPSection("OwlFeathers", createGroupbox(tab, "Owl Feathers ESP"))
	VisualsTab.initBasicESPSection("GuildDoor", createGroupbox(tab, "Guild Door ESP"))
	VisualsTab.initBasicESPSection("GuildBanner", createGroupbox(tab, "Guild Banner ESP"))
	VisualsTab.initBasicESPSection("Obelisk", createGroupbox(tab, "Obelisk ESP"))
	VisualsTab.initBasicESPSection("Ingredient", createGroupbox(tab, "Ingredient ESP"))
	VisualsTab.initBasicESPSection("ArmorBrick", createGroupbox(tab, "Armor Brick ESP"))
	VisualsTab.initBasicESPSection("BellMeteor", createGroupbox(tab, "Bell Meteor ESP"))
	VisualsTab.initBasicESPSection("RareObelisk", createGroupbox(tab, "Rare Obelisk ESP"))
	VisualsTab.initBasicESPSection("HealBrick", createGroupbox(tab, "Heal Brick ESP"))
	VisualsTab.initBasicESPSection("MantraObelisk", createGroupbox(tab, "Mantra Obelisk ESP"))
	VisualsTab.initBasicESPSection("BRWeapon", createGroupbox(tab, "BR Weapon ESP"))
end

-- Return VisualsTab module.
return VisualsTab
