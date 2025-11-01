---@type PartTiming
local PartTiming = getfenv().PartTiming

---@type Action
local Action = getfenv().Action

---@type ProjectileTracker
local ProjectileTracker = getfenv().ProjectileTracker

---@module Features.Combat.Defense
local Defense = getfenv().Defense

--- Combined module for IceDaggers & FleetingSparks
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	-- Track either IceDagger or FleetingSparks
	local tracker = ProjectileTracker.new(function(candidate)
		return candidate and candidate.Name and (candidate.Name == "IceDagger" or candidate.Name == "LightningMote")
	end)

	local delay = 0.5 - (self.rtt() or 0)
	if delay < 0 then
		delay = 0
	end
	task.wait(delay)

	local projectile = tracker:wait()
	if not projectile or not projectile:IsA("BasePart") then
		return
	end

	local name = projectile.Name

	-- === FleetingSparks logic ===
	if name == "LightningMote" then
		if self:distance(self.entity) <= 10 then
			local actionclose = Action.new()
			actionclose._type = "Parry"
			actionclose._when = 0
			actionclose.name = "Fleeting Sparks Close Timing"
			actionclose.ihbc = true
			self:action(timing, actionclose)
		end

		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.name = "Fleeting Sparks Part"

		local pt = PartTiming.new()
		pt.uhc = false
		pt.duih = true
		pt.fhb = false
		pt.name = "FleetingSparksProjectile"
		pt.actions:push(action)
		pt.cbm = true

		pt.hitbox = Vector3.new(10, 10, 10)
		Defense.cdpo(projectile, pt)

		task.spawn(function()
			local baseHitbox = Vector3.new(10, 10, 10)
			local lastSpeed = 0
			local smoothing = 0.3 -- 0.1–0.3 recommended: lower = snappier, higher = smoother

			while projectile and projectile.Parent do
				local velocity = projectile.AssemblyLinearVelocity or projectile.Velocity or Vector3.zero
				local rawSpeed = velocity.Magnitude

				-- smooth speed using exponential moving average
				local smoothedSpeed = lastSpeed + (rawSpeed - lastSpeed) * smoothing
				lastSpeed = smoothedSpeed

				-- compute scale factor (smoothly changing)
				local scaleFactor = math.clamp(smoothedSpeed / 5, 1, 4)
				local newHitbox = baseHitbox * scaleFactor

				-- only update if size changed meaningfully
				if (pt.hitbox - newHitbox).Magnitude > 0.05 then
					pt.hitbox = newHitbox

					if Defense.updateHitbox then
						Defense.updateHitbox(projectile, pt)
					end
				end

				task.wait(0.05) -- small step for smoother transitions and lower CPU usage
			end
		end)

	-- === IceDaggers logic ===
	elseif name == "IceDagger" then
		if self:distance(self.entity) <= 15 then
			local actionclose = Action.new()
			actionclose._type = "Start Block"
			actionclose._when = 0
			actionclose.name = "Ice Daggers Close Timing"
			actionclose.ihbc = true
			self:action(timing, actionclose)

			local actioncloseTwo = Action.new()
			actioncloseTwo._when = 1000
			actioncloseTwo._type = "End Block"
			actioncloseTwo.ihbc = true
			self:action(timing, actioncloseTwo)
		end

		local action = Action.new()
		action._when = 0
		action._type = "Start Block"
		action.name = "Ice Dagger Part"

		local actionTwo = Action.new()
		actionTwo._when = 500
		actionTwo._type = "End Block"
		actionTwo.ihbc = true

		local pt = PartTiming.new()
		pt.uhc = true
		pt.duih = true
		pt.fhb = true
		pt.name = "IceDaggersProjectile"
		pt.hitbox = Vector3.new(20, 20, 32.5)
		pt.actions:push(action)
		pt.actions:push(actionTwo)
		pt.cbm = true

		Defense.cdpo(projectile, pt)
	end
end
