--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
repeat task.wait() until game:IsLoaded()
if shared.aerov4 then shared.aerov4:Uninject() end

local aerov4 -- Changed from vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and aerov4 then -- Changed from vape
		aerov4:CreateNotification('aerov4', 'Failed to load : '..err, 30, 'alert') -- Changed from Vape
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
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			-- Updated repository name and local path
			return game:HttpGet('https://raw.githubusercontent.com/wrealaero/NewAeroV5/'..readfile('newaerov4/profiles/commit.txt')..'/'..select(1, path:gsub('newaerov4/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

-- Changed folder names from newvape to newaerov4
for _, folder in {'newaerov4', 'newaerov4/games', 'newaerov4/profiles', 'newaerov4/assets', 'newaerov4/libraries', 'newaerov4/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.aerov4Developer then -- Changed from VapeDeveloper
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/wrealaero/NewAeroV5') -- Updated repository name
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newaerov4/profiles/commit.txt') and readfile('newaerov4/profiles/commit.txt') or '') ~= commit then -- Changed folder name
		wipeFolder('newaerov4') -- Changed folder name
		wipeFolder('newaerov4/games') -- Changed folder name
		wipeFolder('newaerov4/guis') -- Changed folder name
		wipeFolder('newaerov4/libraries') -- Changed folder name
	end
	writefile('newaerov4/profiles/commit.txt', commit) -- Changed folder name
end

aerov4 = loadstring(downloadFile('newaerov4/main.lua'), 'main')() -- Changed from vape and folder name
shared.aerov4 = aerov4 -- Changed from vape

if not shared.aerov4Independent then -- Changed from VapeIndependent
	loadstring(downloadFile('newaerov4/games/universal.lua'), 'universal')() -- Changed folder name
	if isfile('newaerov4/games/'..game.PlaceId..'.lua') then -- Changed folder name
		loadstring(readfile('newaerov4/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.aerov4Developer then -- Changed from VapeDeveloper
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/wrealaero/NewAeroV5/main/newaerov4/games/'..game.PlaceId..'.lua', true) -- Updated repository and folder name
			end)
			if suc and res ~= '404: Not Found' then
				writefile('newaerov4/games/'..game.PlaceId..'.lua', res) -- Changed folder name
				loadstring(res, tostring(game.PlaceId))(...)
			end
		end
	end
end

if not shared.aerov4reload then -- Changed from vapereload
	if not aerov4.Categories then return end -- Changed from vape
	if aerov4.Categories.Main.Options['GUI bind indicator'].Enabled then -- Changed from vape
		aerov4:CreateNotification('Finished Loading', aerov4.aerov4Button and 'Press the button in the top right to open GUI' or 'Press '..table.concat(aerov4.Keybind, ' + '):upper()..' to open GUI', 5) -- Changed from Vape and vape.VapeButton
	end
end
