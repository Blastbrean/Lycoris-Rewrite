---@module Utility.PersistentData
local PersistentData = require("Utility/PersistentData")

---@module Utility.Table
local Table = require("Utility/Table")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- ServerHop module.
---@todo: Add a fallback if there are no available servers.
local ServerHop = {}

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local teleportService = game:GetService("TeleportService")
local runService = game:GetService("RunService")

-- Constants.
local LOBBY_PLACE_ID = 4111023553
local DEBUGGING_MODE = true

-- Last retry.
local lastRetry = nil

-- Current data state.
local currentData = nil

-- Current server we're trying to connect to.
local currentServer = nil

---Telemetry log.
local function telemetryLog(...)
	if not DEBUGGING_MODE then
		return
	end

	Logger.warn(...)
end

---Get the blacklist list.
---@return table
local function getBlacklist()
	local blacklist = PersistentData.get("sblacklist") or {}

	-- Check for any entries that have been older than 5 minutes.
	for key, value in next, blacklist do
		if tick() - value < 300 then
			continue
		end

		telemetryLog("(%s) Removed old entry (%s) from server blacklist.", tostring(key), tostring(value))

		blacklist[key] = nil
	end

	-- Set the new table.
	PersistentData.set("sblacklist", blacklist)

	return blacklist
end

---Return filtered server data.
local function getFilteredData()
	-- Get the blacklist.
	local blacklist = getBlacklist()

	-- Remove blacklisted servers from our data.
	for idx, server in next, currentData do
		local found, _ = Table.find(blacklist, function(id)
			return id == server.id
		end)

		if not found then
			continue
		end

		telemetryLog("(%s) Removed blacklisted server from available servers.", tostring(server.id))

		table.remove(currentData, idx)
	end

	-- Sort data.
	table.sort(currentData, function(first, second)
		return first.players < second.players
	end)

	-- Return filtered data.
	return currentData
end

---Add to the blacklist.
---@param id string The server ID to add to the blacklist.
local function addBlacklist(id)
	local blacklist = getBlacklist()

	blacklist[id] = tick()

	PersistentData.set("sblacklist", blacklist)
end

---Update ServerHopping module. This continously attempts to try the server you want to connect to.
local function updateServerHopping()
	if not currentData or not currentServer then
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

	local pickServer = startMenu:FindFirstChild("PickServer")
	if not pickServer then
		return
	end

	if lastRetry and os.clock() - lastRetry <= 1.0 then
		return
	end

	lastRetry = os.clock()

	pickServer:FireServer(currentServer.id)
end

---On teleport failure.
local function onTeleportFailure(...)
	telemetryLog(
		"(%s) Teleport to server failed. Blacklisting it.",
		tostring(currentServer and currentServer.id or "N/A")
	)

	addBlacklist(currentServer.id)

	local filteredData = getFilteredData()
	if not filteredData or #filteredData == 0 then
		return error("No available servers found to hop to.")
	end

	local newServer = table.remove(filteredData, 1)
	if not newServer then
		return error("No available servers found to hop to.")
	end

	telemetryLog(
		"(%s) Found new server with %d player(s) and now attempting to teleport there.",
		tostring(newServer.id),
		newServer.players
	)

	currentServer = newServer
end

---Wait for filtered server data.
---@param slot string The data slot to use.
local function waitForFilteredData(slot)
	local servers = replicatedStorage:WaitForChild("Servers")
	local requests = replicatedStorage:WaitForChild("Requests")
	local showServers = requests:WaitForChild("ShowServers")
	local connection = nil

	-- Pick a slot to invoke a server list update.
	local startMenu = requests:WaitForChild("StartMenu")
	local pickSlot = startMenu:WaitForChild("PickSlot")

	pickSlot:FireServer(slot)

	-- Set current data to nil.
	currentData = nil

	-- Wait for the server to update the list.
	connection = showServers.OnClientEvent:Connect(function(luminant)
		-- Get the luminant servers.
		local luminantServers = servers:FindFirstChild(luminant)
		if not luminantServers then
			return
		end

		currentData = {}

		-- Scrape server data.
		for _, instance in next, luminantServers:GetChildren() do
			if not instance:IsA("Folder") then
				continue
			end

			local playerCount = instance:FindFirstChild("NumPlayers")
			if not playerCount or not playerCount:IsA("IntValue") then
				continue
			end

			currentData[#currentData + 1] = {
				id = instance.Name,
				players = playerCount.Value,
			}
		end
	end)

	-- Wait until we have data.
	repeat
		task.wait()
	until currentData

	-- Disconnect.
	connection:Disconnect()
	connection = nil

	-- Return filtered data.
	return getFilteredData()
end

---Handle lobby state.
function ServerHop.lobby()
	local shslot = PersistentData.get("shslot")
	if not shslot then
		return error("No server hop slot set in PersistentData.")
	end

	-- Wait for server data.
	telemetryLog("(%s) Waiting for filtered server data.", tostring(shslot))

	local data = waitForFilteredData(shslot)
	if not data or #data == 0 then
		return error("No available servers found to hop to.")
	end

	local bestServer = table.remove(data, 1)
	if not bestServer then
		return error("No available servers found to hop to.")
	end

	-- Update current server.
	telemetryLog(
		"(%s) Found server with %d player(s) and placed handlers.",
		tostring(bestServer.id),
		bestServer.players
	)

	currentServer = bestServer

	-- Place server fail fallback.
	teleportService.TeleportInitFailed:Connect(onTeleportFailure)

	-- Place teleport update handler.
	runService.PreRender:Connect(updateServerHopping)
end

---Return to the lobby.
function ServerHop.rlobby()
	-- Log.
	telemetryLog("Returning to lobby.")

	-- Fire the return to menu request.
	local requests = replicatedStorage:WaitForChild("Requests")
	local returnToMenu = requests:WaitForChild("ReturnToMenu")
	local playerGui = players.LocalPlayer:WaitForChild("PlayerGui")

	while task.wait() do
		returnToMenu:FireServer()

		local prompt = playerGui:FindFirstChild("ChoicePrompt")
		local choicePrompt = prompt and prompt:FindFirstChild("Choice")

		if not choicePrompt then
			continue
		end

		choicePrompt:FireServer(true)
	end
end

---Server hop. By default, this will look for the lowest population server.
---@param slot string The data slot to use.
---@param blacklist boolean If true, we will blacklist the current server.
function ServerHop.hop(slot, blacklist)
	-- Set the server hop slot in persistent data.
	PersistentData.set("shslot", slot)

	telemetryLog("(%s, %s) Hopping to new server.", tostring(slot), tostring(blacklist))

	-- Blacklist the current server if needed.
	if blacklist then
		local blacklisted = getBlacklist()

		blacklisted[slot] = tick()

		PersistentData.set("sblacklist", blacklisted)
	end

	-- Start the process for the lobby if we're already there.
	if game.PlaceId == LOBBY_PLACE_ID then
		return ServerHop.lobby()
	end

	-- Return to the lobby.
	return ServerHop.rlobby()
end

-- Return ServerHop module.
return ServerHop
