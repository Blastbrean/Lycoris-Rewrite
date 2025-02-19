-- KeyHandler related stuff is handled here.
local KeyHandling = {}

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Instances.
local modules = replicatedStorage and replicatedStorage:WaitForChild("Modules", 3)
local clientModuleManager = modules and modules:WaitForChild("ClientManager", 3)
local persistence = modules and modules:WaitForChild("Persistence", 3)

-- Modules.
local integrity = persistence and persistence:WaitForChild("Integrity", 3)
local keyHandler = clientModuleManager and clientModuleManager:WaitForChild("KeyHandler", 3)

---Get the stack of the KeyHandler module.
---@return table?
function KeyHandling.getStack()
	if not keyHandler then
		return
	end

	local keyHandlerModule = require(keyHandler)
	return debug.getupvalue(getrawmetatable(debug.getupvalue(keyHandlerModule, 8)).__index, 1)[1][1]
end

---Get the Heaven and Hell remotes.
---@return Instance?, Instance?
function KeyHandling.getAntiCheatRemotes()
	local stack = KeyHandling.getStack()
	if not stack then
		return
	end

	return stack[86], stack[85]
end

---Get the 'khGetRemote' funciton.
---@return function?
function KeyHandling.getRemoteRaw()
	if not keyHandler then
		return
	end

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

---Get remote from a specific remote name.
---@param remoteName string
---@return Instance|nil
function KeyHandling.getRemote(remoteName)
	if not integrity then
		return
	end

	local integrityModule = require(integrity)
	if not integrityModule then
		return
	end

	local keyHandlerKey = integrityModule()
	if not keyHandlerKey then
		return
	end

	local khGetRemote = KeyHandling.getRemoteRaw()
	if not khGetRemote then
		return
	end

	return khGetRemote(remoteName, keyHandlerKey)
end

-- Return KeyHandling module.
return KeyHandling
