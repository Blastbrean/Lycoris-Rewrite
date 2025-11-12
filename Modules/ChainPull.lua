---@type Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local data = Mantra.data(self.entity, "Mantra:StreamMetal{{Chain Pull}}")
	local range = data.perfect * 4 + data.crystal * 3

	local action = Action.new()
	action._when = math.min(350 + distance * 10)
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 40 + range)
	action.name = string.format("(%.2f) Dynamic Chain Pull Timing", distance)

	return self:action(timing, action)
end
