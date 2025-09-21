---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local rightHand = self.entity:FindFirstChild("RightHand")
	local leftHand = self.entity:FindFirstChild("LeftHand")
	if not rightHand or not leftHand then
		return
	end

	local handWeapon = rightHand:FindFirstChild("HandWeapon") or leftHand:FindFirstChild("HandWeapon")
	if not handWeapon then
		return
	end

	if handWeapon:GetAttribute("WeaponName") == "Kyrsieger" then
		return
	end

	local action = Action.new()
	action._when = 370
	action._type = "Parry"
	action.hitbox = Vector3.new(14, 11, 20)
	action.name = "Rifle Spear Crit Timing"
	return self:action(timing, action)
end
