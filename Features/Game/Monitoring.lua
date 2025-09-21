return LPH_NO_VIRTUALIZE(function()
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

	---@module Utility.CoreGuiManager
	local CoreGuiManager = require("Utility/CoreGuiManager")

	---@module Utility.TaskSpawner
	local TaskSpawner = require("Utility/TaskSpawner")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	---@module Utility.Entitites
	local Entitites = require("Utility/Entitites")

	---@module Game.LeaderboardClient
	local LeaderboardClient = require("Game/LeaderboardClient")

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

	-- Instances.
	local beepSound = CoreGuiManager.imark(Instance.new("Sound"))

	-- Update limiting.
	local lastUpdateTime = os.clock()

	-- Original stores.
	local cameraSubject = spectateMaid:mark(OriginalStore.new())

	-- Original store managers.
	local showHiddenMap = spectateMaid:mark(OriginalStoreManager.new())

	---Fetch name.
	local function fetchName(player)
		local spoofName = Configuration.expectToggleValue("InfoSpoofing")
			and Configuration.expectToggleValue("SpoofOtherPlayers")

		return spoofName and "[REDACTED]"
			or string.format("(%s) %s", player:GetAttribute("CharacterName") or "Unknown Character Name", player.Name)
	end

	---On spectate input began.
	---@param player Player
	---@param input InputObject
	local function onSpectateInputBegan(player, input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		-- Fetch name for player.
		local usedName = fetchName(player)

		-- Get data.
		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return Logger.notify("Failed to spectate '%s' because the local player does not exist.", usedName)
		end

		local character = player.Character
		if not character then
			return Logger.notify("Failed to spectate '%s' because their character does not exist.", usedName)
		end

		local mapPosition = character:GetAttribute("MapPos")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		-- Request a stream if we're able to and we know that they're not loaded in.
		if mapPosition and not humanoidRootPart then
			spectateMaid:add(
				TaskSpawner.spawn(
					"Monitoring_RequestStreamMapPos",
					players.LocalPlayer.RequestStreamAroundAsync,
					players.LocalPlayer,
					mapPosition,
					0.1
				)
			)

			return Logger.notify("Requesting stream for unloaded character '%s' - try again later.", usedName)
		end

		-- Fail because they're *truly* not loaded in.
		if not humanoidRootPart then
			return Logger.notify("Failed to spectate '%s' because they are not loaded in.", usedName)
		end

		local shouldUpdateSubject = Monitoring.subject ~= humanoidRootPart and players.LocalPlayer ~= player

		Monitoring.subject = shouldUpdateSubject and humanoidRootPart or nil

		if shouldUpdateSubject then
			Logger.notify("Started spectating player %s.", usedName)
		else
			Logger.notify("Reset spectating camera subject.")
		end
	end

	---Update spectating.
	local function updateSpectating()
		local leaderboardMap, refreshLeaderboard = LeaderboardClient.gld(), LeaderboardClient.glrf()
		if not leaderboardMap or not refreshLeaderboard then
			return cameraSubject:restore()
		end

		-- Refresh leaderboard state.
		refreshLeaderboard()

		-- Update leaderboard based on state.
		for player, frame in next, leaderboardMap do
			local inputBegan = Signal.new(frame.InputBegan)
			local label = string.format("Monitoring_InputBegan%s", player.Name)

			if Configuration.expectToggleValue("ShowHiddenPlayers") then
				showHiddenMap:add(frame, "Visible", true)
			end

			if spectateMaid[frame] then
				continue
			end

			spectateMaid[frame] = inputBegan:connect(label, function(input)
				onSpectateInputBegan(player, input)
			end)
		end
	end

	---Update player proximity.
	local function updatePlayerProximity()
		local proximityRange = Configuration.expectOptionValue("PlayerProximityRange") or 350
		local playersInRange = Entitites.getPlayersInRange(proximityRange)
		if not playersInRange then
			return
		end

		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		local backpack = localPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		-- Handle monitoring.
		for player, _ in next, Monitoring.seen do
			local isInPlayerRange = table.find(playersInRange, player)
			if isInPlayerRange then
				continue
			end

			local removeNotification = Monitoring.seen[player]

			removeNotification()

			Monitoring.seen[player] = nil
		end

		for _, player in next, playersInRange do
			if Monitoring.seen[player] ~= nil then
				continue
			end

			if
				Configuration.expectToggleValue("PlayerProximityVW")
				and not backpack:FindFirstChild("Talent:Voidwalker Contract")
			then
				continue
			end

			Monitoring.seen[player] =
				Logger.mnnotify("%s entered your proximity radius of %i studs.", fetchName(player), proximityRange)

			if Configuration.expectToggleValue("PlayerProximityBeep") then
				beepSound.SoundId = "rbxassetid://100849623977896"
				beepSound.PlaybackSpeed = 1
				beepSound.Volume = Configuration.expectOptionValue("PlayerProximityBeepVolume") or 0.1
				beepSound:Play()
			end
		end
	end

	---Update subject montioring.
	local function updateSubjectMonitoring()
		-- Set camera subject.
		cameraSubject:set(workspace.CurrentCamera, "CameraSubject", Monitoring.subject)

		if Monitoring.subject ~= nil then
			players.LocalPlayer:AddTag("ForcedSubject")
		else
			players.LocalPlayer:RemoveTag("ForcedSubject")
		end

		-- Request stream.
		spectateMaid:add(
			TaskSpawner.spawn(
				"Monitoring_RequestStreamSpectate",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				Monitoring.subject.Position,
				0.1
			)
		)
	end

	---Update monitoring.
	local function updateMonitoring()
		if Monitoring.subject then
			updateSubjectMonitoring()
		else
			cameraSubject:restore()
		end

		if os.clock() - lastUpdateTime <= 2.0 then
			return
		end

		lastUpdateTime = os.clock()

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
		-- Attach.
		monitoringMaid:add(renderStepped:connect("Monitoring_OnRenderStepped", updateMonitoring))

		-- Log.
		Logger.warn("Monitoring initialized.")
	end

	---Detach spectating.
	function Monitoring.detach()
		-- Clean.
		monitoringMaid:clean()
		spectateMaid:clean()
		showHiddenMap:restore()

		-- Get leaderboard data.
		local refreshLeaderboard = LeaderboardClient.glrf()

		-- Refresh leaderboard.
		if refreshLeaderboard then
			refreshLeaderboard()
		end

		-- Log.
		Logger.warn("Monitoring detached.")
	end

	-- Return Monitoring module.
	return Monitoring
end)()
