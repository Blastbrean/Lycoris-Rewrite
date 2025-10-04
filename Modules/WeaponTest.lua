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

	timing.pfh = false

	local windup = nil
	local ispeed = self.track.Speed

	-- Windup + 0-speed duration.

	if data.type == "Greataxe" and self.track.Speed ~= 1.0 then
		windup = (0.171 / self.track.Speed) + 0.120
	elseif data.type == "Greataxe" and self.track.Speed == 1.0 then
		windup = (0.171 / self.track.Speed)
		windup += 0.250 / data.ss
		timing.pfh = true
	elseif data.type == "Greathammer" and self.track.Speed ~= 1.0 then
		windup = (0.150 / self.track.Speed) + 0.200
	elseif data.type == "Greathammer" and self.track.Speed == 1.0 then
		windup = (0.150 / self.track.Speed)
		windup += 0.250 / data.ss
		timing.pfh = true
	elseif data.type == "Greatcannon" and self.track.Speed ~= 1.0 then
		windup = (0.155 / self.track.Speed) + 0.160
		timing.pfh = true
	elseif data.type == "Greatcannon" and self.track.Speed == 1.0 then
		windup = (0.155 / self.track.Speed) + 0.300
	elseif data.type == "Rapier" then
		windup = (0.155 / self.track.Speed) + 0.120
	elseif data.type == "Bow" then
		windup = (0.147 / self.track.Speed) + 0.160
	elseif data.type == "Pistol" and not timing.name:match("Shot") then
		windup = 0.400 / data.ss
	elseif data.type == "Pistol" and timing.name:match("Shot") then
		repeat
			task.wait()
		until self.track.Speed ~= ispeed

		windup = 0.100 / self.track.Speed
	elseif data.type == "Rifle" and timing.name:match("2") then
		repeat
			task.wait()
		until self.track.Speed ~= ispeed

		windup = (0.200 / self.track.Speed)
	elseif data.type == "Rifle" then
		windup = (0.174 / self.track.Speed) + 0.150
	elseif data.type == "Club" then
		windup = (0.180 / self.track.Speed) + 0.150
	elseif data.type == "Twinblade" then
		windup = (0.155 / self.track.Speed) + 0.150
	elseif data.type == "Spear" then
		windup = (0.180 / self.track.Speed) + 0.120
	elseif data.type == "Greatsword" then
		windup = (0.158 / self.track.Speed) + 0.170
	elseif data.type == "Fist" then
		windup = (0.140 / self.track.Speed) + 0.130
	elseif data.type == "Dagger" then
		windup = (0.195 / self.track.Speed) + 0.100
	elseif data.type == "Sword" then
		windup = (0.150 / self.track.Speed) + 0.150
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 3, data.length * 3, data.length * 2.2)
	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	return self:action(timing, action)
end
