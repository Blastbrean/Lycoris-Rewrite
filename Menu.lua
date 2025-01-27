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
local stats = game:GetService("Stats")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local menuMaid = Maid.new()

-- Constants.
local MENU_TITLE = "Linoria V2 | Deepwoken"

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

	-- Update watermark.
	menuMaid:add(renderStepped:connect("Menu_WatermarkUpdate", function()
		-- Get stats.
		local networkStats = stats:FindFirstChild("Network")
		local workspaceStats = stats:FindFirstChild("Workspace")
		local performanceStats = stats:FindFirstChild("PerformanceStats")
		local serverStats = networkStats and networkStats:FindFirstChild("ServerStatsItem") or nil

		-- Get data.
		local pingData = serverStats and serverStats:FindFirstChild("Data Ping") or nil
		local heartbeatData = workspaceStats and workspaceStats:FindFirstChild("Heartbeat") or nil
		local cpuData = performanceStats and performanceStats:FindFirstChild("CPU") or nil
		local gpuData = performanceStats and performanceStats:FindFirstChild("GPU") or nil

		-- Set values.
		local ping = pingData and pingData:GetValue() or 0.0
		local fps = heartbeatData and heartbeatData:GetValue() or 0.0
		local cpu = cpuData and cpuData:GetValue() or 0.0
		local gpu = gpuData and gpuData:GetValue() or 0.0

		-- Set watermark.
		Library:SetWatermark(string.format("%s | %.2fms | %.1f/s | %.1fms | %.1fms", MENU_TITLE, ping, fps, cpu, gpu))
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
