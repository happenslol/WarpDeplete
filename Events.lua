local Util = WarpDeplete.Util
local L = WarpDeplete.L

local UPDATE_INTERVAL = 0.1
local sinceLastUpdate = 0

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
    self:Print(L["Disabling demo mode because a challenge has started."])
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

  sinceLastUpdate = 0
  self.frames.root:SetScript("OnUpdate", function(self, elapsed)
    WarpDeplete:OnTimerTick(elapsed)
  end)
end

function WarpDeplete:StopChallengeTimer()
  sinceLastUpdate = 0
  self.frames.root:SetScript("OnUpdate", nil)
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

  self:UpdateTimings()
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

    -- If we call this without any delay, the timer will be off by 10
    -- seconds. The blizzard timer also has this bug and corrects it
    -- after the first death. Lmao
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

  local mapId = C_ChallengeMode.GetActiveChallengeMapID()
  local level, affixIds = C_ChallengeMode.GetActiveKeystoneInfo()

  local affixes = {}
  for i, id in ipairs(affixIds) do
    local name = C_ChallengeMode.GetAffixInfo(id)
    affixes[i] = { name = name, id = id }
  end

  if level <= 0 or #affixes <= 0 then
    self:PrintDebug("No affixes or key level received")
    return false
  end

  self:SetKeyDetails(level or 0, affixes, mapId)
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
  if not totalCount or not mobPointsStr then return nil, nil end

  local currentCountStr = gsub(mobPointsStr, "%%", "")
  local currentCount = tonumber(currentCountStr)
  return currentCount, totalCount
end

function WarpDeplete:UpdateForces()
  if not self.challengeState.inChallenge then return end

  local stepCount = select(3, C_Scenario.GetStepInfo())
  local currentCount = self:GetEnemyForcesCount()
  -- This mostly happens when we have already completed the dungeon
  if not currentCount then return end
  self:PrintDebug("currentCount: " .. currentCount)

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

  if changed then
    self:UpdateTimings()
    self:SetObjectives(objectives)
  end
end

function WarpDeplete:ResetCurrentPull()
  for k, _ in pairs(self.forcesState.currentPull) do
    self.forcesState.currentPull[k] = nil
  end

  self:SetForcesPull(0)
end

function WarpDeplete:AddDeathDetails(time, name, class)
  local len = #self.timerState.deathDetails
  self.timerState.deathDetails[len + 1] = {
    time = time,
    name = name,
    class = class
  }
end

-- These events are used to detect whether we are in challenge mode
-- or whether we should put a key in the socket, and will always stay registered.
function WarpDeplete:RegisterGlobalEvents()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnCheckChallengeMode")
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnCheckChallengeMode")

  -- Fired when the countdown hits 0 (and for some reason when we die?)
  self:RegisterEvent("WORLD_STATE_TIMER_START", "OnChallengeModeStart")

  -- Fired when we open the keystone socket
  self:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", "OnKeystoneOpen")

  -- Register tooltip count display
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, WarpDeplete.DisplayCountInTooltip)

  -- Tooltip events
  self.frames.deathsTooltip:SetScript("OnEnter", WarpDeplete.TooltipOnEnter)
  self.frames.deathsTooltip:SetScript("OnLeave", WarpDeplete.TooltipOnLeave)
end

function WarpDeplete.TooltipOnEnter()
  local self = WarpDeplete
  if not self.db.profile.showDeathsTooltip then return end

  GameTooltip:SetOwner(self.frames.deathsTooltip, "ANCHOR_BOTTOMLEFT",
    self.frames.deathsTooltip.offsetWidth)

  GameTooltip:ClearLines()

  local count = #self.timerState.deathDetails
  if count == 0 then
    GameTooltip:AddLine(L["No Recorded Player Deaths"], 1, 1, 1)
    GameTooltip:Show()
    return
  end

  GameTooltip:AddLine(L["Player Deaths"], 1, 1, 1)
  if self.db.profile.deathLogStyle == "time" then
    local showFrom = 0
    if count > 20 then
      showFrom = count - 20
    end

    for i, d in ipairs(self.timerState.deathDetails) do
      if i >= showFrom then
        local color = select(4, GetClassColor(d.class))
        local time = Util.formatTime(d.time)
        GameTooltip:AddLine(time .. " - |c" .. color .. d.name .. "|r")
      end
    end
  elseif self.db.profile.deathLogStyle == "count" then
    local countTable = {}
    for i, d in ipairs(self.timerState.deathDetails) do
      if not countTable[d.name] then
        countTable[d.name] = {
          color = select(4, GetClassColor(d.class)),
          count = 0
        }
      end

      countTable[d.name].count = countTable[d.name].count + 1
    end

    for name, deaths in pairs(countTable) do
      GameTooltip:AddLine("|c" .. deaths.color .. name .. "|r|cFFFFFFFF: " .. tostring(deaths.count) .. "|r")
    end
  end

  GameTooltip:Show()
end

function WarpDeplete.TooltipOnLeave()
  GameTooltip_Hide()
end

function WarpDeplete.DisplayCountInTooltip(tt, data)
  if not tt or tt ~= GameTooltip or not data or not data.guid then return end
  if not WarpDeplete.timerState.running then return end
  if not MDT or not WarpDeplete.db.profile.showTooltipCount then return end

  local npcID = select(6, strsplit("-", data.guid))
  local count, max = MDT:GetEnemyForces(tonumber(npcID))

  if count and max and count ~= 0 and max ~= 0 then
    local percentText = ("%.2f"):format(count / max * 100)
    local countText = ("%d"):format(count)
    local result = WarpDeplete.db.profile.tooltipCountFormat ~= ":custom:" and
      WarpDeplete.db.profile.tooltipCountFormat or
      WarpDeplete.db.profile.customTooltipCountFormat

    result = gsub(result, ":percent:", percentText .. "%%")
    result = gsub(result, ":count:", countText)
    GameTooltip:AddLine("Count: |cFFFFFFFF" .. result .. "|r")
    GameTooltip:Show()
  end
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
  self:RegisterEvent("ENCOUNTER_END", "OnResetCurrentPull")
  self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnResetCurrentPull")

  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent")
  self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", "OnThreatListUpdate")
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

function WarpDeplete:OnTimerTick(elapsed) 
  if not self.challengeState.inChallenge or
    self.challengeState.challengeCompleted or
    not self.timerState.running then
    self:StopChallengeTimer()
    return
  end

  sinceLastUpdate = sinceLastUpdate + elapsed
  if sinceLastUpdate <= UPDATE_INTERVAL then return end
  sinceLastUpdate = 0

  --TODO(happens): We update this a lot, can we do this
  -- in a better way so it's not called 10 times a second?
  local newDeaths = C_ChallengeMode.GetDeathCount()
  if newDeaths ~= self.timerState.deaths then
    self:SetDeaths(newDeaths)
  end

  local deathPenalty = self.timerState.deaths * 5
  local current = GetTime() + self.timerState.startOffset - self.timerState.startTime + deathPenalty

  -- if current < 0 then return end

  self:SetTimerCurrent(current)
end

function WarpDeplete:OnCheckChallengeMode(ev)
  self:PrintDebugGlobalEvent(ev)
  self:CheckForChallengeMode()
end

function WarpDeplete:OnChallengeModeStart(ev)
  self:PrintDebugGlobalEvent(ev)
  if self.timerState.running then
    self:PrintDebug("Start event received while timer was already running")
    return
  end

  self:StartChallengeTimer()

  if not self.challengeState.inChallenge then
    self:StartChallengeMode()
  end
end

function WarpDeplete:OnPlayerDead(ev)
  self:PrintDebugEvent(ev)
  --TODO(happens): It would be better to also broadcast the death
  -- and then deduplicate deaths, since we can also catch deaths
  -- that weren't logged for us that way. We need to figure out a
  -- good method for deduping though.
  -- self:BroadcastDeath()
  self:ResetCurrentPull()
end

function WarpDeplete:OnChallengeModeReset(ev)
  self:PrintDebugEvent(ev)
  self:ResetState()
end

function WarpDeplete:OnChallengeModeCompleted(ev)
  self:PrintDebugEvent(ev)
  self:CompleteChallengeMode()
end

function WarpDeplete:OnKeystoneOpen(ev)
  self:PrintDebugEvent(ev)

  if not self.db.profile.insertKeystoneAutomatically then
    return
  end

  local difficulty = select(3, GetInstanceInfo())
  if difficulty ~= 8 and difficulty ~= 23 then
    return
  end

  local found = nil
  for bagIndex = 0, NUM_BAG_SLOTS do
    for invIndex = 1, C_Container.GetContainerNumSlots(bagIndex) do
      local itemID = C_Container.GetContainerItemID(bagIndex, invIndex)

      if itemID and C_Item.IsItemKeystoneByID(itemID) then
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

    C_Container.UseContainerItem(found.bagIndex, found.invIndex)
  end
end

function WarpDeplete:OnScenarioPOIUpdate(ev)
  self:PrintDebugEvent(ev)
  self:UpdateForces()
  self:UpdateObjectives()
end

function WarpDeplete:OnScenarioCriteriaUpdate(ev)
  self:PrintDebugEvent(ev)
  self:UpdateForces()
  self:UpdateObjectives()
end

function WarpDeplete:OnResetCurrentPull(ev)
  self:PrintDebugEvent(ev)
  self:ResetCurrentPull()
end

function WarpDeplete:OnThreatListUpdate(ev, unit)
  self:PrintDebugEvent(ev)
  if not MDT then return end
  if not InCombatLockdown() or not unit or not UnitExists(unit) then return end

  --NOTE(happens): There seem to be cases where a Unit will throw a threat list update
  -- after it has died, which falsely re-adds it to the current pull. We set that units'
  -- count value to "DEAD" when it dies, and due to the check if the guid already exists
  -- in the table, it won't be overwritten after the unit has died.
  local guid = UnitGUID(unit)
  if not guid or self.forcesState.currentPull[guid] then return end

  local npcID = select(6, strsplit("-", guid))
  local count = MDT:GetEnemyForces(tonumber(npcID))
  if not count or count <= 0 then return end

  self:PrintDebug("Adding unit " .. guid .. " to current pull: " .. count)
  self.forcesState.currentPull[guid] = count
  local pullCount = Util.calcPullCount(self.forcesState.currentPull, self.forcesState.totalCount)
  self:SetForcesPull(pullCount)
end

function WarpDeplete:OnCombatLogEvent(ev)
  local _, subEv, _, _, _, _, _, guid, name = CombatLogGetCurrentEventInfo()
  if subEv ~= "UNIT_DIED" then return end
  self:PrintDebugEvent(ev)
  if not guid then return end

  --NOTE(happens): We have to check health since we'd count feign death otherwise
  if UnitInParty(name) and UnitHealth(name) <= 1 then
    local name = UnitName(name)
    local class = select(2, UnitClass(name))
    local time = self.timerState.current

    self:PrintDebug("Player died: " .. name .. " class: " .. class .. " time: " .. time)
    self:AddDeathDetails(time, name, class)
    return
  end

  if not self.forcesState.currentPull[guid] then return end
  self:PrintDebug("removing unit " .. guid .. " from current pull")
  -- See comment above (OnThreadListUpdate)
  self.forcesState.currentPull[guid] = "DEAD"
  local pullCount = Util.calcPullCount(self.forcesState.currentPull, self.forcesState.totalCount)
  self:SetForcesPull(pullCount)
end
