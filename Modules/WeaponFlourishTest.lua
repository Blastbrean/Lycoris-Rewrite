---@class Action
local Action = getfenv().Action

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

	timing.fhb = true
	timing.dp = false
	timing.pfht = 0.3

	local windup = nil

	-- Windup + 0-speed duration.

	if data.type == "Greataxe" then
		windup = (0.18 / self.track.Speed) + 0.100
	elseif data.type == "Greathammer" then
		windup = (0.14 / self.track.Speed) + 0.140
	elseif data.type == "Greatsword" then
		windup = (0.17 / self.track.Speed) + 0.150
	elseif data.type == "Twinblade" then
		windup = (0.166 / self.track.Speed) + 0.140
	elseif data.type == "Bow" then
		windup = (0.172 / self.track.Speed) + 0.140
	elseif data.type == "Pistol" then
		windup = 0.500 / data.ss
	elseif data.type == "Greatcannon" then
		windup = (0.173 / self.track.Speed) + 0.160
	elseif data.type == "Dagger" then
		windup = (0.165 / self.track.Speed) + 0.120
	elseif data.type == "Rapier" then
		windup = (0.163 / self.track.Speed) + 0.120
	elseif data.type == "Spear" then
		windup = (0.135 / self.track.Speed) + 0.180
	elseif data.type == "Fist" then
		windup = (0.160 / self.track.Speed) + 0.140
	elseif data.type == "Sword" then
		windup = (0.16 / self.track.Speed) + 0.150
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 2, data.length * 2, data.length * 2)
	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	return self:action(timing, action)
end
