---@class WarpDepleteUtil
local L = WarpDeplete.L
local Util = WarpDeplete.Util

function Util.formatForcesText()
	local completedColor = WarpDeplete.db.profile.completedForcesColor
	local forcesFormat = WarpDeplete.db.profile.forcesFormat
	local customForcesFormat = WarpDeplete.db.profile.customForcesFormat
	local currentPullFormat = WarpDeplete.db.profile.currentPullFormat
	local customCurrentPullFormat = WarpDeplete.db.profile.customCurrentPullFormat
	local pullCount = WarpDeplete.state.pullCount
	local currentCount = WarpDeplete.state.currentCount
	local totalCount = WarpDeplete.state.totalCount
	local completionTime = WarpDeplete.state.forcesCompleted and WarpDeplete.state.forcesCompletionTime or nil
	local splitsEnabled = WarpDeplete.db.profile.splitsEnabled
	local diff = WarpDeplete:GetCurrentDiff("forces")
	local splitFasterTimeColor = WarpDeplete.db.profile.splitFasterTimeColor
	local splitSlowerTimeColor = WarpDeplete.db.profile.splitSlowerTimeColor
	local align = WarpDeplete.db.profile.alignBarTexts

	local best = WarpDeplete:GetBestSplit("forces")
	local isStart = not WarpDeplete.state.timerStarted
	local showPbsDuringCountdown = WarpDeplete.db.profile.showPbsDuringCountdown

	local currentPercent = Util.calcForcesPercent((currentCount / totalCount) * 100)

	local percentText = ("%.2f"):format(currentPercent)
	local countText = ("%d"):format(currentCount)
	local totalCountText = ("%d"):format(totalCount)
	local remainingCountText = ("%d"):format(totalCount - currentCount)
	local remainingPercentText = ("%.2f"):format(100 - currentPercent)
	local result = forcesFormat ~= ":custom:" and forcesFormat or customForcesFormat

	result = result:gsub(":count:", countText)
	result = result:gsub(":percent:", percentText .. "%%")
	result = result:gsub(":totalcount:", totalCountText)
	result = result:gsub(":remainingcount:", remainingCountText)
	result = result:gsub(":remainingpercent:", remainingPercentText .. "%%")

	if pullCount > 0 then
		local pullText = currentPullFormat ~= ":custom:" and currentPullFormat or customCurrentPullFormat

		local pullPercent = (pullCount / totalCount) * 100
		local pullPercentText = ("%.2f"):format(pullPercent)
		local pullCountText = ("%d"):format(pullCount)

		local countAfterPull = currentCount + pullCount
		local countAfterPullText = ("%d"):format(countAfterPull)

		local remainingCountAfterPull = totalCount - countAfterPull
		if remainingCountAfterPull < 0 then
			remainingCountAfterPull = 0
		end
		local remainingCountAfterPullText = ("%d"):format(remainingCountAfterPull)

		local remainingPercentAfterPull = 100 - currentPercent - pullPercent
		if remainingPercentAfterPull < 0 then
			remainingPercentAfterPull = 0
		end
		local remainingPercentAfterPullText = ("%.2f"):format(remainingPercentAfterPull)

		local percentAfterPull = Util.calcForcesPercent(pullPercent + currentPercent)
		local pulledPercentText = ("%.2f"):format(percentAfterPull)

		pullText = result:gsub(":count:", pullCountText)
		pullText = result:gsub(":percent:", pullPercentText .. "%%")

		pullText = result:gsub(":countafterpull:", countAfterPullText)
		pullText = result:gsub(":remainingcountafterpull:", remainingCountAfterPullText)
		pullText = result:gsub(":percentafterpull:", pulledPercentText .. "%%")
		pullText = result:gsub(":remainingpercentafterpull:", remainingPercentAfterPullText .. "%%")

		result = result:gsub(":countafterpull:", countAfterPullText)
		result = result:gsub(":remainingcountafterpull:", remainingCountAfterPullText)
		result = result:gsub(":percentafterpull:", pulledPercentText .. "%%")
		result = result:gsub(":remainingpercentafterpull:", remainingPercentAfterPullText .. "%%")

		if pullText and #pullText > 0 then
			result = pullText .. "  " .. result
		end
	else
		result = result:gsub(":countafterpull:", countText)
		result = result:gsub(":remainingcountafterpull:", remainingCountText)
		result = result:gsub(":percentafterpull:", percentText .. "%%")
		result = result:gsub(":remainingpercentafterpull:", remainingPercentText .. "%%")
	end

	if completionTime then
		local completedText = ("[%s]"):format(Util.formatTime(completionTime))
		if align == "right" then
			result = "|c" .. completedColor .. completedText .. " " .. result .. "|r"
		else
			result = "|c" .. completedColor .. result .. " " .. completedText .. "|r"
		end

		if splitsEnabled and diff then
			local diffColor = diff <= 0 and splitFasterTimeColor or splitSlowerTimeColor
			local diffStr = "|c" .. diffColor .. Util.formatTime(diff, true) .. "|r"

			if align == "right" then
				result = diffStr .. " " .. result
			else
				result = result .. " " .. diffStr
			end
		end
	elseif splitsEnabled and isStart and showPbsDuringCountdown and best then
		local bestStr = "|c" .. splitFasterTimeColor .. Util.formatTime(best) .. "|r"
		if align == "right" then
			result = bestStr .. " " .. result
		else
			result = result .. " " .. bestStr
		end
	end

	return result or ""
end

-- NOTE: Functions with the _OnUpdate suffix are
-- called in the frame update loop and should not use any local vars.

function Util.getBarPercent_OnUpdate(bar, percent)
	if bar == 3 then
		return (percent >= 0.6 and 1.0) or (percent * (10 / 6))
	elseif bar == 2 then
		return (percent >= 0.8 and 1.0) or (percent < 0.6 and 0) or ((percent - 0.6) * 5)
	elseif bar == 1 then
		return (percent < 0.8 and 0) or ((percent - 0.8) * 5)
	end
end

local formatTime_OnUpdate_state = {}
function Util.formatTime_OnUpdate(time)
	formatTime_OnUpdate_state.timeMin = math.floor(time / 60)
	formatTime_OnUpdate_state.timeSec = math.floor(time - (formatTime_OnUpdate_state.timeMin * 60))
	return ("%d:%02d"):format(formatTime_OnUpdate_state.timeMin, formatTime_OnUpdate_state.timeSec)
end

function Util.formatDeathText(deaths)
	if not deaths then
		return ""
	end

	local timeAdded = deaths * WarpDeplete.state.deathPenalty
	local deathText = "" .. deaths
	if deaths == 1 then
		deathText = deathText .. " " .. L["Death"] .. " "
	else
		deathText = deathText .. " " .. L["Deaths"] .. " "
	end

	local timeAddedText = (
		(timeAdded == 0 and "")
		or (timeAdded < 60 and "(+" .. timeAdded .. "s)")
		or "(+" .. Util.formatDeathTimeMinutes(timeAdded) .. ")"
	)

	return deathText .. timeAddedText
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

function WarpDeplete:PrintDebug(str)
	if not self.db.global.DEBUG then
		return
	end
	self:Print("|cFF479AEDDEBUG|r " .. str)
end

function WarpDeplete:PrintDebugEvent(ev)
	self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
end

-- TODO(happens): Add missing locales
local affixNameFilters = {
	["enUS"] = { "Xal'atath's", "Challenger's", "Bargain:" },
	["deDE"] = { "Xal'ataths", "des Herausforderers", "Handel:" },
	["frFR"] = {},
	["itIT"] = {},
	["koKR"] = {},
	["zhCN"] = {},
	["zhTW"] = {},
	["ruRU"] = {},
	["esES"] = { "Xal'atath", "contendiente", "Trato", "de", ":" },
	["esMX"] = {},
	["ptBR"] = {},
}

local locale = GetLocale()
-- These should have the same names
if locale == "enGB" then
	locale = "enUS"
end

function Util.formatAffixName(name)
	local result = name
	local filters = affixNameFilters[locale] or {}
	for _, filter in ipairs(filters) do
		result = result:gsub(filter, "")
	end

	return result:match("^%s*(.-)%s*$")
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
