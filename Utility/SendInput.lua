-- Input sending module.
local SendInput = {}

-- Services.
local virtualInputManager = Instance.new("VirtualInputManager")

---Send mouse button one event.
---@param x number
---@param y number
---@param repetitions number
function SendInput.mb1(x, y, repetitions)
	virtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, repetitions or 0)
	task.wait()
	virtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, repetitions or 0)
end

---Send mouse button one event.
---@param keyCode Enum.KeyCode
function SendInput.key(keyCode)
	virtualInputManager:SendKeyEvent(true, keyCode, false, game)
	task.wait()
	virtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

-- Return SendInput module.
return SendInput
