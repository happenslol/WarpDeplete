WarpDeplete = LibStub("AceAddon-3.0"):NewAddon(
  "WarpDeplete",
  "AceComm-3.0",
  "AceConsole-3.0",
  "AceEvent-3.0",
  "AceTimer-3.0"
)

WarpDeplete.Util = {}
local Util = WarpDeplete.Util

WarpDeplete.LSM = LibStub("LibSharedMedia-3.0")
WarpDeplete.Glow = LibStub("LibCustomGlow-1.0")

WarpDeplete.defaultChallengeState = {
  demoModeActive = false,
  inChallenge = false,
  challengeCompleted = false
}

WarpDeplete.defaultForcesState = {
  pullCount = 0,
  currentCount = 0,
  totalCount = 100,

  pullPercent = 0,
  currentPercent = 0,

  currentPull = {},

  prideGlowActive = false,
  completed = false,
  completedTime = 0
}

WarpDeplete.defaultTimerState = {
  startTime = nil,
  isBlizzardTimer = false,
  running = false,
  deaths = 0,

  current = 0,
  remaining = 0,
  limit = 0,
  startOffset = 0,

  plusTwo = 0,
  plusThree = 0
}

WarpDeplete.defaultObjectivesState = {}

WarpDeplete.defaultKeyDetailsState = {
  level = 0,
  affixes = {}
}

function WarpDeplete:OnInitialize()
  local frames = {}

  frames.root = CreateFrame("Frame", "WarpDepleteFrame", UIParent)
  frames.bars = CreateFrame("Frame", "WarpDepleteBars", frames.root)

  self.frames = frames
end

function WarpDeplete:OnEnable()
  self:InitOptions()
  self:InitChatCommands()
  self:InitDisplay()

  self:ResetState()

  self:RegisterGlobalEvents()
  self:RegisterComms()
  self:Hide()

  if self.db.global.DEBUG then
    self:EnableDemoMode()
  end
end

function WarpDeplete:OnDisable()
end

function WarpDeplete:EnableDemoMode()
  if self.challengeState.inChallenge then
    self:Print("Can't enable demo mode while in an active challenge!")
    return
  end

  if self.challengeState.demoModeActive then return end

  self:ResetState()
  self.challengeState.demoModeActive = true

  local objectives = {}
  for i = 1, 5 do
    objectives[i] = { name = "Test Boss Name " .. i }

    if i < 3 then
      objectives[i].time = 520 * i
    end
  end

  self:SetObjectives(objectives)
  self:SetKeyDetails(30, {"Tyrannical", "Bolstering", "Spiteful", "Prideful"})

  self:SetTimerLimit(35 * 60)
  self:SetTimerRemaining(8 * 60)
  self:SetForcesCurrent(34)
  self:SetForcesPull(7)
  self:SetDeaths(3)

  self:Show()
end

function WarpDeplete:DisableDemoMode()
  if not self.challengeState.demoModeActive then return end
  self.challengeState.demoModeActive = false

  self:Hide()
  self:ResetState()
end

function WarpDeplete:Show()
  self.frames.root:Show()
  self:UpdateLayout()
  ObjectiveTrackerFrame:Hide()
end

function WarpDeplete:Hide()
  self.frames.root:Hide()
  ObjectiveTrackerFrame:Show()
end

function WarpDeplete:ResetState()
  self:PrintDebug("Resetting state")

  self.forcesState = Util.copy(self.defaultForcesState)
  self.timerState = Util.copy(self.defaultTimerState)
  self.challengeState = Util.copy(self.defaultChallengeState)
  self.objectivesState = Util.copy(self.defaultObjectivesState)
  self.keyDetailsState = Util.copy(self.defaultKeyDetailsState)

  self:HidePrideGlow()
end