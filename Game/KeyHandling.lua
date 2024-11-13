-- KeyHandler related stuff is handled here.
local KeyHandling = {}

-- Fetch environment.
local environment = getgenv and getgenv() or _G
if not environment then
	return
end

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Instances.
local modules = replicatedStorage:WaitForChild("Modules")
local clientModuleManager = modules:WaitForChild("ClientManager")
local persistence = modules:WaitForChild("Persistence")

-- Modules.
local integrity = persistence:WaitForChild("Integrity")
local keyHandler = clientModuleManager:WaitForChild("KeyHandler")

---Get the stack of the KeyHandler module.
---@return table
function KeyHandling.getStack()
	local keyHandlerModule = require(keyHandler)
	return debug.getupvalue(getrawmetatable(debug.getupvalue(keyHandlerModule, 8)).__index, 1)[1][1]
end

---Get the Heaven and Hell remotes.
---@return Instance, Instance
function KeyHandling.getAntiCheatRemotes()
	local stack = KeyHandling.getStack()
	return stack[86], stack[85]
end

---Get remote from a specific remote name.
---@param remoteName string
---@return Instance|nil
function KeyHandling.getRemote(remoteName)
	local integrityModule = require(integrity)
	local keyHandlerModule = require(keyHandler)

	if not integrityModule or not keyHandlerModule then
		return
	end

	local keyHandlerKey = integrityModule()
	local keyHandlerObject = keyHandlerModule()

	if not keyHandlerKey or not keyHandlerObject then
		return
	end

	local khGetRemote = keyHandlerObject[1]

	if not khGetRemote then
		return
	end

	return khGetRemote(remoteName, keyHandlerKey)
end

---Return the "khGetRemote" function.
---@return function
function KeyHandling.rawGetRemote()
	local keyHandlerModule = require(keyHandler)
	if not keyHandlerModule then
		return
	end

	local keyHandlerObject = keyHandlerModule()
	if not keyHandlerObject then
		return
	end

	return keyHandlerObject[1]
end

-- Return KeyHandling module.
return KeyHandling
