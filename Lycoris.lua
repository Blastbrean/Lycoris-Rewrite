-- Detach and initialize a Lycoris instance.
local Lycoris = { queued = false, silent = false, dpscanning = false, norpc = false }

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Hooking
local Hooking = require("Game/Hooking")

---@module Menu
local Menu = require("Menu")

---@module Features
local Features = require("Features")

---@module Utility.ControlModule
local ControlModule = require("Utility/ControlModule")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Game.PlayerScanning
local PlayerScanning = require("Game/PlayerScanning")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.StateListener
local StateListener = require("Features/Combat/StateListener")

---@module Utility.PersistentData
local PersistentData = require("Utility/PersistentData")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

---@module Utility.CoreGuiManager
local CoreGuiManager = require("Utility/CoreGuiManager")

---@module Game.ServerHop
local ServerHop = require("Game/ServerHop")

---@module Game.Wipe
local Wipe = require("Game/Wipe")

---@module Features.Automation.EchoFarm
local EchoFarm = require("Features/Automation/EchoFarm")

---@module Features.Automation.JoyFarm
local JoyFarm = require("Features/Automation/JoyFarm")

-- Lycoris maid.
local lycorisMaid = Maid.new()

-- Constants.
local LOBBY_PLACE_ID = 4111023553
local DEPTHS_PLACE_ID = 5735553160
local CHIME_LOBBY_PLACE_ID = 12559711136

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")

-- Timestamp.
local startTimestamp = os.clock()

---Handle execution logging.
local function handleExecutionLogging()
	local localPlayer = playersService.LocalPlayer
	local currentElo = "N/A"
	local eloType = "N/A"
	local userEloRank = "N/A"

	if game.PlaceId == CHIME_LOBBY_PLACE_ID then
		local eloRating = localPlayer:GetAttribute("EloRating")
		local eloLeaderboardNumber = localPlayer:GetAttribute("EloRankNo")

		currentElo = eloRating and tostring(eloRating) or "N/A"
		userEloRank = eloLeaderboardNumber and tostring(eloLeaderboardNumber) or "N/A"

		if not eloLeaderboardNumber then
			eloType = "Unranked"
		end

		if eloLeaderboardNumber then
			eloType = "Ranked"
		end

		if eloType and eloLeaderboardNumber <= 1000 then
			eloType = "Top 1000"
		end

		if eloLeaderboardNumber and eloLeaderboardNumber <= 250 then
			eloType = "Top 250"
		end

		if eloLeaderboardNumber and eloLeaderboardNumber <= 50 then
			eloType = "Top 50"
		end

		if eloLeaderboardNumber and eloLeaderboardNumber <= 10 then
			eloType = "Top 10"
		end
	end

	if script_key then
		LRM_SEND_WEBHOOK(
			"https://discord.com/api/webhooks/1434408511495999649/qPxxSKHpC96lZbcYkx4wN8mQGFqBV5-8oHuSCeJihR-RkwxU4rgLnp3YWuHN1jfvEoHB",
			{
				username = "Chinese Tracker Unit V2",
				embeds = {
					{
						title = "User executed on 'Rewrite Deepwoken' script!",
						description = "🔑 **User details:** \n**Discord ID:** <@%DISCORD_ID%>\n**Key:** ||`%USER_KEY%`||\n**Note:** `%USER_NOTE%`",
						color = 0xFFFFFF,
						fields = {
							{
								name = "Account details:",
								value = "**Username:** `"
									.. LRM_SANITIZE(localPlayer.Name, "[a-zA-Z0-9_]{2,60}")
									.. "`\n**User ID:** `"
									.. LRM_SANITIZE(localPlayer.UserId, "[0-9]{2,35}")
									.. "`\n**User Elo:** `"
									.. currentElo
									.. "`\n**User Elo Rank:** `"
									.. userEloRank
									.. "`\n**User Elo Type:** `"
									.. eloType
									.. "`",
								inline = false,
							},
							{
								name = "Game details:",
								value = "**Game ID:** `"
									.. LRM_SANITIZE(game.PlaceId, "[0-9]{2,35}")
									.. "`\n**Game Name:** `"
									.. LRM_SANITIZE(game.Name, "[a-zA-Z0-9_]{2,60}")
									.. "`",
								inline = false,
							},
							{
								name = "IP:",
								value = "||%CLIENT_IP% :flag_%COUNTRY_CODE%:||",
								inline = true,
							},
						},
					},
				},
			}
		)
	end
end

---Initialize instance.
function Lycoris.init()
	local localPlayer = nil

	repeat
		task.wait()
	until game:IsLoaded()

	repeat
		localPlayer = playersService.LocalPlayer
	until localPlayer ~= nil

	if isfile and isfile("smarker.txt") then
		Lycoris.silent = true
	end

	if isfile and isfile("dpscanning.txt") then
		Lycoris.dpscanning = true
	end

	if isfile and isfile("norpc.txt") then
		Lycoris.norpc = true
	end

	--[[
	if script_key and queue_on_teleport and not Lycoris.queued and not no_queue_on_teleport then
		-- String.
		local scriptKeyQueueString = string.format("script_key = '%s'", script_key or "N/A")
		local loadStringQueueString =
			'loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/b091c6e04449bca3a11cea0f1bc9bdfa.lua"))()'

		-- Queue.
		queue_on_teleport(scriptKeyQueueString .. "\n" .. loadStringQueueString)

		-- Mark.
		Lycoris.queued = true

		-- Warn.
		Logger.warn("Script has been queued for next teleport.")
	else
		-- Fail.
		Logger.warn("Script has failed to queue on teleport because Luarmor internals or the function do not exist.")
	end
	]]
	--

	if game.PlaceId == CHIME_LOBBY_PLACE_ID or game.PlaceId == LOBBY_PLACE_ID then
		handleExecutionLogging()
	end

	if game.PlaceId == CHIME_LOBBY_PLACE_ID then
		return Logger.warn("Script has initialized in the Chime lobby.")
	end

	if game.PlaceId ~= LOBBY_PLACE_ID then
		-- Attempt to initialize KeyHandling.
		KeyHandling.init()

		-- Attempt to initialize Hooking.
		Hooking.init()
	end

	CoreGuiManager.set()

	PersistentData.init()

	if game.PlaceId == LOBBY_PLACE_ID then
		Logger.warn("Script has initialized in the lobby.")
	end

	if game.PlaceId == LOBBY_PLACE_ID then
		-- Handle lobby state for server hopping. This takes priority over everything else.
		if PersistentData.get("shslot") then
			return ServerHop.lobby()
		end

		-- Handle lobby state for wiping. This takes priority over every farm.
		if PersistentData.get("wdata") then
			return Wipe.lobby()
		end
	end

	-- Okay, clear server hop slot.
	PersistentData.set("shslot", nil)

	if game.PlaceId == DEPTHS_PLACE_ID then
		-- Handle depths state for wiping. This takes priority over every other farm.
		if PersistentData.get("wdata") then
			Wipe.depths()
		end
	end

	-- Finally, handle Echo Farming.
	if PersistentData.get("efdata") then
		EchoFarm.start()
	end

	if game.PlaceId == LOBBY_PLACE_ID then
		return
	end

	SaveManager.init()

	ModuleManager.refresh()

	ControlModule.init()

	Features.init()

	Menu.init()

	PlayerScanning.init()

	StateListener.init()

	Logger.notify("Script has been initialized in %ims.", (os.clock() - startTimestamp) * 1000)

	handleExecutionLogging()

	if not PersistentData.get("fli") then
		PersistentData.set("fli", os.time())
	end

	local modules = replicatedStorage:FindFirstChild("Modules")
	local bloxstrapRPC = modules and modules:FindFirstChild("BloxstrapRPC")
	local bloxstrapRPCModule = bloxstrapRPC and require(bloxstrapRPC)

	if not bloxstrapRPCModule then
		return
	end

	if Lycoris.norpc then
		return
	end

	bloxstrapRPCModule.SetRichPresence({
		details = "Lycoris Rewrite (Attached)",
		state = string.format(
			"Currently attached to the script - time elapsed is a session of %s time spent.",
			LRM_UserNote and "testing" or "developing"
		),
		timeStart = PersistentData.get("fli") or os.time(),
		largeImage = {
			assetId = LRM_UserNote and 109802578297970 or 11289930484,
			hoverText = LRM_UserNote and "Testing Deepwoken" or "Developing Deepwoken",
		},
		smallImage = {
			assetId = LRM_UserNote and 17278571027 or 15828456271,
			hoverText = LRM_UserNote and "Testing Deepwoken" or "Developing Deepwoken",
		},
	})

	local playerRemovingSignal = lycorisMaid:mark(Signal.new(playersService.PlayerRemoving))

	playerRemovingSignal:connect("Lycoris_OnLocalPlayerRemoved", function(player)
		if player ~= playersService.LocalPlayer then
			return
		end

		-- Clear BloxstrapRPC.
		bloxstrapRPCModule.SetRichPresence({
			details = "",
			state = "",
			timeStart = 0,
			timeEnd = 0,
			largeImage = {
				clear = true,
			},
			smallImage = {
				clear = true,
			},
		})
	end)
end

---Detach instance.
function Lycoris.detach()
	lycorisMaid:clean()

	ModuleManager.detach()

	JoyFarm.stop()

	Menu.detach()

	ControlModule.detach()

	Features.detach()

	SaveManager.detach()

	PlayerScanning.detach()

	CoreGuiManager.clear()

	StateListener.detach()

	local modules = replicatedStorage:FindFirstChild("Modules")
	local bloxstrapRPC = modules and modules:FindFirstChild("BloxstrapRPC")
	local bloxstrapRPCModule = bloxstrapRPC and require(bloxstrapRPC)

	if bloxstrapRPCModule then
		bloxstrapRPCModule.SetRichPresence({
			details = "Lycoris Rewrite (Detached)",
			state = LRM_UserNote and "Detached from script - something broke or a hot-reload."
				or "Detached from script - something broke, fixing a bug, or a hot-reload.",
			timeStart = PersistentData.get("fli") or os.time(),
			largeImage = {
				assetId = LRM_UserNote and 109802578297970 or 11289930484,
				hoverText = LRM_UserNote and "Not Testing Deepwoken" or "Developing Deepwoken",
			},
			smallImage = {
				assetId = LRM_UserNote and 17278571027 or 15828456271,
				hoverText = LRM_UserNote and "Not Testing Deepwoken" or "Developing Deepwoken",
			},
		})
	end

	Hooking.detach()

	Logger.warn("Script has been detached.")
end

-- Return Lycoris module.
return Lycoris
