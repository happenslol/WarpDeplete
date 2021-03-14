local Util = {}

function Util.formatForcesText(pullCount, currentCount, totalCount, completedTime)
  local currentPercent = (currentCount / totalCount) * 100
  if currentPercent > 100.0 then currentPercent = 100.0 end

  local result = ("%.2f%%"):format(currentPercent)

  if completedTime then
    local completedText = Util.formatTime(completedTime)
    result = "|cFF00FF24" .. completedText .. " - " .. result .. "|r"
  end

  if pullCount > 0 then
    local pullPercent = (pullCount / totalCount) * 100
    result = ("(+%.2f%%)"):format(pullPercent) .. "  " .. result
  end

  return result
end

function Util.getBarPercent(bar, percent)
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
  if deaths == 1 then deathText = deathText .. " Death "
  else deathText = deathText .. " Deaths " end
  
  local timeAddedText = (
    (timeAdded == 0 and "") or
    (timeAdded < 60 and "(+" .. timeAdded .. "s)") or
    "(+" .. Util.formatDeathTimeMinutes(timeAdded) .. ")"
  )

  return deathText..timeAddedText
end

function Util.formatTime(time)
  local timeMin = math.floor(time / 60)
  local timeSec = math.floor(time - (timeMin * 60))
  return ("%d:%02d"):format(timeMin, timeSec)
end

function Util.formatDeathTimeMinutes(time)
  local timeMin = math.floor(time / 60)
  local timeSec = math.floor(time - (timeMin * 60))
  return ("%d:%02d"):format(timeMin, timeSec)
end

function Util.hexToRGB(hex)
  local hex = hex:gsub("#","")
  if hex:len() == 3 then
    return (tonumber("0x"..hex:sub(1,1))*17)/255, (tonumber("0x"..hex:sub(2,2))*17)/255, (tonumber("0x"..hex:sub(3,3))*17)/255
  else
    return tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255
  end
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

WarpDeplete.Util = Util