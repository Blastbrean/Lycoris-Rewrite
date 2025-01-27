---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.OriginalStore
local OriginalStore = require("Utility/OriginalStore")

---@module Utility.OriginalStoreManager
local OriginalStoreManager = require("Utility/OriginalStoreManager")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Entitites
local Entitites = require("Utility/Entitites")

-- Monitoring module.
local Monitoring = { subject = nil, seen = {} }

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local monitoringMaid = Maid.new()
local spectateMaid = Maid.new()

-- Original stores.
local cameraSubject = spectateMaid:mark(OriginalStore.new())

-- Original store managers.
local showHiddenMap = spectateMaid:mark(OriginalStoreManager.new())

---Get leaderboard data.
---@return table?, function?
local function getLeaderboardData()
	for _, con in next, getconnections(players.PlayerRemoving) do
		local func = con.Function
		if not func then
			continue
		end

		local info = debug.getinfo(func)
		if info.name ~= nil and info.name ~= "" then
			continue
		end

		local constants = debug.getconstants(func)
		if #constants ~= 1 or constants[1] ~= "Destroy" then
			continue
		end

		local upvalues = debug.getupvalues(func)
		if not upvalues then
			continue
		end

		return upvalues[1], upvalues[2]
	end

	return nil
end

---On spectate input began.
---@param player Player
---@param input InputObject
local function onSpectateInputBegan(player, input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local character = player.Character
	if not character then
		return Logger.notify("Failed to spectate %s because their character does not exist.", player.Name)
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return Logger.notify("Failed to spectate %s because they are not loaded in.", player.Name)
	end

	local shouldUpdateSubject = Monitoring.subject ~= humanoidRootPart and players.LocalPlayer ~= player

	Monitoring.subject = shouldUpdateSubject and humanoidRootPart or nil

	if shouldUpdateSubject then
		Logger.notify("Started spectating player %s.", player.name)
	else
		Logger.notify("Reset spectating camera subject.")
	end
end

---Update spectating.
---@todo: Start streaming around the player when spectating.
local function updateSpectating()
	local leaderboardMap, updateLeaderboard = getLeaderboardData()
	if not leaderboardMap or not updateLeaderboard then
		return cameraSubject:restore()
	end

	for player, frame in next, leaderboardMap do
		local inputBegan = Signal.new(frame.InputBegan)
		local label = string.format("Monitoring_InputBegan%s", player.Name)

		if Configuration.expectToggleValue("ShowHiddenPlayers") then
			showHiddenMap:add(frame, "Visible", true)
		else
			---@todo: STOP! STOP! Restoring will fuck up the leaderboard here. We need proper restore functions instead of defaulting to map.
			showHiddenMap:restore()
		end

		if spectateMaid[frame] then
			continue
		end

		spectateMaid[frame] = inputBegan:connect(label, function(input)
			onSpectateInputBegan(player, input)
		end)
	end

	if Monitoring.subject then
		cameraSubject:set(workspace.CurrentCamera, "CameraSubject", Monitoring.subject)
	else
		cameraSubject:restore()
	end
end

---Update player proximity.
local function updatePlayerProximity()
	local proximityRange = Configuration.expectOptionValue("PlayerProximityRange") or 350
	local playersInRange = Entitites.getPlayersInRange(proximityRange)
	if not playersInRange then
		return
	end

	local backpack = players.LocalPlayer:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	for player, _ in next, Monitoring.seen do
		local isInPlayerRange = table.find(playersInRange, player)

		if isInPlayerRange then
			continue
		end

		Logger.notify("%s is now outside of your proximity radius.", player.Name)

		Monitoring.seen[player] = nil
	end

	for _, player in next, playersInRange do
		if Monitoring.seen[player] then
			continue
		end

		if
			Configuration.expectToggleValue("PlayerProximityVW")
			and not backpack:FindFirstChild("Talent:Voidwalker Contract")
		then
			continue
		end

		if Configuration.expectToggleValue("PlayerProximityBeep") then
			local beepSound = Instance.new("Sound", game:GetService("CoreGui"))
			beepSound.SoundId = "rbxassetid://100849623977896"
			beepSound.PlaybackSpeed = 1
			beepSound.Volume = Configuration.expectOptionValue("PlayerProximityBeepVolume") or 0.1
			beepSound.PlayOnRemove = true
			beepSound:Destroy()
		end

		Logger.notify("%s entered your proximity radius of %i studs.", player.Name, proximityRange)

		Monitoring.seen[player] = true
	end
end

---Update monitoring.
local function updateMonitoring()
	if Configuration.expectToggleValue("PlayerSpectating") then
		updateSpectating()
	else
		spectateMaid:clean()
	end

	if Configuration.expectToggleValue("PlayerProximity") then
		updatePlayerProximity()
	end
end

---Initialize monitoring.
function Monitoring.init()
	monitoringMaid:add(renderStepped:connect("Monitoring_OnRenderStepped", updateMonitoring))
end

---Detach spectating.
function Monitoring.detach()
	monitoringMaid:clean()
	spectateMaid:clean()
	showHiddenMap:restore()
end

-- Return Monitoring module.
return Monitoring
