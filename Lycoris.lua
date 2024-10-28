-- Detach and initialize a Lycoris instance.
local Lycoris = {}

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Hooking
local Hooking = require("Game/Hooking")

---@module Menu
local Menu = require("Menu")

---@module Features
local Features = require("Features")

-- Services.
local memStorageService = game:GetService("MemStorageService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")

-- Constants.
local LOBBY_PLACE_ID = 4111023553

-- Handle server hop while in the main menu.
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

-- Handle start menu.
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

	local scriptKeyQueueString = string.format("script_key = '%s'", lycoris_init.key)
	local loadStringQueueString =
		'loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/c41b4fcdd3494b59bd6dc042e1bd2967.lua"))()'

	if queue_on_teleport then
		queue_on_teleport(scriptKeyQueueString .. "\n" .. loadStringQueueString)
	else
		Logger.warn("Script has failed to queue on teleport because the function does not exist.")
	end

	Logger.warn("Script has been queued for next teleport.")

	local serverHopSlot = memStorageService:HasItem("ServerHop") and memStorageService:GetItem("ServerHop")
	local serverHopJobId = memStorageService:HasItem("ServerHopJobId") and memStorageService:GetItem("ServerHopJobId")

	if game.PlaceId == LOBBY_PLACE_ID and serverHopSlot and serverHopJobId then
		return handleMainMenuServerHop(serverHopSlot, serverHopJobId)
	end

	Hooking.init()

	Features.init()

	Menu.init()

	if memStorageService:HasItem("HandleStartMenu") then
		handleStartMenu()
	end

	Logger.notify("Script has been initialized.")
end

---Detach instance.
function Lycoris.detach()
	Menu.detach()

	Features.detach()

	Hooking.detach()

	Logger.warn("Script has been detached.")
end

-- Return Lycoris module.
return Lycoris
