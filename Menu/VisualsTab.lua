---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Features.Visuals.Visuals
local Visuals = require("Features/Visuals/Visuals")

---@module Utility.JSON
local JSON = require("Utility/JSON")

---@module Features.Visuals.Objects.BuilderData
local BuilderData = require("Features/Visuals/Objects/BuilderData")

-- Visuals tab.
local VisualsTab = {}

---Initialize ESP Customization section.
---@param groupbox table
function VisualsTab.initESPCustomization(groupbox)
	groupbox:AddSlider("FontSize", {
		Text = "ESP Font Size",
		Default = 16,
		Min = 4,
		Max = 24,
		Rounding = 0,
	})

	groupbox:AddSlider("ESPSplitLineLength", {
		Text = "ESP Split Line Length",
		Tooltip = "The total length of a ESP label line before it splits into a new line.",
		Default = 30,
		Min = 10,
		Max = 100,
		Rounding = 0,
	})

	local fonts = {}

	for _, font in next, Enum.Font:GetEnumItems() do
		if font == Enum.Font.Unknown then
			continue
		end

		table.insert(fonts, font.Name)
	end

	groupbox:AddDropdown("Font", { Text = "ESP Fonts", Default = 1, Values = fonts })
end

---Initialize ESP Optimizations section.
---@param groupbox table
function VisualsTab.initESPOptimizations(groupbox)
	groupbox:AddToggle("ESPLimitUpdates", {
		Text = "ESP Limit Updates",
		Tooltip = "Limit when ESP updates can happen in a given amount of frames.",
		Default = true,
	})

	local eluDepBox = groupbox:AddDependencyBox()

	eluDepBox:AddSlider("ESPRefreshRate", {
		Text = "ESP Refresh Rate",
		Tooltip = "The frames that the ESP will attempt to update in.",
		Suffix = "f",
		Default = 30,
		Min = 1,
		Max = 144,
		Rounding = 0,
	})

	eluDepBox:SetupDependencies({
		{ Toggles.ESPLimitUpdates, true },
	})

	groupbox:AddToggle("ESPSplitUpdates", {
		Text = "ESP Split Updates",
		Tooltip = "This is an optimization where the ESP will split updating the object pool into multiple frames.",
		Default = false,
	})

	local esuDepBox = groupbox:AddDependencyBox()

	esuDepBox:AddSlider("ESPSplitFrames", {
		Text = "ESP Split Frames",
		Tooltip = "How many frames we have to split the object pool into.",
		Suffix = "f",
		Default = 32,
		Min = 1,
		Max = 64,
		Rounding = 0,
	})

	groupbox:AddToggle("NoPersisentESP", {
		Text = "No Persistent ESP",
		Tooltip = "Disable ESP models from being persistent and never being streamed out.",
		Default = false,
	})
end

---Initialize World Visuals section.
---@param groupbox table
function VisualsTab.initWorldVisualsSection(groupbox)
	groupbox:AddToggle("ModifyFieldOfView", {
		Text = "Modify Field Of View",
		Default = true,
	})

	local fovDepBox = groupbox:AddDependencyBox()

	fovDepBox:AddSlider("FieldOfView", {
		Text = "Field Of View Slider",
		Default = 90,
		Min = 0,
		Max = 120,
		Suffix = "°",
		Rounding = 0,
	})

	fovDepBox:SetupDependencies({
		{ Toggles.ModifyFieldOfView, true },
	})

	local modifyAmbienceToggle = groupbox:AddToggle("ModifyAmbience", {
		Text = "Modify Ambience",
		Tooltip = "Modify the ambience of the game.",
		Default = false,
	})

	modifyAmbienceToggle:AddColorPicker("AmbienceColor", {
		Default = Color3.fromHex("FFFFFF"),
	})

	local oacDepBox = groupbox:AddDependencyBox()

	oacDepBox:AddToggle("OriginalAmbienceColor", {
		Text = "Original Ambience Color",
		Tooltip = "Use the game's original ambience color instead of a custom one.",
		Default = false,
	})

	local umacDepBox = oacDepBox:AddDependencyBox()

	umacDepBox:AddSlider("OriginalAmbienceColorBrightness", {
		Text = "Original Ambience Brightness",
		Default = 0,
		Min = 0,
		Max = 255,
		Suffix = "+",
		Rounding = 0,
	})

	oacDepBox:SetupDependencies({
		{ Toggles.ModifyAmbience, true },
	})

	umacDepBox:SetupDependencies({
		{ Toggles.OriginalAmbienceColor, true },
	})
end

---Initialize Visual Assistance section.
---@param groupbox table
function VisualsTab.initVisualAssistanceSection(groupbox)
	groupbox:AddToggle("SanityTracker", {
		Text = "Sanity Tracker",
		Tooltip = "Create a tracker marking how much sanity you have left.",
		Default = false,
	})

	local buildAssistanceToggle = groupbox:AddToggle("BuildAssistance", {
		Text = "Build Assistance",
		Tooltip = "Visual assistance for selecting talents, progressing a build, and more.",
		Default = false,
	})

	local buildAssistanceDepBox = groupbox:AddDependencyBox()

	local sdoToggle = buildAssistanceDepBox:AddToggle("ShrineDetectionOverride", {
		Text = "Shrine Detection Override",
		Tooltip = "Auto-detection for shrine can be wrong especially when it refunds your points. You can use this to override the current state.",
		Default = true,
	})

	local sdoDepBox = buildAssistanceDepBox:AddDependencyBox()

	sdoDepBox:AddDropdown("ShrineOverrideState", {
		Text = "Shrine Override State",
		Tooltip = "The shrine state to override to.",
		Default = 1,
		Values = { "Pre-Shrine", "Post-Shrine", "Must Shrine" },
	})

	sdoDepBox:SetupDependencies({
		{ sdoToggle, true },
	})

	buildAssistanceDepBox:AddInput("BuildAssistanceLink", {
		Text = "Build Assistance Link",
		Tooltip = "The builder link that will be used to assist with builds.",
		Placeholder = "Enter your builder link here.",
		Finished = true,
		Callback = function(value)
			if not buildAssistanceToggle.Value then
				return
			end

			local dresponse = request({
				Url = "https://api.deepwoken.co/get?type=all",
				Method = "GET",
				Headers = { ["Content-Type"] = "application/json" },
			})

			if not dresponse or not dresponse.Success or not dresponse.Body then
				return Logger.notify("Invalid response while fetching data response.")
			end

			local dsuccess, dresult = pcall(JSON.decode, dresponse.Body)
			if not dsuccess or not dresult then
				return Logger.notify("JSON error '%s' while deserializing data response.", dresult)
			end

			Logger.notify("Successfully fetched Deepwoken data.")

			local id = value:gsub("https://deepwoken.co/builder%?id=", ""):gsub(" ", ""):gsub("\n", "")
			local bresponse = request({
				Url = ("https://api.deepwoken.co/build?id=%s"):format(id),
				Method = "GET",
				Headers = { ["Content-Type"] = "application/json" },
			})

			if not bresponse or not bresponse.Success or not bresponse.Body then
				return Logger.notify("Invalid response while fetching builder response.")
			end

			local bsuccess, bresult = pcall(JSON.decode, bresponse.Body)
			if not bsuccess or not bresult then
				return Logger.notify("JSON error '%s' while deserializing builder response.", bresult)
			end

			Logger.notify("Successfully created BuilderData object.")

			Visuals.bdata = BuilderData.new(bresult, dresult)
		end,
	})

	buildAssistanceDepBox:SetupDependencies({
		{ buildAssistanceToggle, true },
	})
end

---Initialize Visual Removals section.
---@param groupbox table
function VisualsTab.initVisualRemovalsSection(groupbox)
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

	groupbox:AddToggle("NoShadows", {
		Text = "No Shadows",
		Tooltip = "Shadow effects are hidden.",
		Default = false,
	})

	groupbox:AddToggle("NoAnimatedSea", {
		Text = "No Animated Sea",
		Tooltip = "Disable the script(s) that animate the sea.",
		Default = false,
	})
end

---Initialize Base ESP section.
---@note: Every ESP object has access to these options.
---@param identifier string
---@param groupbox table
---@return string, table, table
function VisualsTab.initBaseESPSection(identifier, groupbox)
	local enableToggle = groupbox
		:AddToggle(Configuration.identify(identifier, "Enable"), {
			Text = "Enable ESP",
			Default = false,
		})
		:AddKeyPicker(Configuration.identify(identifier, "Keybind"), {
			Default = "N/A",
			SyncToggleState = true,
			NoUI = true,
			Text = groupbox.Name,
		})

	enableToggle:AddColorPicker(Configuration.identify(identifier, "Color"), {
		Default = Color3.new(1, 1, 1),
	})

	local enableDepBox = groupbox:AddDependencyBox()

	enableDepBox:AddToggle(Configuration.identify(identifier, "ShowDistance"), {
		Text = "Show Distance",
		Default = false,
	})

	enableDepBox:AddSlider(Configuration.identify(identifier, "MaxDistance"), {
		Text = "Distance Threshold",
		Tooltip = "If the distance is greater than this value, the ESP object will not be shown.",
		Default = 2000,
		Min = 0,
		Max = 100000,
		Suffix = "studs",
		Rounding = 0,
	})

	enableDepBox:SetupDependencies({
		{ enableToggle, true },
	})

	return identifier, enableDepBox
end

---Add Player ESP section.
---@param identifier string
---@param depbox table
function VisualsTab.addPlayerESP(identifier, depbox)
	local markAlliesToggle = depbox:AddToggle(Configuration.identify(identifier, "MarkAllies"), {
		Text = "Mark Allies",
		Default = false,
	})

	markAlliesToggle:AddColorPicker(Configuration.identify(identifier, "AllyColor"), {
		Default = Color3.new(1, 1, 1),
	})

	depbox:AddToggle(Configuration.identify(identifier, "ShowBlood"), {
		Text = "Show Blood Tag",
		Default = false,
	})

	depbox:AddToggle(Configuration.identify(identifier, "ShowPosture"), {
		Text = "Show Posture Tag",
		Default = false,
	})

	depbox:AddToggle(Configuration.identify(identifier, "ShowTempo"), {
		Text = "Show Tempo Tag",
		Default = false,
	})

	depbox:AddToggle(Configuration.identify(identifier, "ShowViewAngle"), {
		Text = "Show View Angle",
		Default = false,
	})

	depbox:AddToggle(Configuration.identify(identifier, "ShowDangerTime"), {
		Text = "Show Danger Time",
		Default = false,
	})

	depbox:AddToggle(Configuration.identify(identifier, "ShowHealthPercentage"), {
		Text = "Show Health Percentage",
		Default = false,
	})

	depbox:AddToggle(Configuration.identify(identifier, "ShowHealthBars"), {
		Text = "Show Health In Bars",
		Default = false,
	})

	depbox:AddDropdown(Configuration.identify(identifier, "PlayerNameType"), {
		Text = "Player Name Type",
		Default = 1,
		Values = { "Character Name", "Roblox Display Name", "Roblox Username" },
	})
end

---Add Filtered ESP section.
---@param identifier string
---@param depbox table
function VisualsTab.addFilterESP(identifier, depbox)
	local filterObjectsToggle = depbox:AddToggle(Configuration.identify(identifier, "FilterObjects"), {
		Text = "Filter Objects",
		Default = true,
	})

	local foDepBox = depbox:AddDependencyBox()

	local filterLabelList = foDepBox:AddDropdown(Configuration.identify(identifier, "FilterLabelList"), {
		Text = "Filter Label List",
		Default = {},
		SaveValues = true,
		Multi = true,
		Values = {},
	})

	local filterLabel = foDepBox:AddInput(Configuration.identify(identifier, "FilterLabel"), {
		Text = "Filter Label",
		Placeholder = "Partial or exact object label.",
	})

	foDepBox:AddDropdown(Configuration.identify(identifier, "FilterLabelListType"), {
		Text = "Filter List Type",
		Default = 1,
		Values = { "Hide Labels Out Of List", "Hide Labels In List" },
	})

	foDepBox:AddButton("Add Name To Filter", function()
		local filterLabelValue = filterLabel.Value

		if #filterLabelValue <= 0 then
			return Logger.notify("Please enter a valid filter name.")
		end

		local filterLabelListValues = filterLabelList.Values

		if not table.find(filterLabelListValues, filterLabelValue) then
			table.insert(filterLabelListValues, filterLabelValue)
		end

		filterLabelList:SetValues(filterLabelListValues)
		filterLabelList:SetValue({})
		filterLabelList:Display()
	end)

	foDepBox:AddButton("Remove Selected Names", function()
		local filterLabelListValues = filterLabelList.Values
		local selectedFilterNames = filterLabelList.Value

		for selectedFilterName, _ in next, selectedFilterNames do
			local selectedIndex = table.find(filterLabelListValues, selectedFilterName)
			if not selectedIndex then
				return Logger.notify("The selected filter name %s does not exist in the list", selectedFilterName)
			end

			table.remove(filterLabelListValues, selectedIndex)
		end

		filterLabelList:SetValues(filterLabelListValues)
		filterLabelList:SetValue({})
		filterLabelList:Display()
	end)

	foDepBox:SetupDependencies({
		{ filterObjectsToggle, true },
	})
end

---Initialize tab.
---@param window table
function VisualsTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Visuals")

	-- Initialize sections.
	VisualsTab.initESPCustomization(tab:AddDynamicGroupbox("ESP Customization"))
	VisualsTab.initESPOptimizations(tab:AddDynamicGroupbox("ESP Optimizations"))
	VisualsTab.initWorldVisualsSection(tab:AddDynamicGroupbox("World Visuals"))
	VisualsTab.initVisualRemovalsSection(tab:AddDynamicGroupbox("Visual Removals"))
	VisualsTab.initVisualAssistanceSection(tab:AddDynamicGroupbox("Visual Assistance"))
	VisualsTab.addPlayerESP(VisualsTab.initBaseESPSection("Player", tab:AddDynamicGroupbox("Player ESP")))
	VisualsTab.initBaseESPSection("Mob", tab:AddDynamicGroupbox("Mob ESP"))
	VisualsTab.initBaseESPSection("NPC", tab:AddDynamicGroupbox("NPC ESP"))
	VisualsTab.initBaseESPSection("Chest", tab:AddDynamicGroupbox("Chest ESP"))
	VisualsTab.initBaseESPSection("BagDrop", tab:AddDynamicGroupbox("Bag ESP"))
	VisualsTab.addFilterESP(VisualsTab.initBaseESPSection("AreaMarker", tab:AddDynamicGroupbox("Area Marker ESP")))
	VisualsTab.initBaseESPSection("JobBoard", tab:AddDynamicGroupbox("Job Board ESP"))
	VisualsTab.initBaseESPSection("Artifact", tab:AddDynamicGroupbox("Artifact ESP"))
	VisualsTab.initBaseESPSection("WindrunnerOrb", tab:AddDynamicGroupbox("Windrunner Orb ESP"))
	VisualsTab.initBaseESPSection("Whirlpool", tab:AddDynamicGroupbox("Whirlpool ESP"))
	VisualsTab.initBaseESPSection("ExplosiveBarrel", tab:AddDynamicGroupbox("Explosive Barrel ESP"))
	VisualsTab.initBaseESPSection("MinistryCacheIndicator", tab:AddDynamicGroupbox("Ministry Cache ESP"))
	VisualsTab.initBaseESPSection("OwlFeathers", tab:AddDynamicGroupbox("Owl Feathers ESP"))
	VisualsTab.initBaseESPSection("GuildDoor", tab:AddDynamicGroupbox("Guild Door ESP"))
	VisualsTab.initBaseESPSection("GuildBanner", tab:AddDynamicGroupbox("Guild Banner ESP"))
	VisualsTab.initBaseESPSection("Obelisk", tab:AddDynamicGroupbox("Obelisk ESP"))
	VisualsTab.addFilterESP(VisualsTab.initBaseESPSection("Ingredient", tab:AddDynamicGroupbox("Ingredient ESP")))
	VisualsTab.initBaseESPSection("ArmorBrick", tab:AddDynamicGroupbox("Armor Brick ESP"))
	VisualsTab.initBaseESPSection("BellMeteor", tab:AddDynamicGroupbox("Bell Meteor ESP"))
	VisualsTab.initBaseESPSection("RareObelisk", tab:AddDynamicGroupbox("Rare Obelisk ESP"))
	VisualsTab.initBaseESPSection("HealBrick", tab:AddDynamicGroupbox("Heal Brick ESP"))
	VisualsTab.initBaseESPSection("MantraObelisk", tab:AddDynamicGroupbox("Mantra Obelisk ESP"))
	VisualsTab.initBaseESPSection("BRWeapon", tab:AddDynamicGroupbox("BR Weapon ESP"))
	VisualsTab.initBaseESPSection("BellKey", tab:AddDynamicGroupbox("Bell Key ESP"))
end

-- Return VisualsTab module.
return VisualsTab
