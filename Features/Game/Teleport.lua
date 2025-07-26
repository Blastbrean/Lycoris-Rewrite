-- Teleport module.
---@note: Teleports in Deepwoken do not work the same. They lag you back, obviously. This is a utility module to handle repeatedly teleporting for a specific purpose.
local Teleport = { destination = nil }

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Maids.
local tmaid = Maid.new()

---Loop for teleport module.
function Teleport.loop()
	local dest = Teleport.destination
	if not dest then
		return
	end

	local localPlayer = players.LocalPlayer
	local character = localPlayer.Character
	if not character then
		return
	end

	if dest == "EasternLuminant" then
		tmaid:add(
			TaskSpawner.spawn(
				"Teleport_EasternLuminantStream",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				Vector3.new(-2632.86084, 628.632935, -6707.99805),
				0.1
			)
		)

		local realmTeleport = workspace:FindFirstChild("RealmTeleport")
		if not realmTeleport then
			return
		end

		character:PivotTo(realmTeleport.CFrame)
	end
end

---Start teleport module.
---@param destination string
function Teleport.start(destination)
	if not destination then
		return error("Destination must be provided for teleporting.")
	end

	Teleport.destination = destination
end

---Stop teleport module.
function Teleport.stop()
	Teleport.destination = nil
end

---Initialize Teleport module.
function Teleport.init()
	local renderStepped = Signal.new(runService.RenderStepped)
	tmaid:mark(renderStepped:connect("Teleport_RenderStepped", Teleport.loop))
end

---Detach Teleport module.
function Teleport.detach()
	tmaid:destroy()
end

-- Return Teleport module.
return Teleport
