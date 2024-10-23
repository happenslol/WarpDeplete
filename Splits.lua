local Util = WarpDeplete.Util

function WarpDeplete:UpdateSplits()
  self:PrintDebug("Updating splits")
  local objectives = Util.copy(self.state.objectives)
  local timings = self:GetSplitsForCurrentInstance()

  if timings == nil then
    self:PrintDebug("Could not get timings for current instance")
    return
  end

  local best = timings.best
  if best == nil then
    best = {}
    timings.best = best
  end

  local current = timings.current
  if current == nil then
    current = {}
    timings.current = current
  end

  local currentDiff = timings.currentDiff
  if currentDiff == nil then
    currentDiff = {}
    timings.currentDiff = currentDiff
  end

  for i = 1, #objectives do
    local boss = objectives[i]
    if boss.time ~= nil and not current[i] then
      self:PrintDebug("Setting current time for " .. tostring(i) .. ": " .. tostring(boss.time))
      current[i] = boss.time

      if best[i] ~= nil then
        currentDiff[i] = boss.time - best[i]
        self:PrintDebug("Setting diff for " .. tostring(i) .. " to " .. tostring(currentDiff[i]))
      else
        self:PrintDebug("No best time found, not setting diff")
      end
    end
  end

  if self.forcesState.completed and not current["forces"] then
    self:PrintDebug("Setting current time for forces")
    current["forces"] = self.forcesState.completedTime

    if best["forces"] ~= nil then
      currentDiff["forces"] = self.forcesState.completedTime - best["forces"]
      self:PrintDebug("Setting diff for forces to " .. tostring(currentDiff[i]))
    end
  end

  if self.challengeCompleted and not current["challenge"] then
    self:PrintDebug("Setting current time for challenge")
    local blizzardCompletionTime = select(3, C_ChallengeMode.GetCompletionInfo())
    current["challenge"] = blizzardCompletionTime

    if best["challenge"] ~= nil then
      currentDiff["challenge"] = blizzardCompletionTime - best["challenge"]
      self:PrintDebug("Setting diff for challenge to " .. tostring(currentDiff[i]))
    end
  end

  self:PrintDebug("Splits updated")
end

function WarpDeplete:GetCurrentDiff(objectiveIndex)
  if self.challengeState.demoModeActive then
    if type(objectiveIndex) == "number" then
      return -60 + (objectiveIndex * 30)
    end

    if objectiveIndex == "forces" then
      return -40
    end

    if objectiveIndex == "challenge" then
      return 100
    end

    return 0
  end

  local timings = self:GetSplitsForCurrentInstance()
  if timings == nil then return nil end

  local currentDiff = timings.currentDiff
  if currentDiff == nil then return nil end

  return currentDiff[objectiveIndex]
end

function WarpDeplete:GetSplitsForCurrentInstance()
  local level = self.keyDetailsState.level
  local mapId = self.keyDetailsState.mapId
  if mapId == nil or level == nil then return nil end

  return self:GetSplits(mapId, level)
end

function WarpDeplete:GetSplits(mapId, keystoneLevel)
  local mapSplits = self.db.global.timings[mapId]
  if mapSplits == nil then
    mapSplits = {}
    self.db.global.timings[mapId] = mapSplits
  end

  local keystoneSplits = mapSplits[keystoneLevel]
  if keystoneSplits == nil then
    keystoneSplits = {}
    mapSplits[keystoneLevel] = keystoneSplits
  end

  return keystoneSplits
end

function WarpDeplete:ResetSplitsCurrent()
  local timings = self:GetSplitsForCurrentInstance()
  if timings == nil then return end

  timings.current = {}
  timings.currentDiff = {}
end

function WarpDeplete:UpdateBestSplits()
  local timings = self:GetSplitsForCurrentInstance()
  if timings == nil or timings.current == nil then return end

  if timings.best == nil then
    timings.best = {}
  end

  for k, v in pairs(timings.current) do
    self:PrintDebug("Updating best timings for objective " .. tostring(k))
    if not timings.best[k] then
      self:PrintDebug("No best time found, setting " .. tostring(v))
      timings.best[k] = v
    elseif timings.best[k] > v then
      self:PrintDebug("Better time found, setting " .. tostring(v))
      timings.best[k] = v
    end
  end
end
