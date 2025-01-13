---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.InstanceWrapper
local InstanceWrapper = require("Utility/InstanceWrapper")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@class AnimatorDefender: Defender
---@field animator Animator
---@field entity Model
---@field heffects Instance[]
---@field manimations table<number, Animation>
---@field track AnimationTrack? Don't be confused. This is the **valid && last** animation track played.
---@field maid Maid
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Check if we're in a valid state to proceed with the action.
---@param timing AnimationTiming
---@param action Action
---@return boolean
function AnimatorDefender:valid(timing, action)
	if not self.track then
		return self:notify(timing, "No current track.")
	end

	if not self.entity then
		return self:notify(timing, "No entity found.")
	end

	local target = Targeting.find(self.entity)
	if not target then
		return self:notify(timing, "Not a viable target.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	local hbStartPosition = target.root.CFrame * CFrame.new(0, 0, -(action.hitbox.Z / 2))

	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { character }
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	---@todo: Make the visualizations better. This is just for debugging. Right now, they don't clear up properly.
	if Configuration.expectToggleValue("EnableVisualizations") then
		local visualizationPart = InstanceWrapper.create(self.maid, "VisualizationPart", "Part")
		visualizationPart.Size = action.hitbox
		visualizationPart.CFrame = hbStartPosition
		visualizationPart.Transparency = 0.85
		visualizationPart.Color = Color3.fromRGB(255, 0, 0)
		visualizationPart.Parent = workspace
		visualizationPart.Anchored = true
		visualizationPart.CanCollide = false
		visualizationPart.Material = Enum.Material.SmoothPlastic
	end

	if #workspace:GetPartBoundsInBox(hbStartPosition, action.hitbox, overlapParams) <= 0 then
		return self:notify(timing, "Not inside of the hitbox.")
	end

	local targetInstance = self.entity:FindFirstChild("Target")
	if targetInstance and targetInstance.Value ~= self.entity and Configuration.toggleValue("CheckTargetingValue") then
		return self:notify(timing, "Not being targeted.")
	end

	if not self.track.IsPlaying then
		return self:notify(timing, "Animation stopped playing.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return self:notify(timing, "No effect replicator found.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return self:notify(timing, "No effect replicator module found.")
	end

	---@note: Hyperarmor check can be improved.

	if
		#self.heffects >= 1
		and (not self.entity:FindFirstChildWhichIsA("Highlight"))
		and (players:GetPlayerFromCharacter(self.entity) or self.entity:FindFirstChild("HumanController"))
	then
		return self:notify(timing, "Entity got attack cancelled.")
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

---Repeat until parry end.
---@param track AnimationTrack
---@param timing AnimationTiming
---@param index number
function AnimatorDefender:rpue(track, timing, index)
	if not self.track.IsPlaying then
		return
	end

	self:mark(
		Task.new(
			string.format("RPUE_%s_%i", timing.name, index),
			timing:rpd() - self:ping(),
			self.rpue,
			self,
			track,
			timing,
			index + 1
		)
	)

	if not self:initial(timing) then
		return
	end

	self:log(timing, "(%i) Action 'RPUE Parry' is being executed.", index)

	InputClient.parry()
end

---Process animation track.
---@todo: Logger module.
---@param track AnimationTrack
function AnimatorDefender:process(track)
	if track.Priority == Enum.AnimationPriority.Core then
		return
	end

	if track.WeightTarget <= 0.05 then
		return Logger.warn(
			"Animation %s is being skipped from entity %s with speed %.2f and weight-target %.2f. It is hidden.",
			track.Animation.AnimationId,
			self.entity.Name,
			track.WeightTarget,
			track.Speed
		)
	end

	if players:GetPlayerFromCharacter(self.entity) and self.manimations[track.Animation.AnimationId] ~= nil then
		return Logger.warn(
			"Animation %s is being skipped from player %s because they're likely AP breaking.",
			track.Animation.AnimationId,
			self.entity.Name
		)
	end

	local localCharacter = players.LocalPlayer.Character
	if localCharacter and self.entity == localCharacter then
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

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local humanoidRootPart = self.entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local midAttackEffect = effectReplicatorModule:FindEffect("MidAttack")
	local midAttackData = midAttackEffect and midAttackEffect.index
	local midAttackExpiry = midAttackData and midAttackData.Expiration
	local midAttackCanFeint = midAttackExpiry and (os.clock() - midAttackExpiry) <= 0.45

	-- Stop! We need to feint if we're currently attacking. Input block will handle the rest.
	-- Assume, we cannot react in time. Example: we attacked just right before this process call.
	local shouldFeintAttack = midAttackCanFeint and Configuration.expectToggleValue("FeintM1WhileDefending")
	local shouldFeintMantra = effectReplicatorModule:FindEffect("CastingSpell")
		and Configuration.expectToggleValue("FeintMantrasWhileDefending")

	if not effectReplicatorModule:FindEffect("FeintCool") and (shouldFeintAttack or shouldFeintMantra) then
		InputClient.feint(humanoidRootPart)
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Set current data.
	self.track = track
	self.heffects = {}

	---@note: Start processing the timing. Add the actions if we're not RPUE.
	if not timing.rpue then
		return self:actions(timing)
	end

	self:mark(
		Task.new(string.format("RPUE_%s", timing.name), timing:rsd() - self:ping(), self.rpue, self, track, timing, 0)
	)

	self:log(
		timing,
		"Added RPUE '%s' (%.2fs, then every %.2fs) with relevant ping subtracted.",
		timing.name,
		timing:rsd(),
		timing:rpd()
	)
end

---Detach AnimatorDefender object.
function AnimatorDefender:detach()
	-- Clean tasks.
	self:clean()

	-- Clean maid and object.
	self.maid:clean()
	self = nil
end

---Create new AnimatorDefender object.
---@param animator Animator
---@param manimations table<number, Animation>
---@return AnimatorDefender
function AnimatorDefender.new(animator, manimations)
	local entity = animator:FindFirstAncestorWhichIsA("Model")
	if not entity then
		return error(string.format("AnimatorDefender.new(%s) - no entity.", animator:GetFullName()))
	end

	local self = setmetatable(Defender.new(), AnimatorDefender)
	local animationPlayed = Signal.new(animator.AnimationPlayed)
	local entityDescendantAdded = Signal.new(entity.DescendantAdded)

	self.animator = animator
	self.manimations = manimations
	self.entity = entity

	self.track = nil
	self.heffects = {}
	self.maid = Maid.new()

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
