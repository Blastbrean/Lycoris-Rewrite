---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	for idx = 0, 1 do
		local action = Action.new()
		action._when = 400
		action._type = "Parry"
		action.hitbox = Vector3.new(25, 25, 25)
		action.name = "Dynamic Crocco Timing"

		if idx == 1 then
			action._when = 1100
		end

		if self.entity.Name:match("king") then
			action.hitbox *= 2.0
		end

		self:action(timing, action)
	end
end
