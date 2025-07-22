---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Weapon.action(self.entity, 800 * 0.84, true)
	if not action then
		return
	end

	action.name = "Dynamic Greatsword Timing"

	return self:action(timing, action)
end
