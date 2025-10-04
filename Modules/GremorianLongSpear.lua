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

	if handWeapon:GetAttribute("WeaponName") == "Bloodtide Trident" then
		local action = Action.new()
		action._when = 300
		action._type = "Parry"
		action.hitbox = Vector3.new(21, 15, 28)
		action.name = "Static Bloodtide Trident Timing"
		return self:action(timing, action)
	end

	local action = Action.new()
	action._when = 500
	action._type = "Parry"
	action.hitbox = Vector3.new(21, 15, 28)
	action.name = "Static Gremorian Long Spear Timing"
	return self:action(timing, action)
end
