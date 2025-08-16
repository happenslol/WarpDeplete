---@class WarpDepleteUtil
local L = WarpDeplete.L
local Util = WarpDeplete.Util

-- NOTE: Functions with the _OnUpdate suffix are
-- called in the frame update loop and should not use any local vars.

local formatTime_OnUpdate_state = {}
function Util.formatTime_OnUpdate(time)
	formatTime_OnUpdate_state.timeMin = math.floor(time / 60)
	formatTime_OnUpdate_state.timeSec = math.floor(time - (formatTime_OnUpdate_state.timeMin * 60))
	return ("%d:%02d"):format(formatTime_OnUpdate_state.timeMin, formatTime_OnUpdate_state.timeSec)
end

function Util.formatDeathText(deathCount, timeLost)
	if deathCount == 0 then
		return " "
	end

	local result = tostring(deathCount)
	if deathCount == 1 then
		result = result .. " " .. L["Death"]
	else
		result = result .. " " .. L["Deaths"]
	end

	if timeLost > 0 then
		if timeLost < 60 then
			result = result .. " (+" .. tostring(timeLost) .. "s)"
		else
			result = result .. " (+" .. Util.formatDeathTimeMinutes(timeLost) .. ")"
		end
	end

	return result
end

function Util.formatTime(time, sign)
	sign = sign or false
	local absTime = math.abs(time)
	local timeMin = math.floor(absTime / 60)
	local timeSec = math.floor(absTime - (timeMin * 60))
	local formatted = ("%d:%02d"):format(timeMin, timeSec)

	if sign then
		if time < 0 then
			return "-" .. formatted
		elseif time == 0 then
			return "±" .. formatted
		else
			return "+" .. formatted
		end
	end

	return formatted
end

function Util.formatTimeMilliseconds(time)
	local timeMin = math.floor(time / 60000)
	local timeSec = math.floor(time / 1000 - (timeMin * 60))
	local timeMilliseconds = math.floor(time - (timeMin * 60000) - (timeSec * 1000))
	return ("%d:%02d.%03d"):format(timeMin, timeSec, timeMilliseconds)
end

function Util.formatDeathTimeMinutes(time)
	local timeMin = math.floor(time / 60)
	local timeSec = math.floor(time - (timeMin * 60))
	return ("%d:%02d"):format(timeMin, timeSec)
end

function Util.hexToRGB(hex)
	if string.len(hex) == 8 then
		return tonumber("0x" .. hex:sub(3, 4)) / 255,
			tonumber("0x" .. hex:sub(5, 6)) / 255,
			tonumber("0x" .. hex:sub(7, 8)) / 255,
			tonumber("0x" .. hex:sub(1, 2)) / 255
	end

	return tonumber("0x" .. hex:sub(1, 2)) / 255,
		tonumber("0x" .. hex:sub(3, 4)) / 255,
		tonumber("0x" .. hex:sub(5, 6)) / 255
end

function Util.rgbToHex(r, g, b, a)
	r = math.ceil(255 * r)
	g = math.ceil(255 * g)
	b = math.ceil(255 * b)
	if not a then
		return string.format("FF%02x%02x%02x", r, g, b)
	end

	a = math.ceil(255 * a)
	return string.format("%02x%02x%02x%02x", a, r, g, b)
end

function Util.copy(obj, seen)
	if type(obj) ~= "table" then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do
		res[Util.copy(k, s)] = Util.copy(v, s)
	end
	return res
end

function Util.colorText(text, color)
	return "|c" .. color .. text .. "|r"
end

function Util.reverseList(list)
	table.sort(list, function(a, b)
		return a > b
	end)
end

-- Expects a table of guids to count values, as well as the total count value
-- Returns count, percent
function Util.calcPullCount(pull, total)
	local totalPull = 0
	for _, c in pairs(pull) do
		if c ~= "DEAD" then
			totalPull = totalPull + c
		end
	end

	local percent = total > 0 and totalPull / total or 0
	return totalPull, percent
end

function Util.calcForcesPercent(forcesPercent)
	return math.min(forcesPercent, 100.0)
end

function Util.joinStrings(strings, delim)
	local result = ""

	for i, s in ipairs(strings) do
		result = result .. s

		if i < #strings then
			result = result .. delim
		end
	end

	return result
end

function Util.showAlert(key, message, okMessage)
	StaticPopupDialogs[key] = {
		text = message,
		button1 = okMessage or "OK",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopup_Show(key)
end

function WarpDeplete:PrintDebug(...)
	if not self.db.global.DEBUG then
		return
	end
	self:Print("|cFF479AEDDEBUG|r", ...)
end

---@param str string
---@return string
function Util.trim(str)
	return str:match("^%s*(.-)%s*$")
end

local locale = GetLocale()
-- These should have the same names
if locale == "enGB" then
	locale = "enUS"
end

-- TODO: Add missing locales
local affixNameFilters = {
	["enUS"] = { "Xal'atath's", "Challenger's", "Bargain:" },
	["deDE"] = { "Xal'ataths", "des Herausforderers", "Handel:" },
	["frFR"] = {},
	["itIT"] = {},
	["koKR"] = { "잘아타스의 제안:", "도전자의" },
	["zhCN"] = { "萨拉塔斯的交易：", "挑战者的" },
	["zhTW"] = { "薩拉塔斯的交易：", "挑戰者的" },
	["ruRU"] = {},
	["esES"] = { "Xal'atath", "contendiente", "Trato", "de", ":" },
	["esMX"] = {},
	["ptBR"] = { "Barganha de Xal'atath:" },
}

---@param name string
---@return string
function Util.formatAffixName(name)
	local result = name
	local filters = affixNameFilters[locale] or {}
	for _, filter in ipairs(filters) do
		result = result:gsub(filter, "")
	end

	return Util.trim(result)
end

-- TODO: Add missing locales
local objectiveNameFilters = {
	["enUS"] = { "Defeated", "defeated" },
	["deDE"] = {},
	["frFR"] = {},
	["itIT"] = {},
	["koKR"] = {},
	["zhCN"] = {},
	["zhTW"] = {},
	["ruRU"] = {},
	["esES"] = {},
	["esMX"] = {},
	["ptBR"] = {},
}

---@param name string
---@return string
function Util.formatObjectiveName(name)
	local result = name
	local filters = objectiveNameFilters[locale] or {}
	for _, filter in ipairs(filters) do
		result = result:gsub(filter, "")
	end

	return Util.trim(result)
end

-- Taken from Reloe's M+ Timer
local mapIDToEJID = { -- MapChallengeMode = JournalInstance
	-- Cata
	[438] = { 68, "Vortex Pinnacle" },
	[456] = { 65, "Throne" },
	[507] = { 71, "Grim Batol" },

	-- MoP
	[2] = { 313, "Jade Serpent" },
	[56] = { 302, "Stromsout" },
	[57] = { 303, "Setting Sun" },
	[58] = { 312, "Shadow-Pan" },
	[59] = { 324, "Niuzao" },
	[60] = { 321, "Mogu'shan" },
	[76] = { 246, "Scholomance" },
	[77] = { 311, "Scarlet Halls" },
	[78] = { 316, "Monastery" },

	-- WoD
	[161] = { 476, "Skyreach" },
	[163] = { 385, "Slag Mines" },
	[164] = { 547, "Auchindoun" },
	[165] = { 537, "Shadowmoon" },
	[166] = { 536, "Grimrail" },
	[167] = { 559, "UBRS" },
	[168] = { 556, "Everbloom" },
	[169] = { 558, "Iron Docks" },

	-- Legion
	[197] = { 716, "Eye of Azshara" },
	[198] = { 762, "Darkheart" },
	[199] = { 740, "BRH" },
	[200] = { 721, "Halls of Valor" },
	[206] = { 767, "Neltharion's Lair" },
	[207] = { 707, "Vault" },
	[208] = { 727, "Maw of Souls" },
	[209] = { 726, "Arcway" },
	[210] = { 800, "Court of Stars" },
	[227] = { 860, "Kara: Lower" },
	[233] = { 900, "Cathedral" },
	[234] = { 860, "Kara: Upper" },
	[239] = { 945, "Seat" },

	-- BfA
	[244] = { 968, "Atal'Dazar" },
	[245] = { 1001, "Freehold" },
	[246] = { 1002, "Tol Dagor" },
	[247] = { 1012, "Motherlode" },
	[248] = { 1021, "Waycrest" },
	[249] = { 1041, "King's Rest" },
	[250] = { 1030, "Sethraliss" },
	[251] = { 1022, "Underrot" },
	[252] = { 1036, "Shrine" },
	[353] = { 1023, "Boralus" },
	[369] = { 1178, "Junkyard" },
	[370] = { 1178, "Workshop" },

	-- Shadowlands
	[375] = { 1184, "Mists" },
	[376] = { 1182, "Necrotic Wake" },
	[377] = { 1188, "Other Side" },
	[378] = { 1185, "Halls" },
	[379] = { 1183, "Plaguefall" },
	[380] = { 1189, "Sanguine" },
	[381] = { 1186, "Spires" },
	[382] = { 1187, "Theater" },
	[391] = { 1194, "Streets" },
	[392] = { 1194, "Gambit" },

	-- Dragonflight
	[399] = { 1202, "Ruby Pools" },
	[400] = { 1198, "Nokhud" },
	[401] = { 1203, "Azure Vault" },
	[402] = { 1201, "Academy" },
	[403] = { 1197, "Uldaman" },
	[404] = { 1199, "Neltharus" },
	[405] = { 1196, "Brackenhide" },
	[406] = { 1204, "Halls" },
	[463] = { 1209, "DotI: Lower" },
	[464] = { 1209, "DotI: Upper" },

	-- The War Within
	[499] = { 1267, "Sacred Flame" },
	[500] = { 1268, "The Rookery" },
	[501] = { 1269, "Stonevault" },
	[502] = { 1274, "City of Threads" },
	[503] = { 1271, "Ara-Kara" },
	[504] = { 1210, "Darkflame Cleft" },
	[505] = { 1270, "Dawnbreaker" },
	[506] = { 1272, "Cinderbrew Maedery" },
}

function Util.getEJInstanceID()
	local mapID = C_Map.GetBestMapForUnit("player")
	local instanceID = mapID and EJ_GetInstanceForMap(mapID) or nil -- find instanceid from encounter journal
	if instanceID and instanceID ~= 0 then
		return instanceID
	end

	-- We didn't get an instance id, try to use an id from the hardcoded table
	local challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()
	if challengeMapID and mapIDToEJID[challengeMapID] then
		return mapIDToEJID[challengeMapID][1]
	end

	return nil
end

-- Taken from WeakAuras2
function Util.utf8Sub(input, size)
	local output = ""
	if type(input) ~= "string" then
		return output
	end
	local i = 1
	while size > 0 do
		local byte = input:byte(i)
		if not byte then
			return output
		end
		if byte < 128 then
			-- ASCII byte
			output = output .. input:sub(i, i)
			size = size - 1
		elseif byte < 192 then
			-- Continuation bytes
			output = output .. input:sub(i, i)
		elseif byte < 244 then
			-- Start bytes
			output = output .. input:sub(i, i)
			size = size - 1
		end
		i = i + 1
	end

	-- Add any bytes that are part of the sequence
	while true do
		local byte = input:byte(i)
		if byte and byte >= 128 and byte < 192 then
			output = output .. input:sub(i, i)
		else
			break
		end
		i = i + 1
	end

	return output
end

---@param value number
---@param min number
---@param max number
function Util.clamp(value, min, max)
	return math.min(max, math.max(min, value))
end
