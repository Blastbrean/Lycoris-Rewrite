---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Features.Combat.Objects.AnimatorDefender
local AnimatorDefender = require("Features/Combat/Objects/AnimatorDefender")

---@module Features.Combat.Objects.PartDefender
local PartDefender = require("Features/Combat/Objects/PartDefender")

---@module Features.Combat.Objects.SoundDefender
local SoundDefender = require("Features/Combat/Objects/SoundDefender")

---@module Features.Combat.Objects.EffectDefender
local EffectDefender = require("Features/Combat/Objects/EffectDefender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.Table
local Table = require("Utility/Table")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Handle all defense related functions.
local Defense = {}

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- Maids.
local defenseMaid = Maid.new()

-- Defender objects.
local defenderObjects = {}

-- Mob animations.
local mobAnimations = {}

---Iteratively find effect owner from effect data.
---@param data table
---@return Model?
local function findEffectOwner(data)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local owner = nil

	for _, value in next, data do
		if typeof(value) ~= "Instance" or value.Parent ~= live or value == character then
			continue
		end

		return value
	end

	return owner
end

---Add animator defender.
---@param animator Animator
local function addAnimatorDefender(animator)
	defenderObjects[animator] = AnimatorDefender.new(animator, mobAnimations)
end

---Add sound defender.
---@param sound Sound
local function addSoundDefender(sound)
	---@note: If there's nothing to base the sound position off of, then I'm just gonna skip it bruh.
	local part = sound:FindFirstAncestorWhichIsA("BasePart")
	if not part then
		return
	end

	-- Add sound defender.
	defenderObjects[sound] = SoundDefender.new(sound, part)
end

---Add part defender.
---@param part BasePart
local function addPartDefender(part)
	local timing = SaveManager.ps:index(part.Name)
	if not timing then
		return
	end

	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local distance = (part.Position - humanoidRootPart.Position).Magnitude
	if distance < timing.imdd or distance > timing.imxd then
		return
	end

	local comparison = function(element)
		return table.find(timing.filter, element.Name)
	end

	if #timing.filter >= 1 and not Table.elements(part:GetDescendants(), comparison) then
		return
	end

	defenderObjects[part] = PartDefender.new(part, timing)
end

---On game descendant added.
---@param descendant Instance
local function onGameDescendantAdded(descendant)
	if descendant:IsA("Animator") then
		return addAnimatorDefender(descendant)
	end

	if descendant:IsA("Sound") then
		return addSoundDefender(descendant)
	end

	if descendant:IsA("BasePart") then
		return addPartDefender(descendant)
	end
end

---On game descendant removed.
---@param descendant Instance
local function onGameDescendantRemoved(descendant)
	local object = defenderObjects[descendant]
	if not object then
		return
	end

	object:detach()
	object[descendant] = nil
end

---On client effect event.
---@param name string?
---@param data table?
local function onClientEffectEvent(name, data)
	if not name or not data then
		return
	end

	local owner = findEffectOwner(data)
	if not owner then
		return
	end

	defenderObjects[data] = EffectDefender.new(name, owner)
end

---Update part defenders.
local function updatePartDefenders()
	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	for _, object in next, defenderObjects do
		if object.__type ~= "PartDefender" then
			continue
		end

		if not object.update then
			continue
		end

		object:update()
	end
end

---Check if objects have blocking tasks.
---@return boolean
function Defense.blocking()
	for _, object in next, defenderObjects do
		if not object:blocking() then
			continue
		end

		return true
	end
end

---Initialize defense.
function Defense.init()
	-- Cache mob animations.
	local assetFolder = replicatedStorage:WaitForChild("Assets")
	local animationFolder = assetFolder:WaitForChild("Anims")
	local mobsAnimationFolder = animationFolder:WaitForChild("Mobs")

	for _, animation in next, mobsAnimationFolder:GetDescendants() do
		if not animation:IsA("Animation") then
			continue
		end

		mobAnimations[animation.AnimationId] = animation
	end

	-- Requests.
	local requests = replicatedStorage:WaitForChild("Requests")
	local clientEffect = requests:WaitForChild("ClientEffect")

	-- Signals.
	local gameDescendantAdded = Signal.new(game.DescendantAdded)
	local gameDescendantRemoved = Signal.new(game.DescendantRemoving)
	local postSimulation = Signal.new(runService.PostSimulation)
	local clientEffectEvent = Signal.new(clientEffect.OnClientEvent)

	defenseMaid:add(gameDescendantAdded:connect("Defense_OnDescendantAdded", onGameDescendantAdded))
	defenseMaid:add(gameDescendantRemoved:connect("Defense_OnDescendantRemoved", onGameDescendantRemoved))
	defenseMaid:add(postSimulation:connect("Defense_ProjectilePostSimulation", updatePartDefenders))
	defenseMaid:add(clientEffectEvent:connect("Defense_ClientEffectEvent", onClientEffectEvent))

	for _, descendant in next, game:GetDescendants() do
		onGameDescendantAdded(descendant)
	end
end

---Detach defense.
function Defense.detach()
	for _, object in next, defenderObjects do
		object:detach()
	end

	defenseMaid:clean()
end

-- Return Defense module.
return Defense
