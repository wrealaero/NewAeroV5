-- PerformanceLibrary.lua
-- Library for performance management and event handling in Roblox 
-- Provided by github user

local PerformanceLibrary = {}

function PerformanceLibrary.debounce(func, delay)
	local lastCalled = 0
	return function(...)
		local now = tick()
		if now - lastCalled >= delay then
			lastCalled = now
			func(...)
		end
	end
end

function PerformanceLibrary.throttle(func, rate)
	local interval = 1 / rate
	local lastCalled = 0
	return function(...)
		local now = tick()
		if now - lastCalled >= interval then
			lastCalled = now
			func(...)
		end
	end
end

function PerformanceLibrary.safeDestroy(instance)
	if instance and instance:IsA("Instance") and instance.Parent then
		instance:Destroy()
	end
end

function PerformanceLibrary.safeExecute(func, errorMessage)
    local success, err = pcall(func)
    if not success then
        warn(errorMessage .. ": " .. debug.traceback(tostring(err)))
    end
end

function PerformanceLibrary.memoryMonitor(threshold)
	local memoryUsage = collectgarbage("count") / 1024 -- Get memory in MB
	if memoryUsage > threshold then
		warn("Memory usage exceeded threshold: ", memoryUsage .. "MB")
	end
end

function PerformanceLibrary.optimizeLoops(iterations)
	return function(callback)
		local count = 0
		while count < iterations do
			callback(count)
			count = count + 1
		end
	end
end

function PerformanceLibrary.trackExecutionTime(func)
	return function(...)
		local startTime = tick()
		func(...)
		local endTime = tick()
		print("Execution time: ", endTime - startTime .. " seconds")
	end
end

function PerformanceLibrary.clearTable(tbl)
	for k in pairs(tbl) do
		tbl[k] = nil
	end
end

function PerformanceLibrary.limitInstanceCreation(maxInstances)
	local count = 0
	return function(createFunc)
		if count < maxInstances then
			createFunc()
			count = count + 1
		else
			warn("Instance creation limit reached!")
		end
	end
end

PerformanceLibrary.EventSys = {}
PerformanceLibrary.EventSys._events = {}
PerformanceLibrary.EventSys._remotes = {}

function PerformanceLibrary.EventSys:Connect(evtName, func)
	if not self._events[evtName] then
		self._events[evtName] = {}
	end
	table.insert(self._events[evtName], func)
end

function PerformanceLibrary.EventSys:Fire(evtName, ...)
	if self._events[evtName] then
		for _, func in ipairs(self._events[evtName]) do
			func(...)
		end
	end
end

function PerformanceLibrary.EventSys:Disconnect(evtName)
	if self._events[evtName] then
		self._events[evtName] = nil
	else
		warn(evtName .. " had no bound events to disconnect!")
	end
end

function PerformanceLibrary.EventSys:BindRemoteEvent(remoteName, onServer)
	local remote = self._remotes[remoteName] or Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = game.ReplicatedStorage
	self._remotes[remoteName] = remote

	if onServer then
		remote.OnServerEvent:Connect(function(player, ...)
			self:Fire(remoteName, player, ...)
		end)
	else
		remote.OnClientEvent:Connect(function(...)
			self:Fire(remoteName, ...)
		end)
	end
end

function PerformanceLibrary.EventSys:FireRemote(remoteName, ...)
	local remote = self._remotes[remoteName]
	if remote then
		if game.Players.LocalPlayer then
			remote:FireServer(...)
		else 
			remote:FireAllClients(...)
		end
	else
		warn("RemoteEvent " .. remoteName .. " does not exist!")
	end
end

function PerformanceLibrary.EventSys:FireRemoteToPlayer(player, remoteName, ...)
	local remote = self._remotes[remoteName]
	if remote then
		if game.Players:FindFirstChild(player.Name) then
			remote:FireClient(player, ...)
		else
			warn("Player " .. player.Name .. " not found for event " .. remoteName)
		end
	else
		warn("RemoteEvent " .. remoteName .. " does not exist!")
	end
end

function PerformanceLibrary.EventSys:WaitForEvent(evtName)
	while not self._events[evtName] do
		wait()
	end
end

return PerformanceLibrary