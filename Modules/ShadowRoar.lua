---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---@module Modules.Globals.Waiter
local Waiter = getfenv().Waiter

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

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

	local _ = Mantra.data(self.entity, "Mantra:RoarShadow{{Shadow Roar}}")
	local hitbox = Vector3.new(20, 20, 40)

	timing.fhb = true
	timing.duih = false
	timing.rpue = true
	timing._rsd = 0
	timing._rpd = 300

	local action = Action.new()
	action._when = 500
	action._type = "Parry"
	action.hitbox = hitbox
	action.name = "Shadow Roar First Part"
	self:action(timing, action)

	local track = Waiter.fet("rbxassetid://7620630583", animator)
	local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
	info.track = track
	self:rpue(self.entity, timing, info)
end
