-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()

getfenv().PP_SCRAMBLE_NUM = function(...)
	return ...
end

getfenv().PP_SCRAMBLE_STR = function(...)
	return ...
end

getfenv().PP_SCRAMBLE_RE_NUM = function(...)
	return ...
end

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Lycoris
local Lycoris = require("Lycoris")

---Find existing instances and initialize the script.
local function initializeScript()
	-- Check if there's already another instance.
	if shared.Lycoris then
		-- Detach previous instance.
		shared.Lycoris.detach()

		-- Share the previous state.
		Lycoris.queued = shared.Lycoris.queued
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
