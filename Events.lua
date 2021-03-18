-- These events are used to detect whether we are in challenge mode
-- and will always stay registered.
function WarpDeplete:RegisterGlobalEvents()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnCheckChallengeMode")
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnCheckChallengeMode")

  self:RegisterEvent("WORLD_STATE_TIMER_START", "OnChallengeModeStart")

  self:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", "OnKeystoneOpen")
end

function WarpDeplete:RegisterChallengeEvents()
  -- TODO: Implement unit_died event from COMBAT_LOG_EVENT_UNFILTERED

  -- Challenge mode triggers
  self:RegisterEvent("CHALLENGE_MODE_START", "OnChallengeModeStart")
  self:RegisterEvent("CHALLENGE_MODE_RESET", "OnChallengeModeReset")
  self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnChallengeModeCompleted")

  -- Scenario Triggers
  self:RegisterEvent("SCENARIO_POI_UPDATE", "OnScenarioPOIUpdate")
  self:RegisterEvent("SCENARIO_CRITERIA_UPDATE", "OnScenarioCriteriaUpdate")

  -- Combat triggers
  self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
  self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")
  self:RegisterEvent("PLAYER_DEAD", "OnPlayerDead")
  self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
  self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", "OnThreatListUpdate")
end

function WarpDeplete:UnregisterChallengeEvents()
  self:UnregisterEvent("CHALLENGE_MODE_START")
  self:UnregisterEvent("CHALLENGE_MODE_RESET")
  self:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
  self:UnregisterEvent("SCENARIO_POI_UPDATE")
  self:UnregisterEvent("SCENARIO_CRITERIA_UPDATE")
  self:UnregisterEvent("ENCOUNTER_START")
  self:UnregisterEvent("ENCOUNTER_END")
  self:UnregisterEvent("PLAYER_DEAD")
  self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
end

function WarpDeplete:OnCheckChallengeMode(ev)
  self:Print("|cFF09ED3AG_EVENT|r: " .. ev)
end

function WarpDeplete:OnChallengeModeStart(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
  self:ResetState()

  self.challengeState.inChallenge = true
  self.timerState.startTime = GetTime()

  self:Show()
  self:OnTimerTick()
end

function WarpDeplete:OnChallengeModeReset(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
  self:ResetState()
end

function WarpDeplete:OnChallengeModeCompleted(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnKeystoneOpen(ev)
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
    PickupContainerItem(found.bagIndex, found.invIndex)
    C_Timer.After(0.1, function()
      if CursorHasItem() then C_ChallengeMode.SlotKeystone() end
    end)
  end
end

function WarpDeplete:OnScenarioPOIUpdate(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnScenarioCriteriaUpdate(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnEncounterStart(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnEncounterEnd(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnPlayerDead(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnPlayerRegenEnabled(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnThreatListUpdate(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end