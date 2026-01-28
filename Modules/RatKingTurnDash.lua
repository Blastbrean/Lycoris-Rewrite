---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action.hitbox = Vector3.new(35, 40, 35)

	if _G.RatKingChorusTime and (os.clock() - _G.RatKingChorusTime) < 2 then
		action._when = 500
		action._type = "Parry"
		action.name = string.format("(%.2f) Dynamic Rat King Turn Dash (Post-Chorus)", distance)
		_G.RatKingChorusTime = nil
	else
		action._when = math.min(350 + distance * 6)
		action._type = "Parry"
		action.name = string.format("(%.2f) Dynamic Rat King Turn Dash", distance)
	end

	return self:action(timing, action)
end
