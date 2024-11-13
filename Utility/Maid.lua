-- https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Events/Maid.lua
---@class Maid
local Maid = {}
Maid.__type = "maid"

---Create new Maid object.
---@return Maid
function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

---Return maid[key] - if not, it's not apart of the maid metatable - so we return the relevant task.
-- @return value
function Maid:__index(index)
	if Maid[index] then
		return Maid[index]
	else
		return self._tasks[index]
	end
end

---Clean or add a task with a specific key.
---@param index any
---@param new_task any
function Maid:__newindex(index, new_task)
	if Maid[index] ~= nil then
		return warn(("'%s' is reserved"):format(tostring(index)), 2)
	end

	local tasks = self._tasks
	local oldTask = tasks[index]

	if oldTask == new_task then
		return
	end

	tasks[index] = new_task

	if oldTask then
		if type(oldTask) == "function" then
			oldTask()
		elseif typeof(oldTask) == "RBXScriptConnection" then
			oldTask:Disconnect()
		elseif typeof(oldTask) == "Instance" and oldTask:IsA("Tween") then
			oldTask:Pause()
			oldTask:Cancel()
			oldTask:Destroy()
		elseif oldTask.Destroy then
			oldTask:Destroy()
		elseif oldTask.detach then
			oldTask:detach()
		end
	end
end

---Add a task without a specific ID.
---@param task any
---@return number
function Maid:add(task)
	if not task then
		return error("task cannot be false or nil", 2)
	end

	local taskId = #self._tasks + 1
	self[taskId] = task

	if type(task) == "table" and not task.Destroy then
		warn("gave table task without .Destroy\n\n" .. debug.traceback(1))
	end

	return taskId
end

---Remove task without cleaning it.
---@param taskId number
function Maid:removeTask(taskId)
	local tasks = self._tasks
	tasks[taskId] = nil
end

---Clean up all tasks.
function Maid:clean()
	local tasks = self._tasks

	-- Disconnect all events first - as we know this is safe.
	for index, task in pairs(tasks) do
		if typeof(task) == "RBXScriptConnection" then
			tasks[index] = nil
			task:Disconnect()
		end
	end

	-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid.
	local index, task = next(tasks)

	while task ~= nil do
		tasks[index] = nil

		if type(task) == "function" then
			task()
		elseif typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		elseif typeof(task) == "Instance" and task:IsA("Tween") then
			task:Pause()
			task:Cancel()
			task:Destroy()
		elseif task.Destroy then
			task:Destroy()
		elseif task.detach then
			task:detach()
		end

		index, task = next(tasks)
	end
end

-- Return Maid module.
return Maid
