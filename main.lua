--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.
repeat task.wait() until game:IsLoaded()
if shared.aerov4 then shared.aerov4:Uninject() end

if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local aerov4
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and aerov4 then
		aerov4:CreateNotification('Aerov4', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

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

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.')) == 1 then
			delfile(file)
		end
	end
end

local function clean(module)
	if not module then return end
	for _, v in module.Connections or {} do
		if v.Connected then
			v:Disconnect()
		end
	end
	for _, v in module.Children or {} do
		v:Destroy()
	end
	if module.Object and module.Object.Parent then
		module.Object:Destroy()
	end
	if module.Image and module.Image.Parent then
		module.Image:Destroy()
	end
	if module.Folder and module.Folder.Parent then
		module.Folder:Destroy()
	end
	if module.Event then
		module.Event:Destroy()
	end
	if module.RunningThread and typeof(module.RunningThread) == 'thread' then
		task.cancel(module.RunningThread)
	end
	if module.Timer then
		module.Timer:Destroy()
	end
	if module.Cleaned then
		module.Cleaned(module)
	end
	table.clear(module)
end

local function Uninject()
	if not aerov4 then return end
	for _, v in aerov4.Windows do
		v:Destroy()
	end
	table.clear(aerov4.Windows)
	for _, v in aerov4.Modules do
		clean(v)
	end
	table.clear(aerov4.Modules)
	for _, v in aerov4.Connections do
		if v.Connected then
			v:Disconnect()
		end
	end
	table.clear(aerov4.Connections)
	for _, v in aerov4.Libraries do
		if v.stop then
			v:stop()
		end
		if v.Connections then
			for _, v2 in v.Connections do
				v2:Disconnect()
			end
		end
	end
	if aerov4.Save and aerov4.Categories.Main.Options['Auto save'].Enabled then
		aerov4:Save()
	end
	shared.aerov4 = nil
end

local function CreateNotification(title, message, duration, style)
	local notification = Instance.new('ScreenGui')
	notification.Name = 'Notification'
	notification.DisplayOrder = 99999999
	notification.IgnoreGuiInset = true
	local frame = Instance.new('Frame')
	frame.Size = UDim2.new(0, 300, 0, 70)
	frame.Position = UDim2.new(1, -310, 0, 10)
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = notification
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = frame
	local titleLabel = Instance.new('TextLabel')
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.Position = UDim2.new(0, 0, 0, 5)
	titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Top
	titleLabel.Text = title
	titleLabel.Parent = frame
	local messageLabel = Instance.new('TextLabel')
	messageLabel.Size = UDim2.new(1, 0, 0, 40)
	messageLabel.Position = UDim2.new(0, 0, 0, 25)
	messageLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	messageLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
	messageLabel.TextScaled = true
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.Text = message
	messageLabel.Parent = frame

	notification.Parent = playersService.LocalPlayer:WaitForChild('PlayerGui')

	local tween = game:GetService('TweenService'):Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -310, 0, 10)})
	tween:Play()
	tween.Completed:Wait()

	task.delay(duration, function()
		local tweenOut = game:GetService('TweenService'):Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 0, 10)})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		notification:Destroy()
	end)
end

aerov4 = {
	Uninject = Uninject,
	CreateNotification = CreateNotification,
	Connections = {},
	Windows = {},
	Modules = {},
	Libraries = {},
	Categories = setmetatable({}, {
		__index = function(self, index)
			local category = {
				Name = index,
				Modules = {},
				Options = {},
				Connections = {},
				CreateModule = function(rself, tab)
					tab.Category = rself
					rself.Modules[tab.Name] = tab
					table.insert(aerov4.Modules, tab)
					return tab
				end,
				CreateOption = function(rself, tab)
					rself.Options[tab.Name] = tab
					return tab
				end,
				Connections = {},
				Clean = function(rself, func)
					if func.Connected then
						table.insert(rself.Connections, func)
					else
						table.insert(aerov4.Connections, func)
					end
				end,
			}
			self[index] = category
			return self[index]
		end
	}),
	Keybind = {Enum.KeyCode.RightControl},
	Save = function(self)
		local profile = {}
		for _, cat in self.Categories do
			profile[cat.Name] = {}
			for _, mod in cat.Modules do
				profile[cat.Name][mod.Name] = {
					Enabled = mod.Enabled or false
				}
				for _, v in mod.Children or {} do
					profile[cat.Name][mod.Name][v.Name] = v.Value or nil
				end
			end
			for _, opt in cat.Options do
				profile[cat.Name][opt.Name] = {
					Enabled = opt.Enabled or false
				}
				for _, v in opt.Children or {} do
					profile[cat.Name][opt.Name][v.Name] = v.Value or nil
				end
			end
		end
		writefile('newaerov4/profiles/current.json', game:GetService('HttpService'):JSONEncode(profile))
	end,
	Load = function(self)
		if isfile('newaerov4/profiles/current.json') then
			local profile = game:GetService('HttpService'):JSONDecode(readfile('newaerov4/profiles/current.json'))
			for catName, catData in profile do
				for modName, modData in catData do
					local category = self.Categories[catName]
					if category then
						local module = category.Modules[modName] or category.Options[modName]
						if module then
							if modData.Enabled ~= nil then
								module.Enabled = modData.Enabled
								if module.Function then
									module.Function(module.Enabled)
								end
							end
							for childName, childValue in modData do
								if childName ~= 'Enabled' then
									local child = module.Children[childName]
									if child then
										child.Value = childValue
										if child.Function then
											child.Function(child.Value)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
}
shared.aerov4 = aerov4

run(function()
	local profile = isfile('newaerov4/profiles/load.txt') and readfile('newaerov4/profiles/load.txt') or 'current'
	if isfile('newaerov4/profiles/'..profile..'.json') then
		aerov4:Load()
	end
	playersService.LocalPlayer.CharacterAdded:Connect(function(char)
		local old
		old = char.AncestryChanged:Connect(function()
			if not char.Parent then
				old:Disconnect()
				aerov4:Save()
				if aerov4.Categories.Main.Options['Auto teleport'].Enabled then
					local profile = isfile('newaerov4/profiles/teleport.txt') and readfile('newaerov4/profiles/teleport.txt') or 'current'
					local teleportScript = 'loadstring(game:HttpGet(\"https://raw.githubusercontent.com/wrealaero/NewAeroV5/'..readfile('newaerov4/profiles/commit.txt')..'/NewMainScript.lua\", true))()'
					queue_on_teleport(teleportScript)
				end
			end
		end)
	end)

	if not shared.aerov4reload then
		if not aerov4.Categories then return end
		if aerov4.Categories.Main.Options['GUI bind indicator'].Enabled then
			aerov4:CreateNotification('Finished Loading', aerov4.Aerov4Button and 'Press the button in the top right to open GUI' or 'Press '..table.concat(aerov4.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end)

if not isfile('newaerov4/profiles/gui.txt') then
	writefile('newaerov4/profiles/gui.txt', 'new')
end
local gui = readfile('newaerov4/profiles/gui.txt')

if not isfolder('newaerov4/assets/'..gui) then
	makefolder('newaerov4/assets/'..gui)
end
aerov4 = loadstring(downloadFile('newaerov4/guis/'..gui..'.lua'), 'gui')() -- Change this to the GUI file you create
shared.aerov4 = aerov4

if not shared.Aerov4Independent then
	loadstring(downloadFile('newaerov4/games/universal.lua'), 'universal')()
	if isfile('newaerov4/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('newaerov4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))()
	else
		if not shared.Aerov4Developer then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/wrealaero/NewAeroV5/'..readfile('newaerov4/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				writefile('newaerov4/games/'..game.PlaceId..'.lua', res)
				loadstring(res, tostring(game.PlaceId))()
			end
		end
	end
end
