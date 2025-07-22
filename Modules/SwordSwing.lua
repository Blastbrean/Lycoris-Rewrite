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

	local base = 400
	local name = data.hw and data.hw:GetAttribute("WeaponName") or ""

	-- Bloodfouler uppercut
	if name:match("Bloodfouler") then
		base = 350 * 0.83
	end

	local action = Weapon.action(self.entity, base, true)
	if not action then
		return
	end

	action.name = "Dynamic Sword Swing"

	-- Evengarde sword spam
	if self.entity.Name:match(".evengarde") and self.track.Speed >= 2.5 then
		action._when = 0
		action._type = "Parry"
		action.hitbox = Vector3.new(20, 20, 20)
	end

	return self:action(timing, action)
end
