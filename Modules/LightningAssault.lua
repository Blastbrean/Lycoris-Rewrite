---@type Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:StrikeLightning{{Lightning Assault}}")
	local range = data.stratus * 2 + data.cloud * 1
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(400 + distance * 3, 1500)
	action._type = "Parry"
	action.hitbox = Vector3.new(35, 35, 40 + range)
	action.name = string.format("(%.2f) Dynamic Lightning Assault Timing", distance)

	return self:action(timing, action)
end
