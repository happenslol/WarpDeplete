WarpDeplete = LibStub("AceAddon-3.0"):NewAddon(
  "WarpDeplete",
  "AceComm-3.0",
  "AceConsole-3.0",
  "AceEvent-3.0",
  "AceTimer-3.0"
)

WarpDeplete.L = LibStub("AceLocale-3.0"):GetLocale("WarpDeplete", true)
local L = WarpDeplete.L

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
  deathDetails = {},

  current = 0,
  remaining = 0,
  limit = 0,
  startOffset = 0,
  limits = {0, 0, 0},

  plusTwo = 0,
  plusThree = 0
}

WarpDeplete.defaultObjectivesState = {}

WarpDeplete.defaultKeyDetailsState = {
  level = 0,
  affixes = {}
}

-- Check if Kaliel's Tracker is loaded, since it creates a
-- background frame for the objective window that will not be
-- hidden if only the objective window itself is hidden.
local KT = LibStub("AceAddon-3.0"):GetAddon("!KalielsTracker", true)

function WarpDeplete:OnInitialize()
  local frames = {}

  frames.root = CreateFrame("Frame", "WarpDepleteFrame", UIParent)
  frames.bars = CreateFrame("Frame", "WarpDepleteBars", frames.root)
  frames.deathsTooltip = CreateFrame("Frame", "WarpDepleteDeathsTooltip", frames.root)

  self.frames = frames
end

function WarpDeplete:OnEnable()
  self.forcesState = Util.copy(self.defaultForcesState)
  self.timerState = Util.copy(self.defaultTimerState)
  self.challengeState = Util.copy(self.defaultChallengeState)
  self.objectivesState = Util.copy(self.defaultObjectivesState)
  self.keyDetailsState = Util.copy(self.defaultKeyDetailsState)

  self:InitOptions()
  self:InitChatCommands()
  self:InitDisplay()

  self:RegisterGlobalEvents()
  self:RegisterComms()
  self:Hide()

  if not self.db.global.mdtAlertShown and not MDT then
    self.db.global.mdtAlertShown = true
    self:ShowMDTAlert()
  end
end

function WarpDeplete:ShowMDTAlert()
  Util.showAlert(
    "MDT_NOT_FOUND",
    L["Mythic Dungeon Tools (MDT) is not installed."].."\n\n" ..
    L["WarpDeplete will not show you Pride spawn alert or display the count for you current pull."]
    .. " \n\n" .. L["Install MDT to enable this functionality."])
end

function WarpDeplete:OnDisable()
end

function WarpDeplete:EnableDemoMode()
  if self.challengeState.inChallenge then
    self:Print(L["Can't enable demo mode while in an active challenge!"])
    return
  end

  if self.challengeState.demoModeActive then return end

  self:ResetState()
  self.challengeState.demoModeActive = true

  local objectives = {}
  for i = 1, 5 do
    objectives[i] = { name = L["Test Boss Name"] .. " " .. i }

    if i < 3 then
      objectives[i].time = 520 * i
    end
  end

  self:SetObjectives(objectives)
  self:SetKeyDetails(30, {L["Tyrannical"], L["Bolstering"], L["Spiteful"], L["Prideful"]})

  self:SetTimerLimit(35 * 60)
  self:SetTimerRemaining(20 * 60)
  self:SetForcesCurrent(34)
  self:SetForcesPull(7)
  self:SetDeaths(3)

  local classTable = {
    "SHAMAN",
    "DEMONHUNTER",
    "MONK",
    "DRUID",
    "MAGE"
  }

  local nameTable = {
    "GroupMember1",
    "GroupMember2",
    "GroupMember3",
    "GroupMember4",
    "GroupMember5",
  }

  for i = 1, 30 do
    local class = classTable[(i % #classTable) + 1]
    local name = nameTable[(i % #nameTable) + 1]
    local time = i * 7

    self:AddDeathDetails(time, name, class)
  end

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
  if KT ~= nil then
    KT.frame:Hide()
  end
end

function WarpDeplete:Hide()
  self.frames.root:Hide()
  if KT ~= nil then
    KT.frame:Show()
  end
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
