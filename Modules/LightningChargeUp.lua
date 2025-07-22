---@module Game.Timings.Action
local Action = getfenv().Action

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
		timing.fhb = false
		timing.ieae = false
		timing.iae = false
		timing.rpue = true
		timing.imxd = 150
		timing._rsd = 0
		timing._rpd = 100
		timing.hitbox = Vector3.new(50, 50, 50)
		self:crpue(self.entity, nil, timing, 0, os.clock())
	end
end
