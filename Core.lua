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

  wdp:RegisterEvents()

  wdp:Hide()
end

function WarpDeplete:OnDisable()
end

function WarpDeplete:RegisterEvents()
  C_ChatInfo.RegisterAddonMessagePrefix("WarpDeplete")

  self:RegisterEvent("CHALLENGE_MODE_START")
  self:RegisterEvent("CHALLENGE_MODE_RESET")
  self:RegisterEvent("CHALLENGE_MODE_COMPLETED")

  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("SCENARIO_POI_UPDATE")
  self:RegisterEvent("WORLD_STATE_TIMER_START")
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function WarpDeplete:CHALLENGE_MODE_START()
end

function WarpDeplete:CHALLENGE_MODE_RESET()
end

function WarpDeplete:CHALLENGE_MODE_COMPLETED()
end

function WarpDeplete:PLAYER_ENTERING_WORLD()
end

function WarpDeplete:SCENARIO_POI_UPDATE()
end

function WarpDeplete:WORLD_STATE_TIMER_START()
end

function WarpDeplete:ZONE_CHANGED_NEW_AREA()
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