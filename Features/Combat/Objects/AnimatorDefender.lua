---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@class AnimatorDefender: Defender
---@field maid Maid
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender

-- Services.
local players = game:GetService("Players")

---Process animation track.
---@param track AnimationTrack
function AnimatorDefender:process(track)
	local timing = SaveManager.as:index(tostring(track.Animation.AnimationId))
	if not timing then
		return
	end

	local target = Targeting.find(self.entity)
	if not target then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	Logger.notify("Processing AnimationTrack with timing '%s' (%s) with AnimatorDefender.", timing.name, timing:id())

	task.wait(1)

	Logger.notify("Parry simulation.")

	Defender:parry()

	task.wait(1)

	Logger.notify("Dodge simulation.")

	Defender:dodge(humanoidRootPart, humanoid)
end

---Detach function.
function AnimatorDefender:detach()
	self.maid:clean()
end

---Create new AnimatorDefender object.
---@param animator Animator
---@return AnimatorDefender
function AnimatorDefender.new(animator)
	local self = setmetatable(Defender.new(), AnimatorDefender)
	local animationPlayed = Signal.new(animator.AnimationPlayed)

	self.entity = animator:FindFirstAncestorWhichIsA("Model")
	self.maid = Maid.new()
	self.maid:mark(animationPlayed:connect("AnimatorDefender_OnAnimationPlayed", function(track)
		self:process(track)
	end))

	return self
end

-- Return AnimatorDefender module.
return AnimatorDefender
