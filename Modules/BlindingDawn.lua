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

	timing.fhb = false
	timing.duih = true
	timing.rpue = true
	timing._rsd = 500
	timing._rpd = 150
	timing.hitbox = Vector3.new(60, 20, 60)

	local track = Waiter.fet("rbxassetid://10622235550", animator)
	local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
	info.track = track
	self:rpue(self.entity, timing, info)
end
