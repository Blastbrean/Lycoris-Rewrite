---@type Action
local Action = getfenv().Action

-- Slash counter.
local sc = 0

-- Last slash time
local lst = 0.0

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	if os.clock() - lst >= 3.0 then
		sc = 0
	end

	lst = os.clock()
	sc += 1

	local action = Action.new()

	if sc == 1 then
		return
	end

	if sc == 2 then
		action._when = 900
	end

	if sc == 3 then
		action._when = 200
	end

	if sc == 4 then
		action._when = 200
	end

	action._type = "Parry"
	action.ihbc = true
	action.name = string.format("(%i) Lightning Slash Ferryman Timing", sc)
	return self:action(timing, action)
end
