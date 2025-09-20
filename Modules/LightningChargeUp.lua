---@module Game.Timings.Action
local Action = getfenv().Action

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	if not self.entity.Name:match(".evengarde") then
		return
	end

	if workspace:WaitForChild("windyp", 1.0) then
		local action = Action.new()
		action._when = 0
		action._type = "Dodge"
		action.hitbox = Vector3.new(50, 50, 50)
		self:action(timing, action)
	else
		local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
		info.track = self.track

		timing.fhb = false
		timing.ieae = false
		timing.iae = false
		timing.rpue = true
		timing.imxd = 150
		timing._rsd = 0
		timing._rpd = 100
		timing.hitbox = Vector3.new(50, 50, 50)
		self:rpue(self.entity, timing, info)
	end
end
