-- Detach and initialize a Lycoris instance.
local Lycoris = { queued = false }

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

---@module Features.Visuals.Visuals
local Visuals = require("Features/Visuals/Visuals")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

-- Lycoris maid.
local lycorisMaid = Maid.new()

-- Services.
local memStorageService = game:GetService("MemStorageService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")

-- Constants.
local LOBBY_PLACE_ID = 4111023553

-- Timestamp.
local startTimestamp = os.clock()

---Handle server hop while in the main menu.
---@param serverHopSlot string
---@param serverHopJobId string
local function handleMainMenuServerHop(serverHopSlot, serverHopJobId)
	memStorageService:RemoveItem("ServerHop")

	Logger.warn("Server hopping on slot %s with JobId %s", serverHopSlot, serverHopJobId)

	local localPlayer = playersService.LocalPlayer

	local requests = replicatedStorage:WaitForChild("Requests")
	local startMenu = requests:WaitForChild("StartMenu")

	local start = startMenu:WaitForChild("Start")
	local pickServer = startMenu:WaitForChild("PickServer")

	local slotData = replicatedStorage:WaitForChild("SlotData")
	local slotUserIdData = slotData:WaitForChild(localPlayer.UserId):WaitForChild(serverHopSlot)
	local slotUserIdRealm = slotUserIdData:WaitForChild("Realm").Value

	if slotUserIdRealm == "???" then
		slotUserIdRealm = "EtreanLuminant"
	end

	if slotUserIdRealm:find("The Depths") then
		slotUserIdRealm = "Depths"
	end

	local serversInRealm = replicatedStorage:WaitForChild("Servers"):WaitForChild(slotUserIdRealm)
	local shouldUseJobId = serverHopJobId ~= ""

	if shouldUseJobId and not serversInRealm:FindFirstChild(serverHopJobId, true) then
		return Logger.warn("The JobId %s is not in the realm %s", serverHopJobId, slotUserIdRealm)
	end

	start:FireServer(serverHopSlot, { PrivateTest = false })

	task.wait(0.5)

	if shouldUseJobId then
		pickServer:FireServer(serverHopJobId)
	else
		pickServer:FireServer("none")
	end
end

---Handle start menu.
local function handleStartMenu()
	local localPlayer = playersService.LocalPlayer
	if localPlayer.Character or localPlayer.Character:FindFirstChild("CharacterHandler") then
		return
	end

	local requests = replicatedStorage:FindFirstChild("Requests")
	if not requests then
		return
	end

	local startMenu = requests:FindFirstChild("StartMenu")
	if not startMenu then
		return
	end

	local start = startMenu:FindFirstChild("Start")
	if not start then
		return
	end

	start:FireServer()
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

	if armorshield and queue_on_teleport and not Lycoris.queued then
		-- String.
		local scriptKeyQueueString = string.format("script_key = '%s'", armorshield.key or "N/A")
		local loadStringQueueString =
			'loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/5ac35cc8c071938af640f639b49c629b.lua"))()'

		-- Queue.
		queue_on_teleport(scriptKeyQueueString .. "\n" .. loadStringQueueString)

		-- Mark.
		Lycoris.queued = true

		-- Warn.
		Logger.warn("Script has been queued for next teleport.")
	else
		-- Fail.
		Logger.warn(
			"Script has failed to queue on teleport because ArmorShield internals or the function do not exist."
		)
	end

	if not memStorageService:HasItem("FirstLycorisInitialization") then
		memStorageService:SetItem("FirstLycorisInitialization", os.time())
	end

	local serverHopSlot = memStorageService:HasItem("ServerHop") and memStorageService:GetItem("ServerHop")
	local serverHopJobId = memStorageService:HasItem("ServerHopJobId") and memStorageService:GetItem("ServerHopJobId")
	local inLobbyPlace = game.PlaceId == LOBBY_PLACE_ID

	if inLobbyPlace then
		return (serverHopSlot and serverHopJobId) and handleMainMenuServerHop(serverHopSlot, serverHopJobId)
			or Logger.warn("Script exit initialization early because we are in the lobby.")
	end

	KeyHandling.init()

	Hooking.init()

	InputClient.cache()

	SaveManager.init()

	ModuleManager.refresh()

	ControlModule.init()

	Features.init()

	Menu.init()

	Visuals.start()

	if memStorageService:HasItem("HandleStartMenu") then
		handleStartMenu()
	end

	PlayerScanning.init()

	Logger.notify("Script has been initialized in %ims.", (os.clock() - startTimestamp) * 1000)

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
		timeStart = tonumber(memStorageService:GetItem("FirstLycorisInitialization")) or os.time(),
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

		-- Auto-save.
		SaveManager.autosave()

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

	SaveManager.autosave()

	Menu.detach()

	ControlModule.detach()

	Features.detach()

	PlayerScanning.detach()

	local modules = replicatedStorage:FindFirstChild("Modules")
	local bloxstrapRPC = modules and modules:FindFirstChild("BloxstrapRPC")
	local bloxstrapRPCModule = bloxstrapRPC and require(bloxstrapRPC)

	if bloxstrapRPCModule then
		bloxstrapRPCModule.SetRichPresence({
			details = "Lycoris Rewrite (Detached)",
			state = armorshield and "Detached from script - something broke or a hot-reload."
				or "Detached from script - something broke, fixing a bug, or a hot-reload.",
			timeStart = tonumber(memStorageService:GetItem("FirstLycorisInitialization")) or os.time(),
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
