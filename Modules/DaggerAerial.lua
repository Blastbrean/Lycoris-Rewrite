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

	local action = Weapon.action(self.entity, 300 * 1.25, true)
	if not action then
		return
	end

	action.name = "Dynamic Dagger Aerial Attack"
	action.hitbox = Vector3.new(data.length * 1.75, data.length * 2, data.length * 2)

	timing.duih = true
	timing.hitbox = action.hitbox

	return self:action(timing, action)
end
