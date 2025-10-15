-- Wipe module.
local Wipe = {}

-- Constants.
local LOBBY_PLACE_ID = 4111023553
local FRAGMENTS_OF_SELF_POS = Vector3.new(2910.00, 1133.03, 1474.00)

---@module Features.Game.Interactions
local Interactions = require("Features/Game/Interactions")

---@module Utility.PersistentData
local PersistentData = require("Utility/PersistentData")

---@module Utility.Finder
local Finder = require("Utility/Finder")

---@module Game.ServerHop
local ServerHop = require("Game/ServerHop")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Debugging mode.
local DEBUGGING_MODE = true

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")

---Telemetry log.
local function telemetryLog(...)
	if not DEBUGGING_MODE then
		return
	end

	Logger.warn(...)
end

---Wait until we're in the fragments of self area.
function Wipe.pwait()
	local wdata = PersistentData.get("wdata")
	if not wdata then
		return error("No wipe data set in PersistentData.")
	end

	local startTimestamp = os.clock()

	while task.wait() do
		if os.clock() - startTimestamp >= 30 then
			return ServerHop.hop(wdata.slot, true)
		end

		if Finder.near(FRAGMENTS_OF_SELF_POS, 500) then
			break
		end
	end
end

---Process all items we need to pass down.
function Wipe.pitems()
	local wdata = PersistentData.get("wdata")
	if not wdata then
		return error("No wipe data set in PersistentData.")
	end

	local npcs = workspace:WaitForChild("NPCs")
	local hippocampusPool = npcs:WaitForChild("Hippocampal Pool")

	for _, name in next, wdata.weapons do
		local weapon = Finder.weweapon(name)
		if not weapon then
			continue
		end

		Interactions.etool(weapon)

		Interactions.interact(hippocampusPool, {
			{ choice = "[Inspect]" },
			{ choice = "[Pass down item]" },
			{ exit = true },
		}, true)
	end
end

---Start the process for wiping a slot in the depths.
function Wipe.depths()
	-- Request start.
	local requests = replicatedStorage:WaitForChild("Requests")
	local startMenu = requests:WaitForChild("StartMenu")
	local start = startMenu:WaitForChild("Start")

	telemetryLog("(Depths) Requesting start.")

	start:FireServer()

	-- Wait until our character is in the fragments of self area.
	Wipe.pwait()

	-- Look for people in the Fragments of Self area.
	telemetryLog("(Depths) Looking for anyone in the Fragments of Self area.")

	local wdata = PersistentData.get("wdata")
	if not wdata then
		return error("No wipe data set in PersistentData.")
	end

	if Finder.pnear(FRAGMENTS_OF_SELF_POS, 500) then
		return ServerHop.hop(wdata.slot, true)
	end

	-- Process items.
	Wipe.pitems()

	-- Interact with Self NPC.
	local npcs = workspace:WaitForChild("NPCs")
	local selfNpc = npcs:WaitForChild("Self")

	telemetryLog("(Depths) Teleporting and interacting with Self NPC.")

	Interactions.interact(selfNpc, {
		{ choice = "[The End]" },
	}, true)

	telemetryLog("(Depths) Wiped slot. Server hopping after removing marker.")

	-- Add or remove markers.
	PersistentData.set("wdata", nil)

	if PersistentData.get("efdata") then
		PersistentData.stf("efdata", "wiped", true)
	end

	-- Server hop.
	ServerHop.hop(wdata.slot, true)
end

---Start the process for wiping a slot in the lobby.
function Wipe.lobby()
	telemetryLog("(Lobby) (Step 1) Wiping slot in lobby.")

	-- Keep attempting to wipe the slot until successful.
	local requests = replicatedStorage:WaitForChild("Requests")
	local wipeSlot = requests:WaitForChild("WipeSlot")

	local wdata = PersistentData.get("wdata")
	if not wdata then
		return error("No wipe data set in PersistentData.")
	end

	repeat
		task.wait()
	until wipeSlot:InvokeServer(wdata.slot)

	telemetryLog("(Lobby) (Step 2) Wiped slot. Server hopping.")

	-- Server hop.
	ServerHop.hop(wdata.slot, false)
end

---Invoke a wipe for a specific slot.
---@param slot string The data slot to wipe.
---@param weapons string[]? Optional items to keep. Does not handle any validation.
function Wipe.invoke(slot, weapons)
	-- Mark slot.
	PersistentData.set("wdata", {
		slot = slot,
		weapons = weapons or {},
	})

	telemetryLog("(Invoke) (Step 1) Marked slot %s in data.", slot)

	-- If we're in the lobby, continue there.
	if game.PlaceId == LOBBY_PLACE_ID then
		return Wipe.lobby()
	end

	-- Otherwise, return to the lobby first.
	return ServerHop.rlobby()
end

-- Return Wipe module.
return Wipe
