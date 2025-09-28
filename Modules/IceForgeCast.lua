---@class Action
local Action = getfenv().Action

---@class Timing
local Timing = getfenv().Timing

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local entity = self.entity
	if not entity then
		return
	end

	local hrp = entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	if hrp:FindFirstChild("REP_SOUND_15214335898") then
		local stormBladesTiming = Timing.new()
		stormBladesTiming.name = "StormBlades"

		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.hitbox = Vector3.new(30, 30, 30)
		action.name = "Storm Blades Timing"
		return self:action(stormBladesTiming, action)
	end
end
