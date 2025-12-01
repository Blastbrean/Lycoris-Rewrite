---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

---@module Utility.Signal
local Signal = getfenv().Signal

---@module Utility.Configuration
local Configuration = getfenv().Configuration

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Weapon.data(self.entity)
	if not data then
		return
	end

	local humanoidRootPart = self.entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	-- Fallbacks. Reset to normal.
	timing.nvfb = true
	timing.pbfb = false
	timing.ndfb = false
	timing.bfht = 0.3

	-- Prediction settings.
	timing.dp = false
	timing.pfh = true
	timing.phd = true

	-- Prediction history times.
	timing.pfht = 0.25
	timing.phds = 0.6

	if data.type == "Fist" or data.type == "Dagger" or data.type == "Pistol" then
		timing.pbfb = true
		timing.bfht = 0.6
		timing.phds = data.type == "Dagger" and 0.6 or 0.25
		timing.pfh = false
		timing.dp = true
	end

	if
		data.type == "Sword"
		or data.type == "Twinblade"
		or data.type == "Spear"
		or data.type == "Club"
		or data.type == "Rifle"
	then
		timing.pbfb = true
		timing.bfht = 0.3
		timing.phd = false
		timing.ffh = true
		timing.pfht = 0.5
		timing.dp = false
	end

	if
		data.type == "Greathammer"
		or data.type == "Greatcannon"
		or data.type == "Greatsword"
		or data.type == "Greataxe"
	then
		timing.phd = false
		timing.ffh = true
		timing.pfht = 0.5
		timing.dp = false
	end

	local windup = nil
	local ispeed = self.track.Speed

	-- Windup + 0-speed duration.

	if data.type == "Greataxe" and self.track.Speed ~= 1.0 then
		windup = (0.171 / self.track.Speed) + 0.120
	elseif data.type == "Greataxe" and self.track.Speed == 1.0 then
		windup = (0.171 / self.track.Speed)
		windup += 0.250 / data.ss
	elseif data.type == "Greathammer" and self.track.Speed ~= 1.0 then
		windup = (0.150 / self.track.Speed) + 0.200
	elseif data.type == "Greathammer" and self.track.Speed == 1.0 then
		windup = (0.150 / self.track.Speed)
		windup += 0.250 / data.ss
	elseif data.type == "Greatcannon" and self.track.Speed ~= 1.0 then
		windup = (0.155 / self.track.Speed) + 0.160
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

		windup = 0.080 / self.track.Speed

		if self.track.Speed == 0.0 then
			windup = 0.100
		end
	elseif data.type == "Rifle" and timing.name:match("2") then
		repeat
			task.wait()
		until self.track.Speed ~= ispeed

		windup = (0.200 / self.track.Speed)

		if self.track.Speed == 0.0 then
			windup = 0.100
		end
	elseif data.type == "Rifle" then
		windup = (0.174 / self.track.Speed) + 0.150
	elseif data.type == "Club" then
		windup = (0.180 / self.track.Speed) + 0.100
	elseif data.type == "Twinblade" then
		windup = (0.150 / self.track.Speed) + 0.050
	elseif data.type == "Spear" then
		windup = (0.150 / self.track.Speed) + 0.100
	elseif data.type == "Greatsword" then
		windup = (0.158 / self.track.Speed) + 0.150
	elseif data.type == "Fist" then
		windup = (0.140 / self.track.Speed) + 0.130
	elseif data.type == "Dagger" then
		windup = (0.150 / self.track.Speed) + 0.075
	elseif data.type == "Sword" then
		windup = (0.150 / self.track.Speed) + 0.100
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 2.7, data.length * 3, data.length * 1.8)

	if data.type == "Bow" then
		action.hitbox = Vector3.new(data.length * 1.5, data.length * 2, data.length * 1.5)
	end

	if data.type == "Pistol" or data.type == "Rapier" or data.type == "Spear" then
		action.hitbox = Vector3.new(data.length * 1.7, data.length * 3, data.length * 1.8)
	end

	if data.type == "Sword" or data.type == "Twinblade" then
		action.hitbox = Vector3.new(data.length * 1.7, data.length * 3, data.length * 1.8)
	end

	if
		data.type == "Greathammer"
		or data.type == "Greatcannon"
		or data.type == "Greatsword"
		or data.type == "Greataxe"
	then
		action.hitbox = Vector3.new(data.length * 2.2, data.length * 2, data.length * 1.8)
	end

	if data.type == "Fist" or data.type == "Dagger" then
		action.hitbox = Vector3.new(data.length * 2.7, data.length * 3, data.length * 2)
	end

	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	local onDescendantAdded = Signal.new(self.entity.DescendantAdded)

	self.tmaid:add(onDescendantAdded:connect("WeaponTest_DetectFakeSwing", function(child)
		local current = self.tasks[#self.tasks]
		if not current then
			return
		end

		if child.Name ~= "REP_SOUND_5115545256" and child.Name ~= "REP_SOUND_4954198253" then
			return
		end

		-- If allow failure, then we should not cancel on feint.
		if Configuration.expectToggleValue("AllowFailure") and child.Name == "REP_SOUND_4954198253" then
			return
		end

		current:cancel()
	end))

	return self:action(timing, action)
end
