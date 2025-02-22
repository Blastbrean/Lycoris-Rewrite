-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

---@todo: Chinese Tracker Unit V2
-- Improvements from the previous version:
-- Obtain all data without the use of the UI & compare with UI (account for Stream Sniper).
-- Collect all possible Deepwoken data including inventory, talents, health, quests, and more.
-- Send this data to the ArmorShield database for further checking.
-- Catch the ban evaders :groan:

-- Initialize ArmorShield globals if they do not exist.
if not lycoris_init then
	lycoris_init = { key = "N/A" }
	lycoris_init.current_role = "N/A"
end

-- Initialize Luraph globals if they do not exist.
if not LPH_OBFUSCATED then
	loadstring([[
		function LPH_NO_VIRTUALIZE(...) return ... end
	]])()
end

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Lycoris
local Lycoris = require("Lycoris")

---Find existing instances and initialize the script.
---@todo: Virtualize parts of the source.
local function initializeScript()
	-- Check if there's already another instance.
	if shared.Lycoris then
		shared.Lycoris.detach()
	end

	-- Re-initialize under the new state.
	shared.Lycoris = Lycoris
	shared.Lycoris.init()
end

---This is called when the initalization errors.
---@param error string
local function onInitializeError(error)
	-- Warn that an error happened while initializing.
	warn("Failed to initialize.")
	warn(error)

	-- Warn traceback.
	warn(debug.traceback())

	-- Detach the current instance.
	Lycoris.detach()
end

-- Safely profile and initialize the script aswell as handle errors.
Profiler.run("Main_InitializeScript", function(...)
	return xpcall(initializeScript, onInitializeError, ...)
end)
