---@class Action
local Action = getfenv().Action

---Module function.
---@param self EffectDefender
---@param timing EffectTiming
return function(self, timing)
	local entity = self.owner
	if not entity then
		return
	end

	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	---@todo: Prime Golem is a special case.
	if entity.Name:match("prime") then
		return
	end

	local action = Action.new()
	action._when = 2300
	action._type = "Dodge"
	action.hitbox = Vector3.new(40, 200, 200)
	action.name = "Dynamic Beam Timing"
	return self:action(timing, action)
end
