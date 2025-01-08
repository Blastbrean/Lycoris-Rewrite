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

---@module Menu.GameTab
local GameTab = require("Menu/GameTab")

---@module Menu.AutomationTab
local AutomationTab = require("Menu/AutomationTab")

---@module Menu.BuilderTab
local BuilderTab = require("Menu/BuilderTab")

---@module Menu.VisualsTab
local VisualsTab = require("Menu/VisualsTab")

---@module Menu.ExploitTab
local ExploitTab = require("Menu/ExploitTab")

---@module Menu.LycorisTab
local LycorisTab = require("Menu/LycorisTab")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Services.
local runService = game:GetService("RunService")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local menuMaid = Maid.new()

-- Timestamp.
local sloganTimestamp = os.clock()

-- Constants.
local MENU_TITLE = "Biggie Smalls Hack"

---Initialize menu.
function Menu.init()
	-- Create window.
	local window = Library:CreateWindow({
		Title = MENU_TITLE,
		Center = true,
		AutoShow = true,
		TabPadding = 8,
		MenuFadeTime = 0.0,
	})

	-- Configure ThemeManager.
	ThemeManager:SetLibrary(Library)
	ThemeManager:SetFolder("Lycoris-Rewrite-Themes")

	-- Configure SaveManager.
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetFolder("Lycoris-Rewrite-Configs")
	SaveManager:SetIgnoreIndexes({ "Fly", "Noclip", "Speedhack", "InfiniteJump" })

	-- Initialize all tabs.
	CombatTab.init(window)
	BuilderTab.init(window)
	GameTab.init(window)
	VisualsTab.init(window)
	AutomationTab.init(window)
	ExploitTab.init(window)
	LycorisTab.init(window)

	-- Slogans.
	local slogans = {
		"0Y4mKsTiRbldLocloTolM1",
		"5S46E2UNGDYcwZ26yj6aNr",
		"49sbpteBVjEyW4M6P38SM4",
		"0a66FPlQojQPT28qLEI952",
		"3oi79iqWmUfOObQ0MOw3xF",
		"2nNvk9siGRLiWP2RV0XDW2",
		"4d83G18cx4DDJMPGE9BB4M",
		"43nqv4QZLdroszZ03wKCCh",
		"58E4qtpkOmMqbJxHM1dm6I",
		"6udE9waINs3SYdNoGTotm9",
	}

	-- Slogan loop.
	menuMaid:add(renderStepped:connect("Menu_SloganLoop", function()
		-- Check if we can change the slogan.
		if os.clock() - sloganTimestamp < 5 then
			return
		end

		-- Get random slogan.
		local slogan = string.format("%s - %s", MENU_TITLE, slogans[math.random(1, #slogans)])

		-- Log slogan.
		window:SetWindowTitle(slogan)

		-- Update timestamp.
		sloganTimestamp = os.clock()
	end))

	-- Configure Library.
	Library.ToggleKeybind = Options.MenuKeybind

	-- Load auto-load config.
	SaveManager:LoadAutoloadConfig()

	-- Log menu initialization.
	Logger.warn("Menu initialized.")
end

---Detach menu.
function Menu.detach()
	menuMaid:clean()

	Library:Unload()

	Logger.warn("Menu detached.")
end

-- Return Menu module.
return Menu
