---@class Action
local Action = getfenv().Action

---@module Utility.Entitites
local Entitites = getfenv().Entitites

---Module function.
---@param self PartDefender
---@param timing PartTiming
return function(self, timing)
	local chaser = Entitites.fe("chaser")
	if not chaser then
		return
	end

	local hrp = chaser:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	timing.duih = false
	timing.uhc = false

	if hrp:WaitForChild("TelegraphAttach", 0.1) then
		local action = Action.new()
		action._when = 585
		action._type = "Forced Full Dodge"
		action.ihbc = true
		action.name = "Dodge Hit Tendril Timing"
		return self:action(timing, action)
	else
		local action = Action.new()
		action._when = 600
		action._type = "Parry"
		action.ihbc = true
		action.name = "Hit Tendril Timing"
		return self:action(timing, action)
	end
end
