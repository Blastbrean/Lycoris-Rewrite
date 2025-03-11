---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

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

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@class AnimatorDefender: Defender
---@field animator Animator
---@field entity Model
---@field heffects Instance[]
---@field keyframes Action[]
---@field timing AnimationTiming?
---@field manimations table<number, Animation>
---@field track AnimationTrack? Don't be confused. This is the **valid && last** animation track played.
---@field maid Maid This maid is cleaned up after every new animation track. Safe to use for on-animation-track setup.
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender
AnimatorDefender.__type = "Animation"

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Check if we're in a valid state to proceed with the action.
---@param timing AnimationTiming
---@param action Action
---@return boolean
AnimatorDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
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

	while
		timing.duih
		and not self:hitbox(
			target.root.CFrame,
			timing.fhb and action.hitbox.Z / 2 or 0,
			timing.hitbox,
			{ players.LocalPlayer.Character }
		)
	do
		task.wait()
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self:hitbox(target.root.CFrame, timing.fhb and action.hitbox.Z / 2 or 0, action.hitbox, { character }) then
		return self:notify(timing, "Not inside of the hitbox.")
	end

	local targetInstance = self.entity:FindFirstChild("Target")
	if targetInstance and targetInstance.Value ~= character and Configuration.toggleValue("CheckTargetingValue") then
		return self:notify(timing, "Not being targeted.")
	end

	if not timing.iae and not self.track.IsPlaying then
		return self:notify(timing, "Animation stopped playing.")
	end

	if timing.iae and not self.track.IsPlaying and self.track.TimePosition < self.track.Length then
		return self:notify(timing, "Animation stopped playing early.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return self:notify(timing, "No effect replicator found.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return self:notify(timing, "No effect replicator module found.")
	end

	if
		not timing.ha
		and #self.heffects >= 1
		and (players:GetPlayerFromCharacter(self.entity) or self.entity:FindFirstChild("HumanController"))
	then
		return self:notify(timing, "Entity got attack cancelled.")
	end

	return true
end)

---Repeat until parry end.
---@param track AnimationTrack
---@param timing AnimationTiming
---@param index number
AnimatorDefender.rpue = LPH_NO_VIRTUALIZE(function(self, track, timing, index)
	if not self.track.IsPlaying then
		return
	end

	self:mark(
		Task.new(
			string.format("RPUE_%s_%i", timing.name, index),
			timing:rpd() - self:ping(),
			timing.punishable,
			timing.after,
			self.rpue,
			self,
			track,
			timing,
			index + 1
		)
	)

	if
		timing.duih
		and not self:hitbox(
			Targeting.find(self.entity).root.CFrame,
			0,
			timing.hitbox,
			{ players.LocalPlayer.Character }
		)
	then
		return
	end

	if not self:initial(self.entity, SaveManager.as, self.entity.Name, tostring(track.Animation.AnimationId)) then
		return
	end

	self:notify(timing, "(%i) Action 'RPUE Parry' is being executed.", index)

	InputClient.parry()
end)

---Get latest keyframe.
---@return Action?
AnimatorDefender.latest = LPH_NO_VIRTUALIZE(function(self)
	local latestKeyframe = nil
	local latestDelta = nil

	for _, keyframe in next, self.keyframes do
		if self.track.TimePosition <= keyframe.adelta then
			continue
		end

		if latestDelta and keyframe.adelta <= latestDelta then
			continue
		end

		latestDelta = keyframe.adelta
		latestKeyframe = keyframe
	end

	return latestKeyframe
end)

---Update the defender.
---@param self AnimatorDefender
AnimatorDefender.update = LPH_NO_VIRTUALIZE(function(self)
	if not self.track or not self.timing then
		return
	end

	-- Find the latest keyframe that we have exceeded.
	local latest = self:latest()
	if not latest then
		return
	end

	-- Clear the keyframes that we have exceeded.
	for idx, keyframe in next, self.keyframes do
		if self.track.TimePosition <= keyframe.adelta then
			continue
		end

		self.keyframes[idx] = nil
	end

	-- Ok, run action of this keyframe.
	self:mark(
		Task.new(latest._type, nil, self.timing.punishable, self.timing.after, self.handle, self, self.timing, latest)
	)
end)

---Add animation delta actions.
---@param self AnimatorDefender
---@param timing AnimationTiming
AnimatorDefender.aeactions = LPH_NO_VIRTUALIZE(function(self, timing)
	for _, action in next, timing.actions:get() do
		-- Skip all actions that are animation delta based.
		if not action.uad then
			continue
		end

		-- Add to keyframe list.
		self.keyframes[#self.keyframes + 1] = action
	end
end)

---Process animation track.
---@todo: Logger module.
---@param track AnimationTrack
AnimatorDefender.process = LPH_NO_VIRTUALIZE(function(self, track)
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
			"(%s) Animation %s is being skipped from player %s because they're likely AP breaking.",
			self.manimations[track.Animation.AnimationId].Name,
			track.Animation.AnimationId,
			self.entity.Name
		)
	end

	---@type AnimationTiming?
	local timing = self:initial(self.entity, SaveManager.as, self.entity.Name, tostring(track.Animation.AnimationId))
	if not timing then
		return
	end

	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	local localCharacter = players.LocalPlayer.Character
	if localCharacter and self.entity == localCharacter then
		return
	end

	local humanoidRootPart = self.entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
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

	local midAttackEffect = effectReplicatorModule:FindEffect("MidAttack")
	local midAttackData = midAttackEffect and midAttackEffect.index
	local midAttackExpiry = midAttackData and midAttackData.Expiration
	local midAttackCanFeint = midAttackExpiry and (os.clock() - midAttackExpiry) <= 0.45

	-- Stop! We need to feint if we're currently attacking. Input block will handle the rest.
	-- Assume, we cannot react in time. Example: we attacked just right before this process call.
	---@note: Replicate to other types. Improve me or move me.
	local shouldFeintAttack = midAttackCanFeint and Configuration.expectToggleValue("FeintM1WhileDefending")
	local shouldFeintMantra = effectReplicatorModule:FindEffect("CastingSpell")
		and Configuration.expectToggleValue("FeintMantrasWhileDefending")

	if not effectReplicatorModule:FindEffect("FeintCool") and (shouldFeintAttack or shouldFeintMantra) then
		-- Log.
		self:notify(timing, "Automatically feinting attack.")

		-- Feint.
		InputClient.feint()
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Set current data.
	self.timing = timing
	self.track = track
	self.heffects = {}

	-- Use module over actions.
	if timing.umoa then
		return self:module(timing)
	end

	---@note: Start processing the timing. Add the actions if we're not RPUE.
	if not timing.rpue then
		return self:actions(timing) and self:aeactions(timing)
	end

	self:mark(
		Task.new(
			string.format("RPUE_%s", timing.name),
			timing:rsd() - self:ping(),
			timing.punishable,
			timing.after,
			self.rpue,
			self,
			track,
			timing,
			0
		)
	)

	self:notify(
		timing,
		"Added RPUE '%s' (%.2fs, then every %.2fs) with relevant ping subtracted.",
		timing.name,
		timing:rsd(),
		timing:rpd()
	)
end)

---Clean up the defender.
function AnimatorDefender:clean()
	-- Empty keyframes.
	self.keyframes = {}

	-- Clean through base method.
	Defender.clean(self)
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
	self.timing = nil

	self.heffects = {}
	self.keyframes = {}

	self.maid:mark(
		entityDescendantAdded:connect(
			"AnimatorDefender_OnDescendantAdded",
			LPH_NO_VIRTUALIZE(function(descendant)
				if
					descendant.Name ~= "PunchBlood"
					and descendant.Name ~= "PunchEffect"
					and descendant.Name ~= "BloodSpray"
					and not (descendant:IsA("ParticleEmitter") and descendant.Texture == "rbxassetid://7216855595")
				then
					return
				end

				self.heffects[#self.heffects + 1] = descendant
			end)
		)
	)

	self.maid:mark(animationPlayed:connect(
		"AnimatorDefender_OnAnimationPlayed",
		LPH_NO_VIRTUALIZE(function(track)
			self:process(track)
		end)
	))

	return self
end

-- Return AnimatorDefender module.
return AnimatorDefender
