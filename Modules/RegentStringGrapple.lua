---@type Action
local Action = getfenv().Action

if not _G.RegentStringState then
    _G.RegentStringState = {
        firstTime = nil,
        count = 0
    }
end
local state = _G.RegentStringState

local function findRegent()
    local live = workspace:FindFirstChild("Live")
    if not live then return nil end

    for _, model in next, live:GetChildren() do
        if model.Name:lower():find("regent") then
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then return root end
        end
    end
    return nil
end

---@param self EffectDefender
---@param timing EffectTiming
return function(self, timing)
    local now = os.clock()

    if state.firstTime and (now - state.firstTime) > 10 then
        state.firstTime = nil
        state.count = 0
    end

    if not state.firstTime then
        state.firstTime = now
        state.count = 0
        return
    end

    state.count = state.count + 1

    if state.count == 10 then
        local character = game.Players.LocalPlayer.Character
        local myRoot = character and character:FindFirstChild("HumanoidRootPart")

        if myRoot then
            local startWait = os.clock()

            while task.wait() do
                if (os.clock() - startWait) > 3 then break end

                local regentRoot = findRegent()
                if regentRoot then
                    local dist = (myRoot.Position - regentRoot.Position).Magnitude
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

        state.firstTime = nil
        state.count = 0
    end
end
