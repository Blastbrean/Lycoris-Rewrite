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
local clientManager = modules:WaitForChild("ClientManager")
local keyHandler = clientManager:WaitForChild("KeyHandler")

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
	local stack, getRemote, getRemoteKey = nil, nil, nil

	while not stack or not getRemote or not getRemoteKey do
		stack = KeyHandling.getStack()
		getRemote = stack[89]
		getRemoteKey = stack[64]
		task.wait(0.1)
	end

	return getRemote(remoteName, getRemoteKey)
end

---Wait for remote from a specific remote name.
---@param remoteName string
---@return Instance
function KeyHandling.waitForRemote(remoteName)
	local remote = nil

	while not remote do
		remote = KeyHandling.getRemote(remoteName)
		task.wait(0.1)
	end

	return remote
end

-- Return KeyHandling module.
return KeyHandling
