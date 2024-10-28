-- Menu module.
local Menu = {}

---@module GUI.ThemeManager
local ThemeManager = require("GUI/ThemeManager")

---@module GUI.SaveManager
local SaveManager = require("GUI/SaveManager")

---@module GUI.Library
local Library = require("GUI/Library")

---@module Menu.CombatTab
local CombatTab = require("Menu/CombatTab")

---@module Menu.AutomationTab
local AutomationTab = require("Menu/AutomationTab")

---@module Menu.PlayerTab
local PlayerTab = require("Menu/PlayerTab")

---@module Menu.SettingsTab
local SettingsTab = require("Menu/SettingsTab")

---Initialize menu.
function Menu.init()
	-- Create window.
	local window = Library:CreateWindow({
		Title = "Lycoris 1.0",
		Center = true,
		TabPadding = 8,
		MenuFadeTime = 0.1,
	})

	---@note: How the menu will be structured from now on:
	-- All keybinds will be using the AddKeyPicker function on the objects themselves - not as a seperate tab.
	-- Combat tab which houses auto-parry, logging, and other combat-related features.
	-- Player tab which houses auto-sprint, infinite-jump, and other player-related features.
	-- Visuals tab which houses ESP, Tracers, Emotes, Unlocked Zoom Limits and other visual-related features.
	-- Exploits tab which houses mob voiding, mob TPing, and other exploit-related features.
	-- Automation tab which houses auto-farm, auto-maestro, auto-quest, and other automation-related features.
	-- Settings tab which houses keybinds, UI settings, and other settings-related features.

	-- Initialize all tabs.
	CombatTab.init(window)
	AutomationTab.init(window)
	PlayerTab.init(window)
	SettingsTab.init(window)

	-- Configure Library.
	Library.ToggleKeybind = Options.MenuKeybind

	-- Configure ThemeManager.
	ThemeManager:SetLibrary(Library)
	ThemeManager:SetFolder("Lycoris")

	-- Configure SaveManager.
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetFolder("Lycoris")
	SaveManager:LoadAutoloadConfig()
end

---Detach menu.
function Menu.detach()
	Library:Unload()
end

-- Return Menu module.
return Menu
