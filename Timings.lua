local Util = WarpDeplete.Util

function WarpDeplete:UpdateTimings()
  if not self.db.profile.timingsEnabled then
    self:PrintDebug("Skipping timings update: timings are disabled")
    return
  end

  if not self.challengeState.challengeCompleted and not self.db.profile.timingsOnlyCompleted then
    self:PrintDebug("Skipping timings update: challenge not completed")
    return
  end

  self:PrintDebug("Updating timings")
  local objectives = Util.copy(self.objectivesState)
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
  local mapId = select(8, GetInstanceInfo())
  local firstAffix = self.keyDetailsState.affixIds[1]
  if mapId == nil or level == nil or firstAffix == nil then
    return nil
  end

  return self:GetTimings(mapId, level, firstAffix, strict)
end

function WarpDeplete:GetTimings(mapId, keystoneLevel, firstAffixId, strict)
  strict = strict or true

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
