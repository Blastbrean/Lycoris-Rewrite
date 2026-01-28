---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local isRatKing = self.entity.Name:match("ratking")

	if isRatKing then
		timing.fhb = false

		local action = Action.new()
		action._when = 350
		action._type = "Parry"
		action.hitbox = Vector3.new(30, 30, 40)
		action.name = string.format("(%.2f) Rat King Chorus Timing", distance)

		_G.RatKingChorusTime = os.clock()

		return self:action(timing, action)
	end

	local action = Action.new()
	action._when = 550
	action._type = "Parry"
	action.hitbox = Vector3.new(16, 15, 15)
	action.name = string.format("(%.2f) Chorus Crit (1)", distance)
	self:action(timing, action)

	local actionTwo = Action.new()
	actionTwo._when = 1250
	actionTwo._type = "Parry"
	actionTwo.hitbox = Vector3.new(20, 15, 17)
	actionTwo.name = string.format("(%.2f) Chorus Crit (2)", distance)
	self:action(timing, actionTwo)
end
