local Util = WarpDeplete.Util

--TODO(happens): For some reason the timer is off by 10 seconds after the first death.
-- The blizzard timer seems to jump up by 5 seconds while ours goes down 5 seconds,
-- but the end of the timer seems to be correct for the blizzard timer. If we reload the
-- and retrieve the elapsed value from the blizzard timer, we end up with the correct timer
-- again, until we die for the first time after reloading.

function WarpDeplete:CheckForChallengeMode()
  local _, _, difficulty, _, _, _, _, currentZoneID = GetInstanceInfo()

  self:PrintDebug("Checking for challenge mode, difficulty: "
    .. difficulty .. ", Zone ID: " .. currentZoneID)

  local inChallenge = difficulty == 8 and C_ChallengeMode.GetActiveChallengeMapID() ~= nil

  self:PrintDebug("Challenge state: inChallenge:"
    .. tostring(self.challengeState.inChallenge)
    .. ", new value:" .. tostring(inChallenge))

  if self.challengeState.inChallenge == inChallenge then return end

  if inChallenge then self:StartChallengeMode()
  else self:StopChallengeMode() end
end

function WarpDeplete:StartChallengeMode()
  if self.challengeState.demoModeActive then
    self:Print("Disabling demo mode because a challenge has started.")
    self:DisableDemoMode()
  end

  self:PrintDebug("Starting challenge mode")
  self:ResetState()
  self:RegisterChallengeEvents()

  local gotTimerInfo = self:GetTimerInfo()
  local gotKeyInfo = self:GetKeyInfo()
  local gotObjectivesInfo = self:GetObjectivesInfo()
  self:SetDeaths(C_ChallengeMode.GetDeathCount() or 0)

  if not gotKeyInfo or not gotObjectivesInfo or not gotTimerInfo then return end

  self.challengeState.inChallenge = true
  self:Show()

  if not self.timerState.running then
    self:StartChallengeTimer()
  end
end

function WarpDeplete:StartChallengeTimer()
  self:PrintDebug("Challenge timer started")

  self.timerState.startTime = GetTime()
  self.timerState.running = true

  self:OnTimerTick()
end

function WarpDeplete:StopChallengeMode()
  self:Hide()

  self:ResetState()
  self:UnregisterChallengeEvents()
end

function WarpDeplete:CompleteChallengeMode()
  --TODO(happens): Refresh information from blizzard timer so we have
  -- an accurate finish time. If we load in afterwards this is done automatically,
  -- but if we used our own timer we should redo it.
  self.challengeState.challengeCompleted = true

  self:UpdateTimerDisplay()
  self:UpdateObjectivesDisplay()
  self:UpdateForcesDisplay()
end

function WarpDeplete:GetTimerInfo()
  local mapID = C_ChallengeMode.GetActiveChallengeMapID()
  if not mapID then
    self:PrintDebug("No map id for timer received")
    return false
  end

  local limit = select(3, C_ChallengeMode.GetMapUIInfo(mapID))
  if not limit then
    self:PrintDebug("No time limit received")
    return false
  end

  self:SetTimerLimit(limit)

  local current = select(2, GetWorldElapsedTime(1))

  -- If there already is time elapsed, we're loading into
  -- a running key. This means that we're now running on the
  -- blizzard timer and should request the current time from
  -- someone else.
  if current > 2 then --TODO(happens): The WA is using 2 here, is that fine?
    self.timerState.isBlizzardTimer = true
    C_Timer.After(0.5, function() 
      local current = select(2, GetWorldElapsedTime(1))
      local deaths = C_ChallengeMode.GetDeathCount()
      local trueTime = current - deaths * 5
      self.timerState.startOffset = trueTime
      self.timerState.startTime = GetTime()
      self.timerState.isBlizzardTimer = true

      self:RequestTimerSync()
      self:RequestObjectiveSync()
    end)
  end

  self:SetTimerCurrent(current)
  return true
end

function WarpDeplete:GetKeyInfo()
  self:PrintDebug("Getting key info")

  local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()

  local affixNames = {}
  for i, affixID in ipairs(affixes) do
    local name = C_ChallengeMode.GetAffixInfo(affixID)
    affixNames[i] = name
  end

  if level <= 0 or #affixNames <= 0 then
    self:PrintDebug("No affixes or key level received")
    return false
  end

  self:SetKeyDetails(level or 0, affixNames)
  return true
end

function WarpDeplete:GetObjectivesInfo()
  self:PrintDebug("Getting objectives info")

  local stepCount = select(3, C_Scenario.GetStepInfo())
  if stepCount <= 0 then
    self:PrintDebug("No steps received, can't update objective info")
    return false
  end

  local currentCount, totalCount = self:GetEnemyForcesCount()
  -- The last step will forces, all previous steps are bosses
  self:PrintDebug("Got forces info: " .. currentCount .. "/" .. totalCount)

  if totalCount <= 0 then
    self:PrintDebug("No mob count received")
    return false
  end

  self:SetForcesTotal(totalCount)
  self:SetForcesCurrent(currentCount)

  local objectives = {}
  for i = 1, stepCount - 1 do
    local name, _, completed = C_Scenario.GetCriteriaInfo(i)
    if not name then break end

    name = gsub(name, " defeated", "")
    self:PrintDebug("Got boss name for index " .. i .. ": " .. tostring(name))
    objectives[i] = { name = name, time = completed and 0 or nil }
  end

  if #objectives <= 0 then
    self:PrintDebug("No objectives received")
    return false
  end

  self:SetObjectives(objectives)
  return true
end

function WarpDeplete:GetEnemyForcesCount()
  local stepCount = select(3, C_Scenario.GetStepInfo())
  local _, _, _, _, totalCount, _, _, mobPointsStr = C_Scenario.GetCriteriaInfo(stepCount)
  local currentCountStr = gsub(mobPointsStr, "%%", "")
  local currentCount = tonumber(currentCountStr)
  return currentCount, totalCount
end

function WarpDeplete:UpdateForces()
  if not self.challengeState.inChallenge then return end

  local stepCount = select(3, C_Scenario.GetStepInfo())
  local currentCount = self:GetEnemyForcesCount()

  if currentCount >= self.forcesState.totalCount and not self.forcesState.completed then
    -- If we just went above the total count (or matched it), we completed it just now
    self.forcesState.completed = true
    self.forcesState.completedTime = self.timerState.current
  end

  self:SetForcesCurrent(currentCount)
end

function WarpDeplete:UpdateObjectives()
  if not self.challengeState.inChallenge then return end

  local objectives = Util.copy(self.objectivesState)
  local changed = false

  local stepCount = select(3, C_Scenario.GetStepInfo())
  for i = 1, stepCount - 1 do
    if not objectives[i] or not objectives[i].time then
      -- If it wasn't completed before and it is now, we've just completed
      -- it and can set the completion time
      local completed = select(3, C_Scenario.GetCriteriaInfo(i))
      if completed then
        objectives[i].time = self.timerState.current
        changed = true
      end
    end
  end

  if changed then self:SetObjectives(objectives) end
end

function WarpDeplete:ResetCurrentPull()
  for k, _ in pairs(self.forcesState.currentPull) do
    self.forcesState.currentPull[k] = nil
  end

  self:SetForcesPull(0)
end

-- These events are used to detect whether we are in challenge mode
-- or whether we should put a key in the socket, and will always stay registered.
function WarpDeplete:RegisterGlobalEvents()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnCheckChallengeMode")
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnCheckChallengeMode")

  -- Fired when the countdown hits 0 (and for some reason when we die?)
  self:RegisterEvent("WORLD_STATE_TIMER_START", "OnChallengeModeStart")

  self:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", "OnKeystoneOpen")
end

function WarpDeplete:RegisterChallengeEvents()
  -- Challenge mode triggers
  self:RegisterEvent("CHALLENGE_MODE_START", "OnChallengeModeStart")
  self:RegisterEvent("CHALLENGE_MODE_RESET", "OnChallengeModeReset")
  self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnChallengeModeCompleted")

  -- Scenario Triggers
  self:RegisterEvent("SCENARIO_POI_UPDATE", "OnScenarioPOIUpdate")
  self:RegisterEvent("SCENARIO_CRITERIA_UPDATE", "OnScenarioCriteriaUpdate")

  -- Combat triggers
  self:RegisterEvent("PLAYER_DEAD", "OnPlayerDead")
  self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
  self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", "OnThreatListUpdate")
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent")
end

function WarpDeplete:UnregisterChallengeEvents()
  self:UnregisterEvent("CHALLENGE_MODE_START")
  self:UnregisterEvent("CHALLENGE_MODE_RESET")
  self:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
  self:UnregisterEvent("SCENARIO_POI_UPDATE")
  self:UnregisterEvent("SCENARIO_CRITERIA_UPDATE")
  self:UnregisterEvent("PLAYER_DEAD")
  self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function WarpDeplete:OnTimerTick() 
  if not self.challengeState.inChallenge or self.challengeState.challengeCompleted then return end

  --TODO(happens): We update this a lot, can we do this
  -- in a better way so it's not called 10 times a second?
  local newDeaths = C_ChallengeMode.GetDeathCount()
  if newDeaths ~= self.timerState.deaths then
    self:SetDeaths(newDeaths)
  end

  local deathPenalty = self.timerState.deaths * 5
  local current = GetTime() + self.timerState.startOffset - self.timerState.startTime + deathPenalty
  

  if current < 0 then return end

  self:SetTimerCurrent(current)
end

function WarpDeplete:OnCheckChallengeMode(ev)
  self:PrintDebug("|cFF09ED3AG_EVENT|r " .. ev)
  self:CheckForChallengeMode()
end

function WarpDeplete:OnChallengeModeStart(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  if self.timerState.running then
    self:PrintDebug("Start event received while timer was already running")
    return
  end

  self:StartChallengeTimer()

  if not self.challengeState.inChallenge then
    self:StartChallengeMode()
  end
end

function WarpDeplete:OnChallengeModeReset(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  self:ResetState()
end

function WarpDeplete:OnChallengeModeCompleted(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  self:CompleteChallengeMode()
end

function WarpDeplete:OnKeystoneOpen(ev)
  self:PrintDebug("|cFF09ED3AG_EVENT|r " .. ev)

  if not self.db.profile.insertKeystoneAutomatically then
    return
  end

  local difficulty = select(3, GetInstanceInfo())
  if difficulty ~= 8 and difficulty ~= 23 then
    return
  end

  local found = nil
  for bagIndex = 0, NUM_BAG_SLOTS do
    for invIndex = 1, GetContainerNumSlots(bagIndex) do
      local itemID = GetContainerItemID(bagIndex, invIndex)

      if itemID and (itemID == 180653) then
        self:PrintDebug("Key found at ("
          .. bagIndex .. "," .. invIndex .. ")")

        found = {
          bagIndex = bagIndex,
          invIndex = invIndex
        }

        break
      end
    end

    if found ~= nil then break end
  end

  if found ~= nil then
    self:PrintDebug("Slotting keystone from ("
      .. found.bagIndex .. "," .. found.invIndex .. ")")

    PickupContainerItem(found.bagIndex, found.invIndex)
    C_Timer.After(0.1, function()
      if CursorHasItem() then
        C_ChallengeMode.SlotKeystone()
      end
    end)
  end
end

function WarpDeplete:OnScenarioPOIUpdate(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  self:UpdateForces()
  self:UpdateObjectives()
end

function WarpDeplete:OnScenarioCriteriaUpdate(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  self:UpdateForces()
  self:UpdateObjectives()
end

function WarpDeplete:OnPlayerDead(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  self:ResetCurrentPull()
end

function WarpDeplete:OnPlayerRegenEnabled(ev)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  self:ResetCurrentPull()
end

function WarpDeplete:OnThreatListUpdate(ev, unit)
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)
  if not InCombatLockdown() then return end
  if not unit or not UnitExists(unit) then return end

  self:PrintDebug("Getting unit guid for unit " .. tostring(unit))
  local guid = UnitGUID(unit)
  if not guid or self.forcesState.currentPull[guid] then return end

  self:PrintDebug("Getting npc id for unit " .. tostring(unit))
  local npcID = select(6, strsplit("-", guid))
  local count = MDT:GetEnemyForces(tonumber(npcID))
  self:PrintDebug("Got forces for unit: " .. tonumber(count))

  if not count or count <= 0 then return end

  self.forcesState.currentPull[guid] = count

  local pullCount = Util.calcPullCount(self.forcesState.currentPull, self.forcesState.totalCount)
  self:SetForcesPull(pullCount)
end

function WarpDeplete:OnCombatLogEvent(ev)
  local _, subEv, _, _, _, _, _, guid = CombatLogGetCurrentEventInfo()
  if subEv ~= "UNIT_DIED" then return end
  self:PrintDebug("|cFFA134EBEVENT|r " .. ev)

  self.forcesState.currentPull[guid] = nil
  local pullCount = Util.calcPullCount(self.forcesState.currentPull, self.forcesState.totalCount)
  self:SetForcesPull(pullCount)
end
