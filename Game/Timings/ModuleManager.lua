-- Module manager.
local ModuleManager = { modules = {} }

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

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Utility.Entitites
local Entitites = require("Utility/Entitites")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

-- Module filesystem.
local fs = Filesystem.new("Lycoris-Rewrite-Modules")

---List loaded modules.
---@return string[]
function ModuleManager.loaded()
	local out = {}

	for file, _ in next, ModuleManager.modules do
		table.insert(out, file)
	end

	return out
end

---Refresh ModuleManager.
function ModuleManager.refresh()
	-- Reset current list.
	ModuleManager.modules = {}

	-- Load all modules in our filesystem.
	for _, file in next, fs:list(false) do
		-- Check if it is .lua.
		if string.sub(file, #file - 3, #file) ~= ".lua" then
			continue
		end

		-- Get string to load.
		local ls = fs:read(file)

		-- Get function that we can execute.
		local lf, lr = loadstring(ls)
		if not lf then
			Logger.warn("Module file '%s' failed to load due to error '%s' while loading.", file, lr)
			continue
		end

		-- Set function environment to allow for internal modules.
		getfenv(lf).Action = Action
		getfenv(lf).InputClient = InputClient
		getfenv(lf).Task = Task
		getfenv(lf).TaskSpawner = TaskSpawner
		getfenv(lf).Entitites = Entitites
		getfenv(lf).Targeting = Targeting
		getfenv(lf).Logger = Logger

		-- Run executable function to initialize it.
		local success, result = pcall(lf)
		if not success then
			Logger.warn("Module file '%s' failed to load due to error '%s' while executing.", file, result)
			continue
		end

		if typeof(result) ~= "function" then
			Logger.warn("Module file '%s' is invalid because it does not return a function.", file)
			continue
		end

		-- Get the result as a function.
		ModuleManager.modules[string.sub(file, 1, #file - 4)] = result
	end
end

-- Return ModuleManager module.
return ModuleManager
