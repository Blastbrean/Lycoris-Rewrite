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

	timing.pfh = true

	local windup = nil

	-- Windup + 0-speed duration.

	if data.type == "Dagger" then
		windup = (0.166 / self.track.Speed) + 0.120
	elseif data.type == "Greataxe" then
		windup = (0.141 / self.track.Speed) + 0.140
	elseif data.type == "Greathammer" then
		windup = (0.150 / self.track.Speed) + 0.150
	elseif data.type == "Greatsword" then
		windup = (0.157 / self.track.Speed) + 0.130
	elseif data.type == "Greatcannon" then
		windup = (0.166 / self.track.Speed) + 0.130
	elseif data.type == "Twinblade" then
		windup = (0.163 / self.track.Speed) + 0.130
	elseif data.type == "Bow" then
		windup = (0.150 / self.track.Speed) + 0.140
	elseif data.type == "Club" then
		windup = (0.166 / self.track.Speed) + 0.140
	elseif data.type == "Pistol" then
		repeat
			task.wait()
		until self.track.Speed >= 0.1

		windup = (0.166 / self.track.Speed) + 0.150
	elseif data.type == "Rifle" then
		windup = (0.159 / self.track.Speed) + 0.140
	elseif data.type == "Rapier" then
		windup = (0.181 / self.track.Speed) + 0.130
	elseif data.type == "Fist" then
		windup = (0.150 / self.track.Speed) + 0.120
	elseif data.type == "Sword" then
		windup = (0.150 / self.track.Speed) + 0.150
	elseif data.type == "Spear" then
		windup = (0.163 / self.track.Speed) + 0.100
		windup += 0.050 / data.ss
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 2, data.length * 2, data.length * 2.5)
	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	return self:action(timing, action)
end
