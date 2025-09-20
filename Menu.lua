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

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local runService = game:GetService("RunService")
local stats = game:GetService("Stats")
local players = game:GetService("Players")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local menuMaid = Maid.new()

-- Constants.
local MENU_TITLE = "Linoria V2 | Deepwoken"

if LRM_UserNote then
	MENU_TITLE = string.format(
		"(Commit %s) Linoria V2 | Deepwoken First Release",
		string.sub("6b677a0b30a3113820f80e482d09ddbf0b53223f", 1, 6)
	)
end

---Initialize menu.
function Menu.init()
	-- Create window.
	local window = Library:CreateWindow({
		Title = MENU_TITLE,
		Center = true,
		AutoShow = not shared.Lycoris.silent,
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
	SaveManager:SetIgnoreIndexes({
		"Fly",
		"NoClip",
		"Speedhack",
		"InfiniteJump",
		"TweenToObjective",
		"AttachToBack",
	})

	-- Initialize all tabs. Don't initialize them if we have the 'exploit_tester' role.
	CombatTab.init(window)
	BuilderTab.init(window)
	GameTab.init(window)
	VisualsTab.init(window)
	AutomationTab.init(window)
	ExploitTab.init(window)
	LycorisTab.init(window)

	-- Last update.
	local lastUpdate = os.clock()

	-- Update watermark.
	menuMaid:add(renderStepped:connect(
		"Menu_WatermarkUpdate",
		LPH_NO_VIRTUALIZE(function()
			if os.clock() - lastUpdate <= 0.5 then
				return
			end

			lastUpdate = os.clock()

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

			-- Character data.
			local mouse = players.LocalPlayer and players.LocalPlayer:GetMouse()
			local position = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
			local positionFormat = position and string.format("(%.2f, %.2f, %.2f)", position.X, position.Y, position.Z)
				or "N/A"

			-- String.
			local str = string.format("%s | %.2fms | %.1f/s | %.1fms | %.1fms", MENU_TITLE, ping, fps, cpu, gpu)

			if Configuration.expectToggleValue("ShowDebugInformation") then
				str = str .. string.format(" | %s", positionFormat)
				str = str .. string.format(" | %s", mouse and mouse.Target and mouse.Target:GetFullName() or "N/A")
			end

			-- Set watermark.
			Library:SetWatermark(str)
		end)
	))

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
