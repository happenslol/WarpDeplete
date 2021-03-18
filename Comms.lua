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

local requestMessage = "pls"

function WarpDeplete:RegisterComms()
  self:RegisterComm(timerRequestPrefix, "OnTimerSyncRequest")
  self:RegisterComm(timerResponsePrefix, "OnTimerSyncResponse")
  self:RegisterComm(objectiveRequestPrefix, "OnObjectiveSyncRequest")
  self:RegisterComm(objectiveResponsePrefix, "OnObjectiveSyncResponse")
end

function WarpDeplete:RequestTimerSync()
  self:SendCommMessage(timerRequestPrefix, requestMessage, "PARTY")
end

function WarpDeplete:RequestObjectiveSync()
  self:SendCommMessage(objectiveRequestPrefix, requestMessage, "PARTY")
end

function WarpDeplete:OnTimerSyncRequest(prefix, message, dist, sender)
  if message ~= requestMessage then return end

  local text = ("%d"):format(self.timerState.current)
  if self.timerState.current.isBlizzardTimer then
    text = text .. "|blizz"
  else
    text = text .. "|gettime"
  end

  self:SendCommMessage(timerResponsePrefix, text, "WHISPER", sender)
end

function WarpDeplete:OnTimerSyncResponse(prefix, message, dist, sender)
  local currentRaw, typeRaw = strsplit(message, "|")
  local isBlizzard = typeRaw == "blizz"
  local current = tonumber(currentRaw)

  --TODO(happens): Set start time, current and remaining, possibly using an offset?
  -- This should always prefer a gettime timer, if we get any. So check for our
  -- own isBlizzard (which will be set if we log back in after being offline during
  -- a key) and set our own either if the received time is higher than our own
  -- or if the timer is gettime and ours isn't.
end

function WarpDeplete:OnObjectiveSyncRequest(prefix, message, dist, sender)
  if message ~= requestMessage then return end

  local completionTimes = {}
  local hasAny = false
  for i, obj in ipairs(self.objectivesState) do
    hasAny = obj.time ~= nil or hasAny
    completionTimes = completionTimes .. ("%d"):format(obj.time or -1)
  end

  -- We only send if we have any times saved, since we might also be in
  -- the process of getting times from other users
  if not hasAny then return end

  local text = Util.joinStrings(completionTimes, "|")
  self:SendCommMessage(objectiveResponsePrefix, text, "WHISPER", sender)
end

function WarpDeplete:OnObjectiveSyncResponse(prefix, message, dist, sender)
  local parts = strsplit(message, "|")

  for i, objTimeRaw in ipairs(parts) do
    local objTime = tonumber(objTimeRaw)

    if self.objectivesState[i] and objTime >= 0 then
      self.objectivesState[i].time = objTime
    end
  end

  self:UpdateObjectivesDisplay()
end