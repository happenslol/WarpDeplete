local Util = WarpDeplete.Util

function WarpDeplete:UpdateTimings()
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
  local timings = self:GetTimingsForCurrentInstance()

  if timings == nil then
    self:PrintDebug("Could not determine timings for current instance")
    return
  end

  local best = timings.best
  if best == nil then
    best = {}
    timings.best = best
  end

  local last = timings.last
  if last == nil then
    last = {}
    timings.last = last
  end

  for i = 1, #self.objectivesState do
    local boss = self.objectivesState[i]
    if boss.time ~= nil then
      self:PrintDebug("Setting last time for " .. boss.name .. " (" .. i .. ")")
      last[i] = boss.time

      if best[i] == nil or boss.time < best[i] then
        self:PrintDebug("Setting best time for " .. boss.name .. " (" .. i .. ")")
        best[i] = boss.time
      end
    end
  end

  self:PrintDebug("Best times updated")
end

function WarpDeplete:GetBestTime(objectiveIndex)
  if self.challengeState.demoModeActive then
    return 520 * objectiveIndex - 65 + 65 * (objectiveIndex  - 1)
  end
  local timings = self:GetTimingsForCurrentInstance(false)
  if timings == nil then return nil end

  local best = timings.best
  if best == nil then return nil end

  return best[objectiveIndex]
end

function WarpDeplete:GetLastTime(objectiveIndex)
  if self.challengeState.demoModeActive then
    return 520 * objectiveIndex - 23 + 23 * (objectiveIndex  - 1)
  end
  local timings = self:GetTimingsForCurrentInstance(false)
  if timings == nil then return nil end

  local last = timings.last
  if last == nil then return nil end

  return last[objectiveIndex]
end

function WarpDeplete:GetTimingsForCurrentInstance(strict)
  local level = self.keyDetailsState.level
  local mapId = self.keyDetailsState.mapId
  local affixes = self.keyDetailsState.affixes or {}
  local firstAffixId = affixes.id

  if mapId == nil or level == nil or firstAffixId == nil then
    return nil
  end

  return self:GetTimings(mapId, level, firstAffixId, strict)
end

function WarpDeplete:GetTimings(mapId, keystoneLevel, firstAffixId, strict)
  if strict == nil then strict = true end

  local mapTimings = self.db.char.timings[mapId]
  if mapTimings == nil then
    mapTimings = {}
    self.db.char.timings[mapId] = mapTimings
  end

  local keystoneTimings = mapTimings[keystoneLevel]
  if keystoneTimings == nil then
    keystoneTimings = {}
    mapTimings[keystoneLevel] = keystoneTimings

    if not strict then
      local lowerLevel = keystoneLevel - 1
      local lowerTimings = mapTimings[keystoneLevel]
      while lowerTimings == nil and lowerLevel > 2 do
        lowerLevel = lowerLevel - 1
        lowerTimings = mapTimings[keystoneLevel]
      end
    end
  end

  local affixTimings = keystoneTimings[firstAffixId]
  if affixTimings == nil then
    affixTimings = {}
    keystoneTimings[firstAffixId] = affixTimings
  end

  return affixTimings
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
  if self.db.char.timings[mapId] == nil
    self.db.char.timings[mapId] = {}
  end

  if self.db.char.timings[mapId][keystoneLevel] == nil
    self.db.char.timings[mapId][keystoneLevel] = {}
  end

  if self.db.char.timings[mapId][keystoneLevel] == nil
    self.db.char.timings[mapId][keystoneLevel] = {}
  end

  if self.db.char.timings[mapId][keystoneLevel][firstAffixId] == nil
    self.db.char.timings[mapId][keystoneLevel][firstAffixId] = {}
  end

  if self.db.char.timings[mapId][keystoneLevel][firstAffixId][objectiveIndex] == nil
    self.db.char.timings[mapId][keystoneLevel][firstAffixId][objectiveIndex] = {}
  end

  local prevTiming = Util.copy(
    self.db.char.timings[mapId][keystoneLevel][firstAffixId][objectiveIndex]
  )

  local newTiming = {
    last = newtime,
    best = prevTiming.best,
  }

  if newTiming.best == nil or newTiming.best > newTime then
    self:PrintDebug(
      "Setting new best time for objective " .. objectiveIndex ..
      ": " .. newtime
    )

    newTiming.best = newTiming.last
  end

  self.db.char.timings[mapId][keystoneLevel][firstAffixId][objectiveIndex] = newTiming

  -- Now, calculate the current run differences
  if self.db.char.currentTimingDiffs.mapId ~= mapId then
    self.db.char.currentTimingDiffs = {
      mapId = mapId,
      objectives = {},
    }
  end
end
