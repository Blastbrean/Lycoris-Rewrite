---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Waiter
local Waiter = getfenv().Waiter

---@class Timing
local Timing = getfenv().Timing

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local humanoid = self.entity:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return
	end

	task.wait(0.35 - self.rtt())

	if self:distance(self.entity) <= 10 then
		local firstTiming = Timing.new()
		firstTiming.fhb = true
		firstTiming.duih = false
		firstTiming.rpue = false
		firstTiming.name = "ShoulderBashWindup"
		firstTiming.cbm = true

		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.ihbc = true
		action.name = "Shoulder Bash Close"
		return self:action(firstTiming, action)
	end

	local track = Waiter.fet("rbxassetid://9400896040", animator)
	if not track then
		return
	end

	timing.fhb = true
	timing.duih = true
	timing.rpue = false
	timing.hitbox = Vector3.new(10, 10, 17.5)

	self:hook("stopped", function(...)
		return not track.IsPlaying
	end)

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(10, 10, 17.5)
	action.name = "Shoulder Bash Far"
	self:action(timing, action)
end
