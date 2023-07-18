local Util = WarpDeplete.Util


-- Format: "current|type"
-- current: number
-- type: "blizz" or "gettime", depending on whether or not the time
--       was retrieved from the built-in blizzard timer or the GetTime method.
local timerResponsePrefix = "WDP_TimerRes"
local timerRequestPrefix = "WDP_TimerReq"

-- Format: "objTime1|objectTime2|objTimeN"
-- objTime: Objective completion times separated by |, as number of seconds from start.
-- Should be -1 if the objective has not been completed.
local objectiveResponsePrefix = "WDP_ObjRes"
local objectiveRequestPrefix = "WDP_ObjReq"

-- Format: "time|name|class"
-- time: Death time in seconds
-- name: Player name as string
-- class: Class ID of the player (as returned by `select(2, UnitClass("player"))`)
local deathBroadcastPrefix = "WDP_Death"

local requestMessage = "pls"

function WarpDeplete:RegisterComms()
  self:RegisterComm(timerRequestPrefix, "OnTimerSyncRequest")
  self:RegisterComm(timerResponsePrefix, "OnTimerSyncResponse")
  self:RegisterComm(objectiveRequestPrefix, "OnObjectiveSyncRequest")
  self:RegisterComm(objectiveResponsePrefix, "OnObjectiveSyncResponse")
  self:RegisterComm(deathBroadcastPrefix, "OnDeathBroadcast")
end

function WarpDeplete:RequestTimerSync()
  self:PrintDebug("Requesting timer sync")
  self:SendCommMessage(timerRequestPrefix, requestMessage, "PARTY", nil, "ALERT")
end

function WarpDeplete:RequestObjectiveSync()
  self:PrintDebug("Requesting objective sync")
  self:SendCommMessage(objectiveRequestPrefix, requestMessage, "PARTY", nil, "ALERT")
end

function WarpDeplete:OnTimerSyncRequest(prefix, message, dist, sender)
  if message ~= requestMessage or sender == GetUnitName("player", false) then return end

  local text = ("%d"):format(self.timerState.current)
  if self.timerState.isBlizzardTimer then
    text = text .. "|blizz"
  else
    text = text .. "|gettime"
  end

  self:SendCommMessage(timerResponsePrefix, text, "WHISPER", sender, "ALERT")
end

function WarpDeplete:OnTimerSyncResponse(prefix, message, dist, sender)
  local currentRaw, typeRaw = strsplit("|", message)
  local isBlizzard = typeRaw == "blizz"
  local current = tonumber(currentRaw)

  self:PrintDebug("Received time from " .. sender .. ": "
    .. tonumber(current) .. ", type: " .. typeRaw)
  
  if self.timerState.isBlizzardTimer and not isBlizzard then
    self:PrintDebug("Updating timer")
    local deaths = C_ChallengeMode.GetDeathCount()
    self.timerState.current = current
    self.timerState.deaths = deaths
    local trueTime = current - deaths * 5
    self.timerState.startOffset = trueTime
    self.timerState.startTime = GetTime()
    self.timerState.isBlizzardTimer = false
  end
end

function WarpDeplete:OnObjectiveSyncRequest(prefix, message, dist, sender)
  if message ~= requestMessage or sender == GetUnitName("player", false) then return end

  local completionTimes = {}
  local hasAny = false
  for i, obj in ipairs(self.objectivesState) do
    hasAny = obj.time ~= nil or hasAny
    completionTimes[i] = ("%d"):format(obj.time or -1)
  end

  -- We only send if we have any times saved, since we might also be in
  -- the process of getting times from other users
  if not hasAny then return end

  local text = table.concat(completionTimes, "|")
  self:SendCommMessage(objectiveResponsePrefix, text, "WHISPER", sender, "ALERT")
end

function WarpDeplete:OnObjectiveSyncResponse(prefix, message, dist, sender)
  local parts = {strsplit("|", message)}

  for i, objTimeRaw in ipairs(parts) do
    local objTime = tonumber(objTimeRaw)

    if self.objectivesState[i] and objTime >= 0 then
      self.objectivesState[i].time = objTime
    end
  end

  self:UpdateTimings()
  self:UpdateObjectivesDisplay()
end

function WarpDeplete:BroadcastDeath()
  local time = self.timerState.current
  local playerName = UnitName("player")
  local playerClass = select(2, UnitClass("player"))

  self:AddDeathDetails(time, playerName, playerClass)

  local messageTable = {tostring(time), playerName, playerClass}
  local message = table.concat(messageTable, "|")
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