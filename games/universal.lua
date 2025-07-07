--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and aerov4 then
		aerov4:CreateNotification('Aerov4', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/wrealaero/NewAeroV5/'..readfile('newaerov4/profiles/commit.txt')..'/'..select(1, path:gsub('newaerov4/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.\\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	func()
end
local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local aerov4 = shared.aerov4
local tween = aerov4.Libraries.tween
local targetinfo = aerov4.Libraries.targetinfo
local getfontsize = aerov4.Libraries.getfontsize
local getcustomasset = aerov4.Libraries.getcustomasset
local addBlur = aerov4.Libraries.addBlur -- Use the modified addBlur from the GUI file

local TargetStrafeVector, SpiderShift, WaypointFolder
local Spider = {Enabled = false}
local Phase = {Enabled = false}

local function calculateMoveVector(vec)
	local c, s
	local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
	if R12 < 1 and R12 > -1 then
		c = R22
		s = R02
	else
		c = R00
		s = -R01 * math.sign(R12)
	end
	vec = Vector3.new((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
	return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

local function isFriend(plr, recolor)
	if aerov4.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(aerov4.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and aerov4.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(aerov4.Categories.Targets.ListEnabled, plr.Name) and true
end

local function canClick()
	local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
	for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	return (not aerov4.gui.ScaledGui.ClickGui.Visible) and (not inputService:GetFocusedTextBox())
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil
end

local function notif(...)
	return aerov4:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local visited, attempted, tpSwitch = {}, {}, false
local cacheExpire, cache = tick()
local function serverHop(pointer, filter)
	visited = shared.aerov4serverhoplist and shared.aerov4serverhoplist:split('/') or {}
	if not table.find(visited, game.JobId) then
		table.insert(visited, game.JobId)
	end
	if not pointer then
		notif('Aerov4', 'Searching for an available server.', 2)
	end

	local suc, httpdata = pcall(function()
		return cacheExpire < tick() and game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder='..(filter == 'Ascending' and 1 or 2)..'&excludeFullGames=true&limit=100', true) or cache
	end)
	if not suc then
		warn('Server hop failed: '..httpdata)
		return
	end
	cache = httpdata
	cacheExpire = tick() + 60

	local data = game:GetService('HttpService'):JSONDecode(httpdata)
	if data.data then
		local server = nil
		for _, v in data.data do
			if v.playing < v.maxPlayers and v.id ~= game.JobId and not table.find(visited, v.id) then
				server = v.id
				break
			end
		end

		if server then
			if not tpSwitch then
				tpSwitch = true
				notif('Aerov4', 'Found server: '..server..' - Teleporting...', 2)
			end
			table.insert(visited, server)
			shared.aerov4serverhoplist = table.concat(visited, '/')
			teleportService:TeleportToPlaceInstance(game.PlaceId, server, lplr)
		else
			if not attempted[filter] then
				attempted[filter] = true
				return serverHop(true, filter == 'Ascending' and 'Descending' or 'Ascending')
			end
			warn('No available servers found.')
			notif('Aerov4', 'No available servers found.', 2)
		end
	else
		warn('Invalid server data received.')
		notif('Aerov4', 'Invalid server data received.', 2)
	end
	tpSwitch = false
	attempted = {}
end

-- Modules from universal.lua
local TargetStrafeVector, SpiderShift, WaypointFolder
local Spider = {Enabled = false}
local Phase = {Enabled = false}
-- Other general modules you want to keep from universal.lua go here
-- Example: Speedmeter (Velocity)
run(function()
	local Speedmeter
	local label
	local Velocity
	local lastPosition = Vector3.new()
	local lastTick = tick()

	Speedmeter = aerov4.Categories.Render:CreateModule({
		Name = 'Speedmeter',
		Function = function(callback)
			if callback then
				aerov4.Connections.Speedmeter = runService.RenderStepped:Connect(function()
					local now = tick()
					local deltaTime = now - lastTick
					local currentPosition = lplr.Character and lplr.Character.HumanoidRootPart and lplr.Character.HumanoidRootPart.Position or Vector3.new()
					local distance = (currentPosition - lastPosition).Magnitude
					local velocity = distance / deltaTime
					if label then
						label.Text = string.format('%.1f sps', velocity)
					end
					lastPosition = currentPosition
					lastTick = now
				end)
			else
				if aerov4.Connections.Speedmeter then
					aerov4.Connections.Speedmeter:Disconnect()
					aerov4.Connections.Speedmeter = nil
				end
				if label then
					label.Text = '0 sps'
				end
			end
		end,
		Children = {},
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'A label showing the average velocity in studs'
	})
	Speedmeter:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	Speedmeter:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0 sps'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = Speedmeter.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)

run(function()
	local SilentAim local Target local Mode local Method local MethodRay local IgnoredScripts local Range local HitChance local HeadshotChance local AutoFire local AutoFireShootDelay local AutoFireMode local AutoFirePosition local Wallbang local CircleColor local CircleTransparency local CircleFilled local AutoDetect, PredictionAccuracy, IgnoreHumanoids, IgnorePlayers, IgnoreTeammates, IgnoreFriends
	local PredictionAccuracy = {}
	local Targets = {}
	local IgnorePlayers = {}
	local IgnoreTeammates = {}
	local IgnoreFriends = {}

	-- Silent Aim (AimAssist/ProjectileAimbot)
	SilentAim = aerov4.Categories.Combat:CreateModule({
		Name = 'Silent Aim',
		Function = function(callback)
			if callback then
				-- Connect events for silent aim
			else
				-- Disconnect events
			end
		end,
		Children = {},
		Tooltip = 'Silently aims at enemies'
	})

	-- Other aim assist related options (Range, HitChance, HeadshotChance, AutoFire, etc.) would be defined here as children of SilentAim.
	-- This includes `SilentAim:CreateSlider`, `SilentAim:CreateToggle`, etc.

	-- Entity ESP
	local Boxes = {}
	local Labels = {}
	local NameTags
	local BoxColor, NameColor, HPColor, DistanceCheck, DistanceLimit, IgnoreOthers

	EntityESP = aerov4.Categories.Render:CreateModule({
		Name = 'Entity ESP',
		Function = function(callback)
			if callback then
				aerov4.Connections.EntityESP = runService.RenderStepped:Connect(function()
					for i, ent in pairs(entitylib.List) do
						if ent.Character and ent.Character.Humanoid and ent.Character.Humanoid.Health > 0 then
							-- Render ESP box, name, health, distance
						end
					end
				end)
			else
				if aerov4.Connections.EntityESP then
					aerov4.Connections.EntityESP:Disconnect()
					aerov4.Connections.EntityESP = nil
				end
				for _, v in Boxes do v:Destroy() end
				table.clear(Boxes)
				for _, v in Labels do v:Destroy() end
				table.clear(Labels)
			end
		end,
		Children = {},
		Tooltip = 'Shows entities through walls.'
	})
	-- Other ESP options (BoxColor, NameColor, etc.) would be defined here.
end)

run(function()
	local TimeChanger
	local Value
	local old
	
	TimeChanger = aerov4.Legit:CreateModule({
		Name = 'Time Changer',
		Function = function(callback)
			if callback then
				old = lightingService.TimeOfDay
				aerov4.Connections.TimeChanger = runService.RenderStepped:Connect(function()
					lightingService.TimeOfDay = Value.Value
				end)
			else
				if aerov4.Connections.TimeChanger then
					aerov4.Connections.TimeChanger:Disconnect()
					aerov4.Connections.TimeChanger = nil
				end
				lightingService.TimeOfDay = old
			end
		end,
		Children = {}
	})
	Value = TimeChanger:CreateSlider({
		Name = 'Time',
		Min = 0,
		Max = 24,
		Default = 12,
		Decimal = 100
	})
end)
