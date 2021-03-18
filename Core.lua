WarpDeplete = LibStub("AceAddon-3.0"):NewAddon(
  "WarpDeplete",
  "AceComm-3.0",
  "AceConsole-3.0",
  "AceEvent-3.0",
  "AceTimer-3.0"
)

WarpDeplete.DEBUG = true

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

  prideGlowActive = false,
  completed = false,
  completedTime = 0,
}

WarpDeplete.defaultTimeLimit = 60 * 30

WarpDeplete.defaultTimerState = {
  startTime = nil,
  isBlizzardTimer = false,

  current = 0,
  remaining = WarpDeplete.defaultTimeLimit,
  limit = WarpDeplete.defaultTimeLimit,

  plusTwo = WarpDeplete.defaultTimeLimit * 0.8,
  plusThree = WarpDeplete.defaultTimeLimit * 0.6
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

  if self.DEBUG then
    self:EnableDemoMode()
  end
end

function WarpDeplete:OnDisable()
end

function WarpDeplete:EnableDemoMode()
  if self.challengeState.demoModeActive then return end
  self.challengeState.demoModeActive = true

  self:ResetState()

  self:SetTimerLimit(35 * 60)
  self:SetTimerRemaining(8 * 60)
  self:SetForcesCurrent(34)
  self:SetForcesPull(7)
  self:SetDeaths(3)

  local objectives = {}
  for i = 1, 5 do
    objectives[i] = { name = "Test Boss Name " .. i }

    if i < 3 then
      objectives[i].time = 530 * i
    end
  end

  self:SetObjectives(objectives)
  self:SetKeyDetails(30, {"Tyrannical", "Bolstering", "Spiteful", "Prideful"})

  -- self:OnChallengeModeStart()

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
  self.forcesState = self.Util.copy(self.defaultForcesState)
  self.timerState = self.Util.copy(self.defaultTimerState)
  self.challengeState = self.Util.copy(self.defaultChallengeState)
  self.objectivesState = self.Util.copy(self.defaultObjectivesState)
  self.keyDetailsState = self.Util.copy(self.defaultKeyDetailsState)
end

function WarpDeplete:OnTimerTick() 
  if not self.challengeState.inChallenge then
    return
  end

  local deaths = C_ChallengeMode.GetDeathCount() or 3
  local deathPenalty = deaths * 5

  local current = GetTime() - self.timerState.startTime + deathPenalty
  if current < 0 then
    return
  end

  self:SetTimerCurrent(current)
  self:UpdateTimerDisplay()

  C_Timer.After(0.1, function() self:OnTimerTick() end)
end