--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))
local lightingService = cloneref(game:GetService('Lighting'))

local lplr = playersService.LocalPlayer
local aerov4 = shared.aerov4
local entitylib = aerov4.Libraries.entity
local sessioninfo = aerov4.Libraries.sessioninfo
local uipallet = aerov4.Libraries.uipallet
local tween = aerov4.Libraries.tween
local color = aerov4.Libraries.color
local whitelist = aerov4.Libraries.whitelist
local prediction = aerov4.Libraries.prediction
local getfontsize = aerov4.Libraries.getfontsize
local targetinfo = aerov4.Libraries.targetinfo

-- ✅ Notification fallback (debug)
local function errorNotification(title, message, duration)
	if aerov4.CreateNotification then
		aerov4:CreateNotification(title, message, duration, "alert")
	else
		warn("Notification: [" .. title .. "] " .. message)
	end
end

local function notif(...) errorNotification(...) end

-- ✅ GUI Blur Replacement (no assets)
local function addBlur(parent)
	local blur = Instance.new('Frame')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 0, 1, 0)
	blur.Position = UDim2.new(0, 0, 0, 0)
	blur.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	blur.BackgroundTransparency = 0.5
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = blur
	blur.Parent = parent
	return blur
end

aerov4.Libraries.addBlur = addBlur

-- ✅ GUI Object
aerov4.gui = Instance.new('ScreenGui')
aerov4.gui.Name = "Aerov4GUI"
aerov4.gui.ResetOnSpawn = false
aerov4.gui.IgnoreGuiInset = true
aerov4.gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
aerov4.gui.Parent = lplr:WaitForChild('PlayerGui')

aerov4.gui.ScaledGui = Instance.new('Frame')
aerov4.gui.ScaledGui.Name = "ScaledGui"
aerov4.gui.ScaledGui.Size = UDim2.new(0, 500, 0, 350)
aerov4.gui.ScaledGui.Position = UDim2.new(0.5, -250, 0.5, -175)
aerov4.gui.ScaledGui.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aerov4.gui.ScaledGui.BorderSizePixel = 0
aerov4.gui.ScaledGui.Parent = aerov4.gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = aerov4.gui.ScaledGui

addBlur(aerov4.gui.ScaledGui)

-- ✅ Framework for creating GUI categories/modules
aerov4.Categories = {}
aerov4.Modules = {}
aerov4.Connections = {}

function aerov4:CreateWindow()
	local window = { Categories = {} }

	function window:CreateCategory(name)
		local category = {
			Name = name,
			Modules = {},
			Options = {},
			ListEnabled = {}
		}

		function category:CreateModule(moduleData)
			local module = {
				Name = moduleData.Name,
				Enabled = false,
				Function = moduleData.Function or function() end,
				Tooltip = moduleData.Tooltip or "",
				Cleanups = {},
				Category = name
			}

			function module:Enable()
				module.Enabled = true
				module:Function(true)
			end

			function module:Disable()
				module.Enabled = false
				module:Function(false)
				for _, cleanup in ipairs(module.Cleanups) do
					if typeof(cleanup) == "RBXScriptConnection" then
						cleanup:Disconnect()
					elseif typeof(cleanup) == "Instance" then
						cleanup:Destroy()
					elseif typeof(cleanup) == "function" then
						pcall(cleanup)
					end
				end
				module.Cleanups = {}
			end

			function module:Clean(obj)
				table.insert(module.Cleanups, obj)
			end

			function module:CreateToggle(data)
				local toggle = {
					Name = data.Name,
					Default = data.Default or false,
					Function = data.Function or function() end
				}
				toggle.Enabled = toggle.Default
				module[toggle.Name:gsub(" ", "")] = toggle
				return toggle
			end

			function module:CreateSlider(data)
				local slider = {
					Name = data.Name,
					Min = data.Min,
					Max = data.Max,
					Default = data.Default,
					Value = data.Default,
					Function = data.Function or function() end,
					Suffix = data.Suffix
				}
				module[slider.Name:gsub(" ", "")] = slider
				return slider
			end

			category.Modules[module.Name] = module
			aerov4.Modules[module.Name] = module
			return module
		end

		window.Categories[name] = category
		aerov4.Categories[name] = category
		return category
	end

	return window
end

-- ✅ Create your top-level categories (like vape.Categories)
local mainWindow = aerov4:CreateWindow()
mainWindow:CreateCategory("Combat")
mainWindow:CreateCategory("Blatant")
mainWindow:CreateCategory("Render")
mainWindow:CreateCategory("Utility")
mainWindow:CreateCategory("World")
mainWindow:CreateCategory("Misc")
mainWindow:CreateCategory("Exploit")
mainWindow:CreateCategory("Player")
mainWindow:CreateCategory("Friends")
mainWindow:CreateCategory("Targets")
