-- PlayerTab module.
local PlayerTab = {}

---Initialize atach to back section.
---@param groupbox table
function PlayerTab.initAtbSection(groupbox)
	local atbDepBox = groupbox:AddDependencyBox()

	groupbox:AddToggle("AttachToBack", {
		Text = "Attach To Back",
		Tooltip = "Start following the nearest entity based on a distance and height offset.",
		Default = false,
	})

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

	atbDepBox:SetupDependencies({
		{ Toggles.AttachToBack, true },
	})
end

---Initialize tab.
function PlayerTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Player")

	-- Initialize sections.
	PlayerTab.initAtbSection(tab:AddLeftGroupbox("Attach To Back"))
end

-- Return PlayerTab module.
return PlayerTab
