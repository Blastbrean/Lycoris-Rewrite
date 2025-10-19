-- Teleport module.
---@note: Teleports in Deepwoken do not work the same. They lag you back, obviously. This is a utility module to handle repeatedly teleporting for a specific purpose.
local Teleport = { destination = nil, gdp = nil }

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Maids.
local tmaid = Maid.new()

---On player GUI descendant added.
---@param child Instance
local function onPlayerGuiDescendantAdded(child)
	if not child:IsA("TextLabel") then
		return
	end

	local coords = string.split(child.Text, ", ")
	local x, y, z = tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3])
	if not x or not y or not z then
		return
	end

	local position = Vector3.new(x, y, z)

	if (position - Vector3.new(-20000, 20000, -20000)).Magnitude <= 20 and Teleport.destination == "Voidheart" then
		return Teleport.stop()
	end

	if (position - Vector3.new(1596.1, 555.7, 2849.9)).Magnitude <= 20 and Teleport.destination == "LowerErisia" then
		return Teleport.stop()
	end

	if Teleport.gdp and (position - Teleport.gdp).Magnitude <= 20 and Teleport.destination == "GuildDoor" then
		return Teleport.stop()
	end
end

---Get guild doors from partial or exact name.
---@note: First instance is the entrance door. The second instance is the exit door.
---@param name string
---@return Instance?, Instance?
local function getGuildDoors(name)
	for _, instance in next, workspace:GetChildren() do
		if not instance.Name:match("GuildDoor") then
			continue
		end

		local guildName = instance:GetAttribute("GuildName")
		if not guildName then
			continue
		end

		if not guildName:match(name) then
			continue
		end

		return instance, workspace:FindFirstChild(string.gsub(instance.Name, "GuildDoor", "GuildExitDoor"))
	end

	return nil
end

---Loop for teleport module.
local function onTeleportLoop()
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

		local realmTeleporter = workspace:FindFirstChild("RealmTeleporter")
		if not realmTeleporter then
			return
		end

		character:PivotTo(realmTeleporter.CFrame)
	end

	if dest == "EtreanLuminant" then
		tmaid:add(
			TaskSpawner.spawn(
				"Teleport_EtreanLuminantStream",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				Vector3.new(-514.263, 665.174316, -4772.3208),
				0.1
			)
		)

		local realmTeleporter = workspace:FindFirstChild("RealmTeleporter")
		if not realmTeleporter then
			return
		end

		character:PivotTo(realmTeleporter.CFrame)
	end

	if dest == "Depths" then
		tmaid:add(
			TaskSpawner.spawn(
				"Teleport_DepthsStream",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				Vector3.new(39911.3672, 39980.9375, 39708.3203),
				0.1
			)
		)

		local modOffice = workspace:FindFirstChild("ModOffice")
		local officePit = modOffice and modOffice:FindFirstChild("OfficePit")
		if not officePit then
			return
		end

		character:PivotTo(officePit.CFrame)
	end

	if dest == "Voidheart" then
		tmaid:add(
			TaskSpawner.spawn(
				"Teleport_VoidheartStream",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				Vector3.new(-20000.0, 19713.9609, -20000.0),
				0.1
			)
		)

		local voidheart = workspace:FindFirstChild("Voidheart")
		local voidheartVoidWarp = voidheart and voidheart:FindFirstChild("VoidheartVoidWarp")
		if not voidheartVoidWarp then
			return
		end

		character:PivotTo(CFrame.new(-20000.0, 19713.9609, -20000.0))
	end

	if dest == "TrialOfOne" then
		tmaid:add(
			TaskSpawner.spawn(
				"Teleport_TrialStream",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				Vector3.new(-959.787659, 146.996887, -6659.63037),
				0.1
			)
		)

		local oneEntrance = workspace:FindFirstChild("OneEntrance")
		if not oneEntrance then
			return
		end

		local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
		if not effectReplicator then
			return
		end

		local effectReplicatorModule = require(effectReplicator)
		if not effectReplicatorModule then
			return
		end

		if effectReplicatorModule:FindEffect("Knocked") then
			return Teleport.stop()
		end

		character:PivotTo(oneEntrance.CFrame)
	end

	if dest == "GuildDoor" then
		local guildName = Configuration.expectOptionValue("GuildDoorName")
		if not guildName or #guildName <= 0 then
			return
		end

		local entranceDoor, exitDoor = getGuildDoors(guildName)
		if not entranceDoor or not exitDoor then
			return
		end

		local guildBaseCFrame = entranceDoor:GetAttribute("TargetCFrame")
		if not guildBaseCFrame then
			return
		end

		local guildDoorCFrame = exitDoor:GetAttribute("TargetCFrame")
		if not guildDoorCFrame then
			return
		end

		Teleport.gdp = guildDoorCFrame.Position

		-- Stream in the guild base.
		tmaid:add(
			TaskSpawner.spawn(
				"Teleport_GuildBaseStream",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				guildBaseCFrame.Position,
				0.1
			)
		)

		-- Teleport over their bounds to trigger a forced game teleport.
		character:PivotTo(CFrame.new(guildBaseCFrame.Position - Vector3.new(0, 150, 0)))
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
	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local descendantAddedSignal = Signal.new(playerGui.DescendantAdded)
	tmaid:mark(descendantAddedSignal:connect("Teleport_PlayerGui_DescendantAdded", onPlayerGuiDescendantAdded))

	local renderStepped = Signal.new(runService.RenderStepped)
	tmaid:mark(renderStepped:connect("Teleport_RenderStepped", onTeleportLoop))
end

---Detach Teleport module.
function Teleport.detach()
	tmaid:clean()
end

-- Return Teleport module.
return Teleport
