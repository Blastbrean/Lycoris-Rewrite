-- Detach and initialize a Lycoris instance.
local Lycoris = { queued = false, silent = false, dpscanning = false }

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

---@module Features.Combat.EffectListener
local EffectListener = require("Features/Combat/EffectListener")

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

-- Lycoris maid.
local lycorisMaid = Maid.new()

-- Constants.
local LOBBY_PLACE_ID = 4111023553

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")

-- Timestamp.
local startTimestamp = os.clock()

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

	if script_key and queue_on_teleport and not Lycoris.queued and not no_queue_on_teleport then
		-- String.
		local scriptKeyQueueString = string.format("script_key = '%s'", script_key or "N/A")
		local loadStringQueueString =
			'loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/0216eb5f95556e660be56009441409ae.lua"))()'

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

	if game.PlaceId ~= LOBBY_PLACE_ID then
		-- Attempt to initialize KeyHandling.
		KeyHandling.init()

		-- Attempt to initialize Hooking.
		Hooking.init()
	end

	CoreGuiManager.set()

	PersistentData.init()

	if game.PlaceId == LOBBY_PLACE_ID then
		return Logger.warn("Script has initialized in the lobby.")
	end

	InputClient.cache()

	SaveManager.init()

	ModuleManager.refresh()

	ControlModule.init()

	Features.init()

	Menu.init()

	PlayerScanning.init()

	EffectListener.init()

	Logger.notify("Script has been initialized in %ims.", (os.clock() - startTimestamp) * 1000)

	if not PersistentData.get("fli") then
		PersistentData.set("fli", os.time())
	end

	if not PersistentData.get("lus") then
		PersistentData.set("lus", playersService.LocalPlayer:GetAttribute("DataSlot"))
	end

	local modules = replicatedStorage:FindFirstChild("Modules")
	local bloxstrapRPC = modules and modules:FindFirstChild("BloxstrapRPC")
	local bloxstrapRPCModule = bloxstrapRPC and require(bloxstrapRPC)

	if not bloxstrapRPCModule then
		return
	end

	bloxstrapRPCModule.SetRichPresence({
		details = "Lycoris Rewrite (Attached)",
		state = string.format(
			"Currently attached to the script - time elapsed is a session of %s time spent.",
			armorshield and "testing" or "developing"
		),
		timeStart = PersistentData.get("fli") or os.time(),
		largeImage = {
			assetId = armorshield and 13029433631 or 11289930484,
			hoverText = armorshield and "Testing Deepwoken" or "Developing Deepwoken",
		},
		smallImage = {
			assetId = armorshield and 11809086414 or 15828456271,
			hoverText = armorshield and "Testing Deepwoken" or "Developing Deepwoken",
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

	Menu.detach()

	ControlModule.detach()

	Features.detach()

	SaveManager.detach()

	PlayerScanning.detach()

	CoreGuiManager.clear()

	EffectListener.detach()

	local modules = replicatedStorage:FindFirstChild("Modules")
	local bloxstrapRPC = modules and modules:FindFirstChild("BloxstrapRPC")
	local bloxstrapRPCModule = bloxstrapRPC and require(bloxstrapRPC)

	if bloxstrapRPCModule then
		bloxstrapRPCModule.SetRichPresence({
			details = "Lycoris Rewrite (Detached)",
			state = armorshield and "Detached from script - something broke or a hot-reload."
				or "Detached from script - something broke, fixing a bug, or a hot-reload.",
			timeStart = PersistentData.get("fli") or os.time(),
			largeImage = {
				assetId = armorshield and 90216003739455 or 11289930484,
				hoverText = armorshield and "Not Testing Deepwoken" or "Developing Deepwoken",
			},
			smallImage = {
				assetId = armorshield and 13086087956 or 15828456271,
				hoverText = armorshield and "Not Testing Deepwoken" or "Developing Deepwoken",
			},
		})
	end

	Hooking.detach()

	Logger.warn("Script has been detached.")
end

-- Return Lycoris module.
return Lycoris
