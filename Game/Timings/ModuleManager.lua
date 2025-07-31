-- Module manager.
---@note: All globals get executed first but never ran. This gets set in the global environment of every future module after.
local ModuleManager = { modules = {}, globals = {} }

---@module Utility.Filesystem
local Filesystem = require("Utility/Filesystem")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Timings.Action
local Action = require("Game/Timings/Action")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Utility.Entitites
local Entitites = require("Utility/Entitites")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Game.Timings.PartTiming
local PartTiming = require("Game/Timings/PartTiming")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = require("Features/Combat/Objects/RepeatInfo")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Module filesystem.
local fs = Filesystem.new("Lycoris-Rewrite-Modules")
local gfs = Filesystem.new(fs:append("Globals"))

-- Detach table.
local tdetach = {}

---Load file modules from filesystem.
---@param tfs Filesystem The filesystem to load from.
---@param global boolean Whether we're loading global modules or not.
function ModuleManager.load(tfs, global)
	for _, file in next, tfs:list(false) do
		-- Check if it is .lua.
		if string.sub(file, #file - 3, #file) ~= ".lua" then
			continue
		end

		-- Get string to load.
		local ls = tfs:read(file)

		-- Get function that we can execute.
		local lf, lr = loadstring(ls)
		if not lf then
			Logger.warn("Module file '%s' failed to load due to error '%s' while loading.", file, lr)
			continue
		end

		---@module Features.Combat.Defense
		---@note: For some reason, it broke lol. Returned nil.
		local Defense = require("Features/Combat/Defense")

		-- Set function environment to allow for internal modules.
		getfenv(lf).Timing = Timing
		getfenv(lf).PartTiming = PartTiming
		getfenv(lf).Defense = Defense
		getfenv(lf).Action = Action
		getfenv(lf).InputClient = InputClient
		getfenv(lf).Task = Task
		getfenv(lf).Maid = Maid
		getfenv(lf).Signal = Signal
		getfenv(lf).TaskSpawner = TaskSpawner
		getfenv(lf).Entitites = Entitites
		getfenv(lf).Targeting = Targeting
		getfenv(lf).Logger = Logger
		getfenv(lf).HitboxOptions = HitboxOptions
		getfenv(lf).RepeatInfo = RepeatInfo

		-- Load globals if we should.
		for name, entry in next, (not global) and ModuleManager.globals or {} do
			getfenv(lf)[name] = entry
		end

		-- Run executable function to initialize it.
		local success, result = pcall(lf)
		if not success then
			Logger.warn("Module file '%s' failed to load due to error '%s' while executing.", file, result)
			continue
		end

		if global and typeof(result) ~= "table" then
			Logger.warn("Global module file '%s' is invalid because it does not return a table.", file)
			continue
		end

		-- Output table.
		local output = global and ModuleManager.globals or ModuleManager.modules

		-- Get the result as a function.
		output[string.sub(file, 1, #file - 4)] = result

		-- If this is a global, the result is a table, and it has a detach function, store it for later.
		if typeof(result) == "table" and typeof(result.detach) == "function" then
			tdetach[#tdetach + 1] = result.detach
		end
	end
end

---List loaded modules.
---@return string[]
function ModuleManager.loaded()
	local out = {}

	for file, _ in next, ModuleManager.modules do
		table.insert(out, file)
	end

	return out
end

---Detach functions.
function ModuleManager.detach()
	for _, detach in next, tdetach do
		detach()
	end

	-- Clear detach table.
	tdetach = {}
end

---Refresh ModuleManager.
function ModuleManager.refresh()
	-- Detach all modules.
	ModuleManager.detach()

	-- Reset current list.
	ModuleManager.modules = {}
	ModuleManager.globals = {}

	-- Load all globals in our filesystem.
	ModuleManager.load(gfs, true)

	-- Load all modules in our filesystem.
	ModuleManager.load(fs, false)
end

-- Return ModuleManager module.
return ModuleManager
