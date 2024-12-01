-- LycorisTab module.
local LycorisTab = {}

-- Fetch environment.
local environment = getgenv and getgenv() or _G
if not environment then
	return
end

---@module GUI.ThemeManager
local ThemeManager = require("GUI/ThemeManager")

---@module GUI.SaveManager
local SaveManager = require("GUI/SaveManager")

---@module GUI.Library
local Library = require("GUI/Library")

---Initialize Cheat Settings section.
---@param groupbox table
function LycorisTab.initCheatSettingsSection(groupbox)
	groupbox:AddButton("Unload Cheat", function()
		environment.Lycoris.detach()
	end)
end

---Initialize UI Settings section.
---@param groupbox table
function LycorisTab.initUISettingsSection(groupbox)
	local menuBindLabel = groupbox:AddLabel("Menu Bind")

	menuBindLabel:AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = true, Text = "Menu Keybind" })

	local keybindFrameLabel = groupbox:AddLabel("Keybind List Bind")

	keybindFrameLabel:AddKeyPicker("KeybindList", {
		Default = "Backquote",
		Mode = "Always",
		NoUI = true,
		Text = "Keybind List",
		Callback = function(Value)
			Library.KeybindFrame.Visible = Value
		end,
	})
end

---Initialize tab.
function LycorisTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Settings") -- dont change the name, it's more confusing if its named that way

	-- Initialize sections.
	LycorisTab.initCheatSettingsSection(tab:AddLeftGroupbox("Cheat Settings"))
	LycorisTab.initUISettingsSection(tab:AddRightGroupbox("UI Settings"))

	-- Configure SaveManager & ThemeManager.
	ThemeManager:ApplyToTab(tab)
	SaveManager:BuildConfigSection(tab)
end

-- Return LycorisTab module.
return LycorisTab
