-- SettingsTab module.
local SettingsTab = {}

-- Fetch environment.
local environment = getgenv and getgenv() or _G
if not environment then
	return
end

---@module GUI.ThemeManager
local ThemeManager = require("GUI/ThemeManager")

---@module GUI.SaveManager
local SaveManager = require("GUI/SaveManager")

-- Initialize UI settings section.
---@param groupbox table
function SettingsTab.initUISettingsSection(groupbox)
	groupbox:AddButton("Unload", function()
		environment.Lycoris.detach()
	end)

	local menuBindLabel = groupbox:AddLabel("Menu Bind")
	menuBindLabel:AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = true, Text = "Menu Keybind" })
end

---Initialize tab.
function SettingsTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Settings")

	-- Initialize sections.
	SettingsTab.initUISettingsSection(tab:AddLeftGroupbox("Menu"))

	-- Configure SaveManager & ThemeManager.
	ThemeManager:ApplyToTab(tab)
	SaveManager:BuildConfigSection(tab)
end

-- Return SettingsTab module.
return SettingsTab
