local Util = WarpDeplete.Util

function WarpDeplete:UpdateTimings()
  self:PrintDebug("Updating splits")
  local objectives = Util.copy(self.objectivesState)
  local timings = self:GetTimingsForCurrentInstance()

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
      self:PrintDebug("Setting current time for " .. boss.name .. " (" .. i .. ")")
      current[i] = boss.time

      if best[i] ~= nil then
        currentDiff[i] = best[i] - boss.time
        self:PrintDebug("Setting diff for " .. boss.name .. " to " .. tostring(currentDiff[i]))
      else
        self:PrintDebug("No best time found, not setting diff")
      end
    end
  end

  if self.forcesState.completed and not current["forces"] then
    self:PrintDebug("Setting current time for forces")
    current["forces"] = self.forcesState.completedTime

    if best["forces"] ~= nil then
      currentDiff["forces"] = best["forces"] - self.forcesState.completedTime
      self:PrintDebug("Setting diff for forces to " .. tostring(currentDiff[i]))
    end
  end

  if self.challengeCompleted and not current["challenge"] then
    self:PrintDebug("Setting current time for challenge")
    local blizzardCompletionTime = select(3, C_ChallengeMode.GetCompletionInfo())
    current["challenge"] = blizzardCompletionTime

    if best["challenge"] ~= nil then
      currentDiff["challenge"] = best["challenge"] - blizzardCompletionTime
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

  local timings = self:GetTimingsForCurrentInstance()
  if timings == nil then return nil end

  local currentDiff = timings.currentDiff
  if currentDiff == nil then return nil end

  return currentDiff[objectiveIndex]
end

function WarpDeplete:GetTimingsForCurrentInstance()
  local level = self.keyDetailsState.level
  local mapId = C_ChallengeMode.GetActiveChallengeMapID()
  if mapId == nil or level == nil then return nil end

  return self:GetTimings(mapId, level)
end

function WarpDeplete:GetTimings(mapId, keystoneLevel)
  local mapTimings = self.db.global.timings[mapId]
  if mapTimings == nil then
    mapTimings = {}
    self.db.global.timings[mapId] = mapTimings
  end

  local keystoneTimings = mapTimings[keystoneLevel]
  if keystoneTimings == nil then
    keystoneTimings = {}
    mapTimings[keystoneLevel] = keystoneTimings
  end

  return keystoneTimings
end

function WarpDeplete:ResetTimingsCurrent()
  local timings = self:GetTimingsForCurrentInstance()
  if timings == nil then return end

  timings.current = {}
  timings.currentDiff = {}
end

function WarpDeplete:UpdateBestTimings()
  local timings = self:GetTimingsForCurrentInstance()
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
