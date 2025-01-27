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

---On live descendant added.
---@param child Instance
local function onLiveDescendantAdded(child)
	if child:IsA("Animator") then
		return addAnimatorDefender(child)
	end

	if child:IsA("Sound") then
		return addSoundDefender(child)
	end

	if child:IsA("BasePart") then
		return addPartDefender(child)
	end
end

---On live descendant removed.
---@param child Instance
local function onLiveDescendantRemoved(child)
	local object = defenderObjects[child]
	if not object then
		return
	end

	object:detach()
	object[child] = nil
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

---Update defense.
---@note: We're only updating the PartDefender objects.
function Defense.update()
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

	-- Live folder.
	local live = workspace:WaitForChild("Live")

	-- Signals.
	local liveDescendantAdded = Signal.new(live.DescendantAdded)
	local liveDescendantRemoved = Signal.new(live.DescendantRemoving)
	local postSimulation = Signal.new(runService.PostSimulation)

	defenseMaid:add(liveDescendantAdded:connect("Defense_LiveDescendantAdded", onLiveDescendantAdded))
	defenseMaid:add(liveDescendantRemoved:connect("Defense_LiveDescendantRemoved", onLiveDescendantRemoved))
	defenseMaid:add(postSimulation:connect("Defense_PostSimulation", Defense.update))

	for _, descendant in next, live:GetDescendants() do
		onLiveDescendantAdded(descendant)
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
