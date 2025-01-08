---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.InstanceWrapper
local InstanceWrapper = require("Utility/InstanceWrapper")

---@class AnimatorDefender: Defender
---@field animator Animator
---@field entity Model
---@field heffects Instance[]
---@field track AnimationTrack?
---@field tasks Maid
---@field maid Maid
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender

-- Services.
local players = game:GetService("Players")
local stats = game:GetService("Stats")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Logger notify.
---@param timing AnimationTiming
---@param str string
function AnimatorDefender:log(timing, str, ...)
	Logger.notify("[%s] %s", timing.name, string.format(str, ...))
end

---Check if we're in a valid state to proceed with the action.
---@param action Action
---@return boolean
function AnimatorDefender:valid(action)
	if not self.track then
		return Logger.notify("No current track.")
	end

	if not self.entity then
		return Logger.notify("No entity found.")
	end

	local target = Targeting.find(self.entity)
	if not target then
		return Logger.notify("Not a viable target.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return Logger.notify("No character found.")
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { character }
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	local visualizationPart = InstanceWrapper.create(self.maid, "VisualizationPart", "Part")
	visualizationPart.Size = action.hitbox
	visualizationPart.CFrame = target.root.CFrame
	visualizationPart.Transparency = 0.85
	visualizationPart.Color = Color3.fromRGB(255, 0, 0)
	visualizationPart.Parent = workspace
	visualizationPart.Anchored = true
	visualizationPart.CanCollide = false

	if #workspace:GetPartBoundsInBox(target.root.CFrame, action.hitbox, overlapParams) <= 0 then
		return Logger.notify("Not inside of the hitbox.")
	end

	local targetInstance = self.entity:FindFirstChild("Target")
	if targetInstance and targetInstance.Value ~= self.entity and Configuration.toggleValue("CheckTargetingValue") then
		return Logger.notify("Not being targeted.")
	end

	if not self.track.IsPlaying then
		return Logger.notify("Animation stopped playing.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.notify("No effect replicator found.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.notify("No effect replicator module found.")
	end

	if effectReplicatorModule:FindEffect("Parry") or effectReplicatorModule:FindEffect("Dodge") then
		return Logger.notify("Effect list has 'Parry' or 'Dodge' effect.")
	end

	if
		#self.heffects >= 1
		and (players:GetPlayerFromCharacter(self.entity) or self.entity:FindFirstChild("HumanController"))
	then
		return Logger.notify("Entity got attack cancelled.")
	end

	return true
end

---Check if the initial state is valid.
---@param timing AnimationTiming
---@return boolean
function AnimatorDefender:initial(timing)
	local entity = self.animator:FindFirstAncestorWhichIsA("Model")
	if not entity then
		return false
	end

	local entRootPart = entity:FindFirstChild("HumanoidRootPart")
	if not entRootPart then
		return false
	end

	local localCharacter = players.LocalPlayer.Character
	if not localCharacter then
		return false
	end

	local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return false
	end

	local distance = (entRootPart.Position - localRootPart.Position).Magnitude

	if distance < timing.imdd then
		return false
	end

	if distance > timing.imxd then
		return false
	end

	return true
end

---Process animation track.
---@param track AnimationTrack
function AnimatorDefender:process(track)
	if track.Priority == Enum.AnimationPriority.Core then
		return
	end

	---@type AnimationTiming
	local timing = SaveManager.as:index(tostring(track.Animation.AnimationId))
	if not timing then
		return
	end

	if not self:initial(timing) then
		return
	end

	local network = stats:FindFirstChild("Network")
	if not network then
		return
	end

	local serverStatsItem = network:FindFirstChild("ServerStatsItem")
	if not serverStatsItem then
		return
	end

	local dataPingItem = serverStatsItem:FindFirstChild("Data Ping")
	if not dataPingItem then
		return
	end

	self.tasks:clean()
	self.track = track
	self.heffects = {}

	for _, action in next, timing.actions:get() do
		local dataPingInSeconds = dataPingItem:GetValue() / 1000
		local actionTask = TaskSpawner.delay(
			string.format("Action_%s", action._type),
			action:when() - dataPingInSeconds,
			self.handle,
			self,
			action
		)

		self:log(
			timing,
			"Added action '%s' (%.2fs) with ping '%.2f' subtracted.",
			action.name,
			action:when(),
			dataPingInSeconds
		)

		self.tasks:mark(actionTask)
	end
end

---Detach AnimatorDefender object.
function AnimatorDefender:detach()
	self.maid:clean()
	self.tasks:clean()
	self = nil
end

---Create new AnimatorDefender object.
---@param animator Animator
---@return AnimatorDefender
function AnimatorDefender.new(animator)
	local entity = animator:FindFirstAncestorWhichIsA("Model")
	if not entity then
		return error(string.format("AnimatorDefender.new(%s) - no entity.", animator:GetFullName()))
	end

	local self = setmetatable(Defender.new(), AnimatorDefender)
	local animationPlayed = Signal.new(animator.AnimationPlayed)
	local entityDescendantAdded = Signal.new(entity.DescendantAdded)

	self.track = nil
	self.animator = animator
	self.entity = entity

	self.heffects = {}
	self.maid = Maid.new()
	self.tasks = Maid.new()

	self.maid:mark(entityDescendantAdded:connect("AnimatorDefender_OnDescendantAdded", function(descendant)
		if
			descendant.Name ~= "PunchBlood"
			and descendant.Name ~= "PunchEffect"
			and descendant.Name ~= "BloodSpray"
			and not (descendant:IsA("ParticleEmitter") and descendant.Texture == "rbxassetid://7216855595")
		then
			return
		end

		self.heffects[#self.heffects + 1] = descendant
	end))

	self.maid:mark(animationPlayed:connect("AnimatorDefender_OnAnimationPlayed", function(track)
		self:process(track)
	end))

	return self
end

-- Return AnimatorDefender module.
return AnimatorDefender
