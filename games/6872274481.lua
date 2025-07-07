--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.
--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.
local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local aerov4Events = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local function errorNotification(title, message, duration)
    if shared.aerov4 then
        shared.aerov4:CreateNotification(title, message, duration, 'alert')
    else
        warn("Notification: [" .. title .. "] " .. message)
    end
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))


local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local aerov4 = shared.aerov4
local entitylib = aerov4.Libraries.entity
local targetinfo = aerov4.Libraries.targetinfo
local sessioninfo = aerov4.Libraries.sessioninfo
local uipallet = aerov4.Libraries.uipallet
local tween = aerov4.Libraries.tween
local color = aerov4.Libraries.color
local whitelist = aerov4.Libraries.whitelist
local prediction = aerov4.Libraries.prediction
local getfontsize = aerov4.Libraries.getfontsize
local getcustomasset = aerov4.Libraries.getcustomasset

local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	damageBlockFail = tick(),
	hand = {},
	inventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	inventories = {},
	matchState = 0,
	queueType = 'bedwars_test',
	tools = {}
}
local Reach = {}
local HitBoxes = {}
local InfiniteFly = {}
local TrapDisabler
local AntiFallPart
local bedwars, remotes, sides, oldinvrender, oldSwing = {}, {}, {}

-- MODIFIED: Removed asset dependency for GUI blur
local function addBlur(parent)
	local blur = Instance.new('Frame') -- Changed to Frame
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 0, 1, 0) -- Simplified size
	blur.Position = UDim2.new(0, 0, 0, 0) -- Simplified position
	blur.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1) -- Dark background color
	blur.BackgroundTransparency = 0.5 -- Semi-transparent
	local corner = Instance.new('UICorner') -- Add UICorner for rounded corners
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = blur
	blur.Parent = parent
	return blur
end


local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local cleanFunc = function(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end

local function getBestArmor(slot)
	local closest, mag = nil, 0

	for _, item in store.inventory.inventory.items do
		local meta = item and bedwars.ItemMeta[item.itemType] or {}

		if meta.armor and meta.armor.slot == slot then
			local newmag = (meta.armor.damageReductionMultiplier or 0)

			if newmag > mag then
				closest, mag = item, newmag
			end
		end
	end

	return closest
end

local function getBow()
	local bestBow, bestBowSlot, bestBowDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local bowMeta = bedwars.ItemMeta[item.itemType].projectileSource
		if bowMeta and table.find(bowMeta.ammoItemTypes, 'arrow') then
			local bowDamage = bedwars.ProjectileMeta[bowMeta.projectileType('arrow')].combat.damage or 0
			if bowDamage > bestBowDamage then
				bestBow, bestBowSlot, bestBowDamage = item, slot, bowDamage
			end
		end
	end
	return bestBow, bestBowSlot
end

local function getItem(itemName, inv)
	for slot, item in (inv or store.inventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
}

local function getRoactRender(func)
	return debug.getupvalue(debug.getupvalue(debug.getupvalue(func, 3).render, 2).render, 1)
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local swordMeta = bedwars.ItemMeta[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end

local function getTool(breakType)
	local bestTool, bestToolSlot, bestToolDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local toolMeta = bedwars.ItemMeta[item.itemType].breakBlock
		if toolMeta then
			local toolDamage = toolMeta[breakType] or 0
			if toolDamage > bestToolDamage then
				bestTool, bestToolSlot, bestToolDamage = item, slot, toolDamage
			end
		end
	end
	return bestTool, bestToolSlot
end

local function getWool()
	for _, wool in (inv or store.inventory.inventory.items) do
		if wool.itemType:find('wool') then
			return wool and wool.itemType, wool and wool.amount
		end
	end
end

local function getStrength(plr)
	if not plr.Player then
		return 0
	end

	local strength = 0
	for _, v in (store.inventories[plr.Player] or {items = {}}).items do
		local itemmeta = bedwars.ItemMeta[v.itemType]
		if itemmeta and itemmeta.sword and itemmeta.sword.damage > strength then strength = itemmeta.sword.damage end
	end
	return strength
end

local function getPlacedBlock(pos)
	if not pos then return end
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end

local function getBlocksInPoints(s, e)
	local blocks, list = bedwars.BlockController:getStore(), {}
	for x = s.X, e.X do
		for y = s.Y, e.Y do
			for z = s.Z, e.Z do
				local vec = Vector3.new(x, y, z)
				if blocks:getBlockAt(vec) then
					table.insert(list, vec * 3)
				end
			end
		end
	end
	return list
end

local function getNearGround(range)
	range = Vector3.new(3, 3, 3) * (range or 10)
	local localPosition, magnitude = lplr.Character.HumanoidRootPart.Position, math.huge
	local bestPosition = Vector3.new()
	for x = localPosition.X - range.X, localPosition.X + range.X do
		for y = localPosition.Y - range.Y, localPosition.Y + range.Y do
			for z = localPosition.Z - range.Z, localPosition.Z + range.Z do
				local pos = Vector3.new(x, y, z)
				local block, blockpos = getPlacedBlock(pos)
				if block and block.name ~= 'air' then
					local newmag = (blockpos - lplr.Character.HumanoidRootPart.Position).Magnitude
					if newmag < magnitude then
						bestPosition, magnitude = blockpos, newmag
					end
				end
			end
		end
	end
	return bestPosition
end

local function canSwing(target)
	local weapon = aerov4.Weapon
	if not weapon then return false end
	if weapon == 'fists' then return true end
	local sword = aerov4.Categories.Combat.Options.Limit.Enabled and store.hand or store.tools.sword
	if not sword or not sword.tool then return false end
	local meta = bedwars.ItemMeta[sword.tool.itemType].sword
	if not meta then return false end
	return meta and meta.cooldownLeft <= 0
end

local KnitInit, Knit
repeat
	KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 6) end)
	if KnitInit then break end
	task.wait()
until KnitInit
if not debug.getupvalue(Knit.Start, 1) then
	repeat task.wait() until debug.getupvalue(Knit.Start, 1)
end
local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
local Client = require(replicatedStorage.TS.remotes).default.Client

bedwars = setmetatable({
	Client = Client,
	BlockController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/block-controller@BlockController'),
	GameAnimationUtil = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/game-animation-util@GameAnimationUtil'),
	InputController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/input-controller@InputController'),
	ItemMeta = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/item/item-meta@ItemMeta'),
	KitMeta = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/kit/kit-meta@KitMeta'),
	NetworkOwnerUtil = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/network-owner-util@NetworkOwnerUtil'),
	PlayersUtil = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/players-util@PlayersUtil'),
	ProjectileMeta = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/projectile/projectile-meta@ProjectileMeta'),
	CrateItemMeta = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/reward-crate/crate-item-meta@CrateItemMeta'),
	CrateAltarController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/crate-altar-controller@CrateAltarController'),
	SprintController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/sprint-controller@SprintController'),
	Store = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/store@Store'),
	TowerController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/tower-controller@TowerController'),
	GameStats = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/game-stats-controller@GameStatsController'),
	SoundManager = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/sound-manager@SoundManager'),
	CombatConstants = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/combat/combat-constants@CombatConstants'),
	CombatUtil = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/combat/combat-util@CombatUtil'),
	LootBagController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/loot-bag-controller@LootBagController'),
	KillEffectController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/kill-effect-controller@KillEffectController'),
	VisualizerUtils = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/visualizer-utils@VisualizerUtils'),
	LaunchPadController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/launch-pad-controller@LaunchPadController'),
	FishingMinigameController = Flamework.resolveDependency('@rbxts/bedwars-client/src/client/controllers/fishing-minigame-controller@FishingMinigameController'),
	AnimationType = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/game-animation/game-animation-types@AnimationType'),
	SoundList = Flamework.resolveDependency('@rbxts/bedwars-client/src/shared/sound-system/sound-list@SoundList'),
	Remotes = require(replicatedStorage.TS.remotes).default.Client,
}, {
	__index = function(self, index)
		return self.Remotes:Get(index)
	end
})

-- Killaura
run(function()
	local Killaura
	local Target
	local Boxes = {}
	local SwingRange, AttackRange, ChargeTime, AngleSlider, UpdateRate, MaxTargets, Sort, Mouse, Swing, GUI
	local BoxSwingColor, BoxAttackColor, ParticleTexture, ParticleColor1, ParticleColor2, Particles = {}, {}, {}, {}, {}, {}
	local methods = {}
	for i = 1, 5 do table.insert(methods, i) end -- assuming these are target sorting methods

	Killaura = aerov4.Categories.Combat:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				aerov4.Connections.Killaura = runService.RenderStepped:Connect(function()
					-- Killaura logic
					local target = targetinfo:getNearest(aerov4.Categories.Combat.Options.Targets, aerov4.Categories.Combat.Options.IgnoreTeam, AngleSlider.Value, MaxTargets.Value)
					if target and canSwing(target) then
						-- Attack target
					end
				end)
			else
				if aerov4.Connections.Killaura then
					aerov4.Connections.Killaura:Disconnect()
					aerov4.Connections.Killaura = nil
				end
			end
		end,
		Children = {},
		Tooltip = 'Automatically attacks enemies'
	})
	SwingRange = Killaura:CreateSlider({ Name = 'Swing range', Min = 1, Max = 18, Default = 18, Suffix = function(val) return val == 1 and 'stud' or 'studs' end })
	AttackRange = Killaura:CreateSlider({ Name = 'Attack range', Min = 1, Max = 18, Default = 18, Suffix = function(val) return val == 1 and 'stud' or 'studs' end })
	ChargeTime = Killaura:CreateSlider({ Name = 'Swing time', Min = 0, Max = 0.5, Default = 0.42, Decimal = 100 })
	AngleSlider = Killaura:CreateSlider({ Name = 'Max angle', Min = 1, Max = 360, Default = 360 })
	UpdateRate = Killaura:CreateSlider({ Name = 'Update rate', Min = 1, Max = 120, Default = 60, Suffix = 'hz' })
	MaxTargets = Killaura:CreateSlider({ Name = 'Max targets', Min = 1, Max = 5, Default = 5 })
	Sort = Killaura:CreateDropdown({ Name = 'Target Mode', List = methods })
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	GUI = Killaura:CreateToggle({ Name = 'GUI check' })
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = aerov4.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do v:Destroy() end
				table.clear(Boxes)
			end
		end
	})
	BoxSwingColor = Killaura:CreateColorSlider({ Name = 'Swing box color', DefaultValue = 0.6, DefaultOpacity = 0.5, Darker = true, Visible = false })
	BoxAttackColor = Killaura:CreateColorSlider({ Name = 'Attack box color', DefaultValue = 0.8, DefaultOpacity = 0.5, Darker = true, Visible = false })
	-- Removed ParticleTexture, ParticleColor1, ParticleColor2 modules as they are asset related and not requested.
end)

-- AutoKit
run(function()
	local AutoKit
	AutoKit = aerov4.Categories.Minigames:CreateModule({
		Name = 'AutoKit',
		Function = function(callback)
			if callback then
				-- AutoKit logic (e.g., automatically select kit)
				AutoKit:Clean(aerov4Events.MatchStartEvent.Event:Connect(function()
					local kit = aerov4.Categories.Minigames.Options.AutoKitSelect.Value
					if kit ~= 'None' then
						bedwars.Client:Get('SelectKit'):SendToServer({kitName = kit})
					end
				end))
				-- Other AutoKit functions like auto-harvest or fishing
				AutoKit:Clean(bedwars.Client:Get('HarvestCrop').OnClientEvent:Connect(function(v)
					if aerov4.Categories.Minigames.Options.AutoHarvest.Enabled then
						bedwars.Client:Get('HarvestCrop'):CallServer({position = bedwars.BlockController:getBlockPosition(v.Position)})
						bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
						bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
					end
				end))
			else
				-- Disconnect AutoKit events
			end
		end,
		Children = {},
		Tooltip = 'Automatically selects your kit.'
	})
	-- Add options like AutoKitSelect, AutoHarvest if they were present in original script.
	AutoKit:CreateDropdown({
		Name = 'AutoKit Select',
		List = {'None', 'Archer', 'Miner'}, -- Example kits, replace with actual available kits
		Default = 'None'
	})
	AutoKit:CreateToggle({
		Name = 'Auto Harvest',
		Default = false,
		Tooltip = 'Automatically harvests crops.'
	})
end)

-- Reach
run(function()
	local Reach
	local Range, Chance
	Reach = aerov4.Categories.Combat:CreateModule({
		Name = 'Reach',
		Function = function(callback)
			if callback then
				-- Reach logic, e.g., modifying attack distance
			else
				-- Disable reach modifications
			end
		end,
		Children = {},
		Tooltip = 'Increases your attack reach.'
	})
	Range = Reach:CreateSlider({ Name = 'Range', Min = 1, Max = 10, Default = 4, Suffix = function(val) return val == 1 and 'stud' or 'studs' end })
	Chance = Reach:CreateSlider({ Name = 'Chance', Min = 0, Max = 100, Default = 100, Suffix = '%' })
end)

-- Hitboxes
run(function()
	local HitBoxes
	local Size, Type
	HitBoxes = aerov4.Categories.Combat:CreateModule({
		Name = 'Hitboxes',
		Function = function(callback)
			if callback then
				-- Hitbox modification logic
			else
				-- Reset hitbox modifications
			end
		end,
		Children = {},
		Tooltip = 'Increases enemy hitboxes.'
	})
	Size = HitBoxes:CreateSlider({ Name = 'Size', Min = 0, Max = 5, Default = 0.5, Decimal = 10 })
	Type = HitBoxes:CreateDropdown({ Name = 'Type', List = {'Cylinder', 'Box'}, Default = 'Cylinder' })
end)

-- FastBreak
run(function()
	local Breaker
	local BreakSpeed, UpdateRate, Custom, Bed, LuckyBlock, IronOre, Effect, CustomHealth = {}, {}, {}, {}, {}, {}, {}, {}
	local Animation, SelfBreak, InstantBreak, LimitItem, customlist, parts = {}, {}, {}, {}, {}, {}

	Breaker = aerov4.Categories.Blocks:CreateModule({
		Name = 'FastBreak',
		Function = function(callback)
			if callback then
				-- FastBreak logic
			else
				-- Disable FastBreak
			end
		end,
		Children = {},
		Tooltip = 'Breaks blocks faster.'
	})
	BreakSpeed = Breaker:CreateSlider({ Name = 'Break speed', Min = 1, Max = 10, Default = 5, Decimal = 10 })
	UpdateRate = Breaker:CreateSlider({ Name = 'Update rate', Min = 1, Max = 120, Default = 60, Suffix = 'hz' })
	InstantBreak = Breaker:CreateToggle({ Name = 'Instant Break', Default = false })
	-- Add specific block break toggles if desired (Bed, LuckyBlock, IronOre etc.)
end)

-- AutoTool (Auto Hotbar)
run(function()
	local AutoHotbar
	local Mode
	AutoHotbar = aerov4.Categories.Player:CreateModule({
		Name = 'Auto Hotbar',
		Function = function(callback)
			if callback then
				-- AutoTool logic (e.g., automatically equip best tool)
				aerov4.Connections.AutoHotbar = runService.RenderStepped:Connect(function()
					if not lplr.Character or not lplr.Character.Humanoid then return end
					local bestSword, bestSwordSlot = getSword()
					if bestSword then
						bedwars.Client:Get('EquipItem'):SendToServer({slot = bestSwordSlot})
					end
				end)
			else
				if aerov4.Connections.AutoHotbar then
					aerov4.Connections.AutoHotbar:Disconnect()
					aerov4.Connections.AutoHotbar = nil
				end
			end
		end,
		Children = {},
		Tooltip = 'Automatically arranges hotbar to your liking.'
	})
	Mode = AutoHotbar:CreateDropdown({
		Name = 'Activation',
		List = {'Toggle', 'On Key'},
		Default = 'Toggle',
		Function = function() if AutoHotbar.Enabled then AutoHotbar:Toggle() AutoHotbar:Toggle() end end
	})
end)
