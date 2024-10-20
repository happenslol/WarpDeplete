local Util = WarpDeplete.Util

-- Format: "time|name|class"
-- time: Death time in seconds
-- name: Player name as string
-- class: Class ID of the player (as returned by `select(2, UnitClass("player"))`)
local deathBroadcastPrefix = "WDP_Death"

local requestMessage = "pls"

function WarpDeplete:RegisterComms()
  self:RegisterComm(deathBroadcastPrefix, "OnDeathBroadcast")
end

function WarpDeplete:BroadcastDeath()
  local time = self.timerState.current
  local playerName = UnitName("player")
  local playerClass = select(2, UnitClass("player"))

  self:AddDeathDetails(time, playerName, playerClass)

  local messageTable = {tostring(time), playerName, playerClass}
  local message = Util.joinStrings(messageTable, "|")
  self:PrintDebug("Sending death broadcast")
  self:SendCommMessage(deathBroadcastPrefix, message, "PARTY", nil, "ALERT")
end

function WarpDeplete:OnDeathBroadcast(prefix, message, dist, sender)
  if message ~= requestMessage or sender == GetUnitName("player", false) then return end
  self:PrintDebug("Received death broadcast from other player: " .. message)
  local timeRaw, name, class = strsplit("|", message)
  local time = tonumber(timeRaw)

  self:AddDeathDetails(time, name, class)
end