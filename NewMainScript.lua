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
			return game:HttpGet('https://raw.githubusercontent.com/wrealaero/NewAeroV5/'..readfile('newaerov4/profiles/commit.txt')..'/'..select(1, path:gsub('newaerov4/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after aerov4 updates.\n'..res
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

for _, folder in {'newaerov4', 'newaerov4/games', 'newaerov4/profiles', 'newaerov4/assets', 'newaerov4/libraries', 'newaerov4/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.Aerov4Developer then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/wrealaero/NewAeroV5')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newaerov4/profiles/commit.txt') and readfile('newaerov4/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newaerov4')
		wipeFolder('newaerov4/games')
		wipeFolder('newaerov4/guis')
		wipeFolder('newaerov4/libraries')
		-- Intentionally not wiping 'newaerov4/assets' as per your request to not use assets.
	end
	writefile('newaerov4/profiles/commit.txt', commit)
end

return loadstring(downloadFile('newaerov4/main.lua'), 'main')()
