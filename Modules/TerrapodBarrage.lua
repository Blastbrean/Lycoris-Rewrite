---@module Utility.Signal
local Signal = getfenv().Signal

---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local count = 1

	---Handler for barrage iteration.
	local function onBarrageIteration()
		-- Increment count.
		count = count + 1

		-- Handle first swing.
		local actionOne = Action.new()
		actionOne._when = 900
		actionOne._type = "Parry"
		actionOne.hitbox = Vector3.new(20, 25, 23)
		actionOne.name = string.format("(%d) Terrapod Barrage Swing 1", count)
		self:action(timing, actionOne)

		if count > 1 then
			actionOne._when = 400
		end

		-- Handle second swing.
		local actionTwo = Action.new()
		actionTwo._when = 1400
		actionTwo._type = "Parry"
		actionTwo.hitbox = Vector3.new(20, 25, 23)
		actionTwo.name = string.format("(%d) Terrapod Barrage Swing 2", count)
		self:action(timing, actionTwo)

		if count > 1 then
			actionTwo._when = 1100
		end
	end

	local didLoopSignal = Signal.new(self.track.DidLoop)

	self.tmaid:add(didLoopSignal:connect("TerrapodBarrage_DidLoop", onBarrageIteration))

	onBarrageIteration()
end
