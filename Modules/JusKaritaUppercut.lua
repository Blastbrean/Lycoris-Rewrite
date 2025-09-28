---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Weapon.action(self.entity, 325 * 1.14, true)
	if not action then
		return
	end

	action.name = "Dynamic Jus Karita Uppercut"

	return self:action(timing, action)
end
