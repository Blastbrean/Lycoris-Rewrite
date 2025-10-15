---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local timings = {
		[1] = 400,
		[2] = 1000,
		[3] = 1400,
	}

	for idx = 1, 3 do
		local action = Action.new()
		action._when = timings[idx] or 0
		action._type = "Parry"
		action.hitbox = Vector3.new(25, 25, 30)
		action.name = "Dynamic Crocco Timing"

		if self.entity.Name:match("king") then
			action.hitbox *= 2.0
		end

		self:action(timing, action)
	end
end
