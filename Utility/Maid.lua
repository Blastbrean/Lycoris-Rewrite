return LPH_NO_VIRTUALIZE(function()
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
	---@param newTask any
	function Maid:__newindex(index, newTask)
		if Maid[index] ~= nil then
			return warn(("'%s' is reserved"):format(tostring(index)), 2)
		end

		local tasks = self._tasks
		local oldTask = tasks[index]

		if oldTask == newTask then
			return
		end

		tasks[index] = newTask

		if oldTask then
			if typeof(oldTask) == "thread" then
				return coroutine.status(oldTask) == "suspended" and task.cancel(oldTask) or nil
			end

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

	---Add a task without a specific ID and return the task.
	---@param task any
	---@return any
	function Maid:mark(task)
		self:add(task)
		return task
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
		local index, _task = next(tasks)

		while _task ~= nil do
			tasks[index] = nil

			if typeof(_task) == "thread" then
				if coroutine.status(_task) == "suspended" then
					task.cancel(_task)
				end
			else
				if type(_task) == "function" then
					_task()
				elseif typeof(_task) == "RBXScriptConnection" then
					_task:Disconnect()
				elseif typeof(_task) == "Instance" and _task:IsA("Tween") then
					_task:Pause()
					_task:Cancel()
					_task:Destroy()
				elseif _task.Destroy then
					_task:Destroy()
				elseif _task.detach then
					_task:detach()
				end
			end

			index, _task = next(tasks)
		end
	end

	-- Return Maid module.
	return Maid
end)()
