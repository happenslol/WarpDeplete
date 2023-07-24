local Util = WarpDeplete.Util

function WarpDeplete:UpdateTimings()
  if not self.db.profile.timingsEnabled then
    self:PrintDebug("Skipping timings update: timings are disabled")
    return
  end
  
  -- TODO: Disabled until we find a solution for the following problem:
  -- When updating objective timings while the key is not completed we
  -- would calculate wrong time-diffs on consecutive objective completions
  -- due to the fact, that we already wrote the last/best timing to the
  -- database. This causes the time-diff of previously solved objectives
  -- to become 0.
  local onlyCompleted = self.db.profile.timingsOnlyCompleted or true
  local challengeCompleted = self.challengeState.challengeCompleted

  if onlyCompleted and not challengeCompleted then
    self:PrintDebug("Skipping timings update: challenge not completed")
    return
  end

  self:PrintDebug("Updating timings")
  local objectives = Util.copy(self.objectivesState)
  local timings = self:GetTimingsForCurrentInstance(false)

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

  for i = 1, #objectives do
    local boss = objectives[i]
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
  local timings = self:GetTimingsForCurrentInstance(true)
  if timings == nil then return nil end

  local best = timings.best
  if best == nil then return nil end

  return best[objectiveIndex]
end

function WarpDeplete:GetLastTime(objectiveIndex)
  if self.challengeState.demoModeActive then
    return 520 * objectiveIndex - 23 + 23 * (objectiveIndex  - 1)
  end
  local timings = self:GetTimingsForCurrentInstance(true)
  if timings == nil then return nil end

  local last = timings.last
  if last == nil then return nil end

  return last[objectiveIndex]
end

function WarpDeplete:GetTimingsForCurrentInstance(returnNextLower)
  local level = self.keyDetailsState.level
  local mapId = select(8, GetInstanceInfo())
  local firstAffix = self.keyDetailsState.affixIds[1]
  if mapId == nil or level == nil or firstAffix == nil then
    return nil
  end

  return self:GetTimings(mapId, level, firstAffix, returnNextLower)
end

--
-- @param returnNextLower whether to return the timings of the next lower key if no 
--                        timings for current keystoneLevel are available.
function WarpDeplete:GetTimings(mapId, keystoneLevel, firstAffixId, returnNextLower)
  if returnNextLower == nil then
    returnNextLower = false
  end

  local mapTimings = self.db.char.timings[mapId]
  if mapTimings == nil then
    mapTimings = {}
    self.db.char.timings[mapId] = mapTimings
  end

  local keystoneTimings = mapTimings[keystoneLevel]
  if keystoneTimings == nil then
    keystoneTimings = {}
    mapTimings[keystoneLevel] = keystoneTimings
  end

  local affixTimings = keystoneTimings[firstAffixId]
  if affixTimings == nil then
    affixTimings = {}
    keystoneTimings[firstAffixId] = affixTimings
  end

  if returnNextLower and affixTimings.best == nil or affixTimings.last == nil then
    local lowerLevel = keystoneLevel - 1
    while lowerLevel > 2 do
      local lowerKeystoneTimings = mapTimings[lowerLevel]
      if lowerKeystoneTimings ~= nil then 
        local lowerAffixTimings =  lowerKeystoneTimings[firstAffixId]
        if lowerAffixTimings ~= nil and lowerAffixTimings.best ~= nil and lowerAffixTimings.last ~= nil then
          return lowerAffixTimings
        end
      end
      lowerLevel = lowerLevel - 1
    end
  end

  return affixTimings
end
