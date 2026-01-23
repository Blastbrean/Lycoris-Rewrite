---@type Action
local Action = getfenv().Action
---@module Utility.Finder
local Finder = getfenv().Finder

local players = game:GetService("Players")

if not _G.RegentStringState then
    _G.RegentStringState = {
        firstTime = nil,
        count = 0
    }
end
local state = _G.RegentStringState

---@param self EffectDefender
---@param timing EffectTiming
return function(self, timing)
    if not state.firstTime then
        state.firstTime = os.clock()
        state.count = 0
        return
    end

    state.count = state.count + 1

    if state.count == 10 then
        local character = players.LocalPlayer.Character
        local myRoot = character and character:FindFirstChild("HumanoidRootPart")

        if myRoot then
            local startWait = os.clock()

            while task.wait() do
                if (os.clock() - startWait) > 3 then break end

                local regent = Finder.entity("lordregent")
                if regent then
                    local root = regent:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        if dist <= 10 then
                            local action = Action.new()
                            action._type = "Parry"
                            action._when = 50
                            action.ihbc = true
                            action.name = string.format("Regent String Grapple (dist: %.1f)", dist)

                            state.firstTime = nil
                            state.count = 0
                            return self:action(timing, action)
                        end
                    end
                end
            end
        end

        state.firstTime = nil
        state.count = 0
    end
end
