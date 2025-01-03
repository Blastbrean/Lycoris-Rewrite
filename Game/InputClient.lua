-- InputClient module.
local InputClient = {
	sprintFunctionCache = nil,
	rollFunctionCache = nil,
	oldWaitForContainer = nil,
}

-- Services.
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Check if table has non-boolean values.
---@param tbl table
---@return boolean
local function hasNonBooleans(tbl)
	for _, value in next, tbl do
		if typeof(value) == "boolean" then
			continue
		end

		return false
	end

	return true
end

---Fetch input data.
---@return table?
function InputClient.getInputData()
	local inputData = nil

	for _, connection in next, getconnections(runService.RenderStepped) do
		local func = connection.Function
		if not func then
			continue
		end

		local consts = debug.getconstants(func)
		if consts[249] ~= ".lastHBCheck" then
			continue
		end

		local upvalues = debug.getupvalues(func)

		---@note: Only table with boolean values is the input table. Find a better way to filter this?
		for _, upvalue in next, upvalues do
			if typeof(upvalue) ~= "table" or getrawmetatable(upvalue) then
				continue
			end

			if not hasNonBooleans(upvalue) then
				continue
			end

			inputData = upvalue
			break
		end
	end

	return inputData
end

---Initialize InputClient module.
function InputClient.init()
	-- Cache sprint and roll functions for the first time.
	-- @note: I sold my soul to the GC gods because there's no other way. Updates are quick though.
	for _, value in next, getgc() do
		if typeof(value) ~= "function" or iscclosure(value) then
			continue
		end

		local functionName = debug.getinfo(value).name

		if functionName == "Sprint" then
			InputClient.sprintFunctionCache = value
		end

		if functionName == "Roll" then
			InputClient.rollFunctionCache = value
		end

		if InputClient.sprintFunctionCache and InputClient.rollFunctionCache then
			break
		end
	end

	-- Intercept InputClient initializations and get updated functions.
	local effectReplicatorModule = require(replicatedStorage:WaitForChild("EffectReplicator"))

	InputClient.oldWaitForContainer = effectReplicatorModule.WaitForContainer

	effectReplicatorModule.WaitForContainer = function(...)
		local callerFunction = debug.getinfo(2).func

		for _, func in next, debug.getprotos(callerFunction) do
			local functionName = debug.getinfo(func).name

			if functionName == "Sprint" then
				InputClient.sprintFunctionCache = func
			end

			if functionName == "Roll" then
				InputClient.rollFunctionCache = func
			end
		end

		return InputClient.oldWaitForContainer(...)
	end
end

---Detach InputClient module.
function InputClient.detach()
	local effectReplicatorModule = require(replicatedStorage:WaitForChild("EffectReplicator"))
	effectReplicatorModule.WaitForContainer = InputClient.oldWaitForContainer
end

-- Return InputClient module.
return InputClient
