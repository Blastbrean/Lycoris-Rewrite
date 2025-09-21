---@module Game.Timings.Action
local Action = getfenv().Action

-- Weapon module.
local Weapon = {}

---Get equipped weapon data.
---@param entity Model
function Weapon.data(entity)
	local lh = entity:FindFirstChild("LeftHand")
	local rh = entity:FindFirstChild("RightHand")
	if not lh and not rh then
		return
	end

	local hw = (lh and lh:FindFirstChild("HandWeapon")) or (rh and rh:FindFirstChild("HandWeapon"))
	if not hw then
		return
	end

	local hwstats = hw:FindFirstChild("Stats")
	if not hwstats then
		return
	end

	local ssv = hwstats:FindFirstChild("SwingSpeed")
	if not ssv then
		return
	end

	local lv = hwstats:FindFirstChild("Length")
	if not lv then
		return
	end

	return {
		hw = hw,
		ss = ssv.Value,
		length = lv.Value,
	}
end

---Create Weapon action.
---@param entity Model
---@param base number Base timing to scale swing speed off of.
---@param scale boolean Scale dynamically?
---@return Action?
function Weapon.action(entity, base, scale)
	local data = Weapon.data(entity)
	if not data then
		return
	end

	local ss = data.ss
	local length = data.length

	local action = Action.new()
	action._when = scale and base / ss or base
	action._type = "Parry"
	action.hitbox = Vector3.new(length * 1.75, length * 1.5, length * 2)
	return action
end

-- Return Weapon module.
return Weapon
