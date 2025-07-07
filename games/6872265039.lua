--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local aerov4 = shared.aerov4
local entitylib = aerov4.Libraries.entity
local sessioninfo = aerov4.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return aerov4:CreateNotification(...)
end

local function dumpRemote(tab)
	local ind = table.find(tab, 'Client')
	return ind and tab[ind + 1] or ''
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


-- Sprint
run(function()
	local Sprint
	Sprint = aerov4.Categories.Player:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				-- Sprint logic
				local old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function() end
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
				aerov4.Connections.Sprint = runService.RenderStepped:Connect(function()
					-- Ensure sprinting is active
					bedwars.SprintController:startSprinting()
				end)
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function()
					task.delay(0.1, function() bedwars.SprintController:stopSprinting() end)
				end))
			else
				if aerov4.Connections.Sprint then
					aerov4.Connections.Sprint:Disconnect()
					aerov4.Connections.Sprint = nil
				end
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)
