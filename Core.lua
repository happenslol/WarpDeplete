WarpDeplete = LibStub("AceAddon-3.0"):NewAddon(
  "WarpDeplete",
  "AceConsole-3.0",
  "AceEvent-3.0",
  "AceTimer-3.0"
)

local wdp = WarpDeplete
wdp.LSM = LibStub("LibSharedMedia-3.0")
wdp.Glow = LibStub("LibCustomGlow-1.0")

wdp.challengeState = {
  demoModeActive = false,
  inChallenge = false,
  challengeCompleted = false,
}

function WarpDeplete:OnInitialize()
  local frames = {}

  frames.root = CreateFrame("Frame", "WarpDepleteFrame", UIParent)
  frames.bars = CreateFrame("Frame", "WarpDepleteBars", frames.root)

  self.frames = frames
end

function WarpDeplete:OnEnable()
  wdp:InitOptions()
  wdp:InitChatCommands()
  wdp:InitDisplay()

  C_ChatInfo.RegisterAddonMessagePrefix("WarpDeplete")
  wdp:RegisterGlobalEvents()

  wdp:Hide()
end

function WarpDeplete:OnDisable()
end

-- These events are used to detect whether we are in challenge mode
-- and will always stay registered.
function WarpDeplete:RegisterGlobalEvents()
  self:RegisterEvent("PLAYER_ENTERING_WORLD", WarpDeplete.OnCheckChallengeMode, self)
  self:RegisterEvent("WORLD_STATE_TIMER_START", WarpDeplete.OnCheckChallengeMode, self)
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA", WarpDeplete.OnCheckChallengeMode, self)

  self:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", WarpDeplete.OnKeystoneOpen, self)
end

function WarpDeplete:RegisterChallengeEvents()
  -- TODO: Implement unit_died event from COMBAT_LOG_EVENT_UNFILTERED

  -- Challenge mode triggers
  self:RegisterEvent("CHALLENGE_MODE_START", WarpDeplete.OnChallengeModeStart, self)
  self:RegisterEvent("CHALLENGE_MODE_RESET", WarpDeplete.OnChallengeModeReset, self)
  self:RegisterEvent("CHALLENGE_MODE_COMPLETED", WarpDeplete.OnChallengeModeCompleted, self)

  -- Scenario Triggers
  self:RegisterEvent("SCENARIO_POI_UPDATE", WarpDeplete.OnScenarioPOIUpdate, self)
  self:RegisterEvent("SCENARIO_CRITERIA_UPDATE", WarpDeplete.OnScenarioCriteriaUpdate, self)

  -- Combat triggers
  self:RegisterEvent("ENCOUNTER_START", WarpDeplete.OnEncounterStart, self)
  self:RegisterEvent("ENCOUNTER_END", WarpDeplete.OnEncounterEnd, self)
  self:RegisterEvent("PLAYER_DEAD", WarpDeplete.OnPlayerDead, self)
  self:RegisterEvent("PLAYER_REGEN_ENABLED", WarpDeplete.OnPlayerRegenEnabled, self)
  self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", WarpDeplete.OnThreatListUpdate, self)
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

function WarpDeplete:EnableDemoMode()
  local Util = WarpDeplete.Util

  if self.challengeState.demoModeActive then return end
  self.challengeState.demoModeActive = true

  self.forcesState = Util.copy(self.defaultForcesState)
  self.timerState = Util.copy(self.defaultTimerState)

  self:SetTimerLimit(35 * 60)
  self:SetTimerRemaining(8 * 60)
  self:SetForcesCurrent(34)
  self:SetForcesPull(7)

  self:Show()
end

function WarpDeplete:DisableDemoMode()
  if not self.challengeState.demoModeActive then return end
  self.challengeState.demoModeActive = false
  self:Hide()
end

function WarpDeplete:Show()
  self.frames.root:Show()
  ObjectiveTrackerFrame:Hide()
end

function WarpDeplete:Hide()
  self.frames.root:Hide()
  ObjectiveTrackerFrame:Show()
end

function WarpDeplete:OnCheckChallengeMode(ev)
  self:Print("|cFF09ED3AG_EVENT|r: " .. ev)
end

function WarpDeplete:OnChallengeModeStart(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnChallengeModeReset(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnChallengeModeCompleted(ev)
  self:Print("|cFFA134EBEVENT|r: " .. ev)
end

function WarpDeplete:OnKeystoneOpen(ev)
  local difficulty = select(3, GetInstanceInfo())
  if difficulty ~= 8 and difficulty ~= 23 then
    return
  end

  for bagIndex = 0, NUM_BAG_SLOTS do
    for invIndex = 1, GetContainerNumSlots(bagIndex) do
      local itemID = GetContainerItemID(bagIndex, invIndex)
      if itemID and (itemID == 180653) then
        PickupContainerItem(bagIndex, invIndex)
        C_Timer.After(0.1, function()
          if CursorHasItem() then
            C_ChallengeMode.SlotKeystone()
          end
        end)
      end
    end
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
