local Util = WarpDeplete.Util
local L = WarpDeplete.L

--NOTE(happens): functions with the _OnUpdate suffix are
-- called in the frame update loop and should not use any local vars.

function Util.formatForcesText(
  completedColor,
  forcesFormat, customForcesFormat, unclampForcesPercent,
  currentPullFormat, customCurrentPullFormat,
  pullCount, currentCount, totalCount, completedTime
)
  local currentPercent = Util.calcForcesPercent((currentCount / totalCount) * 100, unclampForcesPercent)

  local percentText = ("%.2f"):format(currentPercent)
  local countText = ("%d"):format(currentCount)
  local totalCountText = ("%d"):format(totalCount)
  local remainingCountText = ("%d"):format(totalCount-currentCount)
  local remainingPercentText = ("%.2f"):format(100-currentPercent)
  local result = forcesFormat ~= ":custom:" and forcesFormat or customForcesFormat

  result = gsub(result, ":count:", countText)
  result = gsub(result, ":percent:", percentText .. "%%")
  result = gsub(result, ":totalcount:", totalCountText)
  result = gsub(result, ":remainingcount:", remainingCountText)
  result = gsub(result, ":remainingpercent:", remainingPercentText .. "%%")

  if pullCount > 0 then
    local pullText = currentPullFormat ~= ":custom:" and currentPullFormat or customCurrentPullFormat

    local pullPercent = (pullCount / totalCount) * 100
    local pullPercentText = ("%.2f"):format(pullPercent)
    local pullCountText = ("%d"):format(pullCount)

    local countAfterPull = currentCount + pullCount
    local countAfterPullText = ("%d"):format(countAfterPull)

    local remainingCountAfterPull = totalCount - countAfterPull
    if remainingCountAfterPull < 0 then remainingCountAfterPull = 0 end
    local remainingCountAfterPullText = ("%d"):format(remainingCountAfterPull)

    local remainingPercentAfterPull = 100-currentPercent-pullPercent
    if remainingPercentAfterPull < 0 then remainingPercentAfterPull = 0 end
    local remainingPercentAfterPullText = ("%.2f"):format(remainingPercentAfterPull)

    local percentAfterPull = Util.calcForcesPercent(pullPercent + currentPercent, unclampForcesPercent)
    local pulledPercentText = ("%.2f"):format(percentAfterPull)

    pullText = gsub(pullText, ":count:", pullCountText)
    pullText = gsub(pullText, ":percent:", pullPercentText .. "%%")

    pullText = gsub(pullText, ":countafterpull:", countAfterPullText)
    pullText = gsub(pullText, ":remainingcountafterpull:", remainingCountAfterPullText)
    pullText = gsub(pullText, ":percentafterpull:", pulledPercentText .. "%%")
    pullText = gsub(pullText, ":remainingpercentafterpull:", remainingPercentAfterPullText .. "%%")

    result = gsub(result, ":countafterpull:", countAfterPullText)
    result = gsub(result, ":remainingcountafterpull:", remainingCountAfterPullText)
    result = gsub(result, ":percentafterpull:", pulledPercentText .. "%%")
    result = gsub(result, ":remainingpercentafterpull:", remainingPercentAfterPullText .. "%%")

    if pullText and #pullText > 0 then
      result = pullText .. "  " .. result
    end
  else
    result = gsub(result, ":countafterpull:", countText)
    result = gsub(result, ":remainingcountafterpull:", remainingCountText)
    result = gsub(result, ":percentafterpull:", percentText .. "%%")
    result = gsub(result, ":remainingpercentafterpull:", remainingPercentText .. "%%")
  end

  if completedTime and result then
    local completedText = ("[%s] "):format(Util.formatTime(completedTime))
    result = "|c" .. completedColor .. completedText .. result .. "|r"
  end

  return result or ""
end

function Util.getBarPercent_OnUpdate(bar, percent)
  if bar == 3 then
    return (percent >= 0.6 and 1.0) or (percent * (10 / 6))
  elseif bar == 2 then
    return (percent >= 0.8 and 1.0) or (percent < 0.6 and 0) or ((percent - 0.6) * 5)
  elseif bar == 1 then
    return (percent < 0.8 and 0) or ((percent - 0.8) * 5)
  end
end

function Util.formatDeathText(deaths)
  if not deaths then return "" end

  local timeAdded = deaths * 5
  local deathText = "" .. deaths
  if deaths == 1 then deathText = deathText .. " " .. L["Deaths"] .. " "
  else deathText = deathText .. " " .. L["Deaths"] .. " " end
  
  local timeAddedText = (
    (timeAdded == 0 and "") or
    (timeAdded < 60 and "(+" .. timeAdded .. "s)") or
    "(+" .. Util.formatDeathTimeMinutes(timeAdded) .. ")"
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

local formatTime_OnUpdate_state = {}
function Util.formatTime_OnUpdate(time)
  formatTime_OnUpdate_state.timeMin = math.floor(time / 60)
  formatTime_OnUpdate_state.timeSec = math.floor(time - (formatTime_OnUpdate_state.timeMin * 60))
  return ("%d:%02d"):format(formatTime_OnUpdate_state.timeMin, formatTime_OnUpdate_state.timeSec)
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
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[Util.copy(k, s)] = Util.copy(v, s) end
  return res
end

function Util.colorText(text, color)
  return "|c" .. color .. text .. "|r"
end

function Util.reverseList(list)
  table.sort(list, function(a, b) return a > b end)
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

function Util.calcForcesPercent(forcesPercent, unclampForcesPercent)
  -- Returned forces percent will be floored to 100 if unclampForcesPercent is falsy
  if unclampForcesPercent then
    return forcesPercent
  end
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
    preferredIndex = 3
  }

  StaticPopup_Show(key)
end

Util.MapIDToInstanceID = {
  [1677] = 1188, -- De Other Side
  [1678] = 1188, -- De Other Side
  [1679] = 1188, -- De Other Side
  [1680] = 1188, -- De Other Side
  [1669] = 1184, -- Mists of Tirna Scithe
  [1697] = 1183, -- Plaguefall
  [1675] = 1189, -- Sanguine Depths
  [1676] = 1189, -- Sanguine Depths
  [1692] = 1186, -- Spires of Ascension
  [1693] = 1186, -- Spires of Ascension
  [1694] = 1186, -- Spires of Ascension
  [1695] = 1186, -- Spires of Ascension
  [1666] = 1182, -- The Necrotic Wake
  [1667] = 1182, -- The Necrotic Wake
  [1668] = 1182, -- The Necrotic Wake
  [1683] = 1187, -- Theater of Pain
  [1684] = 1187, -- Theater of Pain
  [1685] = 1187, -- Theater of Pain
  [1686] = 1187, -- Theater of Pain
  [1687] = 1187, -- Theater of Pain
  [1663] = 1185, -- Halls of Atonement
  [1664] = 1185, -- Halls of Atonement
  [1665] = 1185, -- Halls of Atonement
}

function WarpDeplete:PrintDebug(str)
  if not self.db.global.DEBUG then return end
  self:Print("|cFF479AEDDEBUG|r " .. str)
end

function WarpDeplete:PrintDebugGlobalEvent(ev)
  self:PrintDebug("|cFFA134EBG_EVENT|r " .. ev)
end

function WarpDeplete:PrintDebugEvent(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
end
