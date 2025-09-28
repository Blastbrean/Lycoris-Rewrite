---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Weapon.data(self.entity)
	if not data then
		return
	end

	local action = Weapon.action(self.entity, 350, false)
	if not action then
		return
	end

	action.name = "Dynamic Fist Running Attack"
	action.hitbox = Vector3.new(data.length * 2, data.length * 2, data.length * 2.5)

	timing.duih = true
	timing.hitbox = action.hitbox
	timing.fhb = true

	return self:action(timing, action)
end
