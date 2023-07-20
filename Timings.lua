local Util = WarpDeplete.Util

function WarpDeplete:GetCurrentRunTimings(objectiveIndex)
  local level = self.keyDetailsState.level
  local mapId = self.keyDetailsState.mapId
  local affixes = self.keyDetailsState.affixes or {}
  local firstAffixId = affixes.id

  if mapId == nil or level == nil or firstAffixId == nil then
    self:PrintDebug("Failed to get current run timings due to missing keyDetailsState fields")
    return nil
  end

  local currentTimings = self.db.char.currentRunTimings
  if currentTimings.mapId == nil or currentTimings.mapId ~= mapId then
    self:PrintDebug("No current run timings found due to mapId mismatch")
    return nil
  end

  if currentTimings.objectives == nil or currentTimings.objectives[objectiveIndex] == nil then
    self:PrintDebug("No current run timings found due to missing objectiveIndex")
    return nil
  end

  return currentTimings.objectives[objectiveIndex]
end

function WarpDeplete:GetBestTimeDifference(objectiveIndex)
  local objectiveTimings = self:GetObjectiveTimings(objectiveIndex)
  if objectiveTimings == nil or objectiveTimings.bestUpdated == false then
    return nil
  end

  -- Make sure we even have a previous best recorded and didn't just
  -- record our first best time.
  if objectiveTimings.lastBest == nil then
    return nil
  end

  return objectiveTimings.newBest - objectiveTimings.lastBest
end

function WarpDeplete:GetLastTimeDifference(objectiveIndex)
  local objectiveTimings = self:GetObjectiveTimings(objectiveIndex)
  if objectiveTimings == nil or objectiveTimings.lastTime == nil then
    return nil
  end

  -- lastTime will only ever be set if newTime is also set.
  return objectiveTimings.newTime - objectiveTimings.lastTime
end

--[[
  This will set a new time for the current keyDetailsState, and update
  the best time in case the given time is better. It also ensures
  the db layout is correct.

  This function will be a no-op if any of the keyDetailsState fields
  are missing.

  NOTE(happens): I've thought about just generating a simple key
  for each timing (e.g. "<mapId>.<level>.<affixId>.<objectiveIndex>"),
  which would save us all this trouble.
  However, that would make it harder in the future to iterate over
  timings for all the dungeons, so I'm leaving this here for now.
--]]
function WarpDeplete:SetTiming(objectiveIndex, newTime)
  if not self.db.profile.timingsEnabled then
    self:PrintDebug("Skipping timings update: timings are disabled")
    return
  end

  if not self.challengeState.challengeCompleted and
    not self.db.profile.timingsOnlyCompleted then
    self:PrintDebug("Skipping timings update: challenge not completed")
    return
  end

  self:PrintDebug("Updating timings")

  local level = self.keyDetailsState.level
  local mapId = self.keyDetailsState.mapId
  local affixes = self.keyDetailsState.affixes or {}
  local firstAffixId = affixes.id

  if mapId == nil or level == nil or firstAffixId == nil then
    self:PrintDebug("Failed to set new timing due to missing keyDetailsState fields")
    return
  end

  self:PrintDebug(
    "Setting new timing: " ..
    "mapId(" .. mapId .. ") " ..
    "level(" .. level .. ") " ..
    "firstAffixId(" .. firstAffixId .. ") " ..
    "objectiveIndex(" .. objectiveIndex .. ") " ..
    "newTime(" .. newTime .. ")"
  )

  -- TODO(happens): Make a helper function that ensures a deep
  -- field in a nested table exists
  if self.db.char.timings[mapId] == nil then
    self.db.char.timings[mapId] = {}
  end

  if self.db.char.timings[mapId][level] == nil then
    self.db.char.timings[mapId][level] = {}
  end

  if self.db.char.timings[mapId][level] == nil then
    self.db.char.timings[mapId][level] = {}
  end

  if self.db.char.timings[mapId][level][firstAffixId] == nil then
    self.db.char.timings[mapId][level][firstAffixId] = {}
  end

  if self.db.char.timings[mapId][level][firstAffixId][objectiveIndex] == nil then
    self.db.char.timings[mapId][level][firstAffixId][objectiveIndex] = {}
  end

  local prevTiming = Util.copy(
    self.db.char.timings[mapId][level][firstAffixId][objectiveIndex]
  )

  local newTiming = {
    last = newTime,
    best = prevTiming.best,
  }

  local currentTimings = {
    lastTime = prevTiming.last,
    newTime = newTime,
    bestUpdated = false,
    prevBest = prevTiming.best,
  }

  if prevTiming.best == nil or newTime < prevTiming.best then
    self:PrintDebug(
      "Setting new best time for objective " .. objectiveIndex ..
      ": " .. newTime
    )

    -- We want to record whether or not we changed this value,
    -- since it's possible that we get the exact same time twice.
    -- In that case, we don't want to show something incorrect
    -- to the user.
    currentTimings.bestUpdated = true
    currentTimings.newBest = newTime
    newTiming.best = newTiming.last
  end

  self.db.char.timings[mapId][level][firstAffixId][objectiveIndex] = newTiming

  -- Persist the changes we just saved for the current map id.
  if self.db.char.currentRunTimings.mapId == nil or
    self.db.char.currentRunTimings.mapId ~= mapId then
    self.db.char.currentRunTimings = {
      mapId = mapId,
      objectives = {},
    }
  end

  self.db.char.currentRunTimings.objectives[objectiveIndex] = currentTimings
end
