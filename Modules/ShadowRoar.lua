---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---@module Modules.Globals.Waiter
local Waiter = getfenv().Waiter

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

	local data = Mantra.data(self.entity, "Mantra:RoarShadow{{Shadow Roar}}")
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
	self:crpue(self.entity, track, timing, 0, os.clock())
end
