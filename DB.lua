local defaults = {
  global = {
    DEBUG = false,
    mdtAlertShown = false,

    splits = {},
  },

  char = {
    currentChallenge = {
      mapId = nil,
    },
  },

  profile = {
    frameScale = 1,
    frameAnchor = "RIGHT",
    frameX = -20,
    frameY = 0,

    -- Alignment
    alignTexts = "right",
    alignBarTexts = "right",
    alignBossClear = "start",

    -- Element display options
    forcesFormat = ":percent:",
    customForcesFormat = ":percent:",
    currentPullFormat = "(+:percent:)",
    customCurrentPullFormat = "(+:percent:)",

    showForcesGlow = true,
    demoForcesGlow = false,
    forcesGlowColor = "FFD12F14",
    forcesGlowLineCount = 18,
    forcesGlowFrequency = 0.13,
    forcesGlowLength = 10,
    forcesGlowThickness = 2,

    showTooltipCount = true,
    tooltipCountFormat = "+:count: / :percent:",
    customTooltipCountFormat = "+:count: / :percent:",

    showDeathsTooltip = true,
    deathLogStyle = "time",

    -- Font families
    deathsFont = "Expressway",
    timerFont = "Expressway",
    keyFont = "Expressway",
    keyDetailsFont = "Expressway",
    bar1Font = "Expressway",
    bar2Font = "Expressway",
    bar3Font = "Expressway",
    forcesFont = "Expressway",
    objectivesFont = "Expressway",

    -- Font flags
    deathsFontFlags = "OUTLINE",
    timerFontFlags = "OUTLINE",
    keyFontFlags = "OUTLINE",
    keyDetailsFontFlags = "OUTLINE",
    bar1FontFlags = "OUTLINE",
    bar2FontFlags = "OUTLINE",
    bar3FontFlags = "OUTLINE",
    forcesFontFlags = "OUTLINE",
    objectivesFontFlags = "OUTLINE",

    -- Font colors
    deathsColor = "FFFFFFFF",
    timerRunningColor = "FFFFFFFF",
    timerExpiredColor = "FFFF2A2E",
    timerSuccessColor = "FFFFD338",
    keyColor = "FFB1B1B1",
    keyDetailsColor = "FFB1B1B1",
    forcesColor = "FFFFFFFF",
    completedForcesColor = "FF00FF24",
    objectivesColor = "FFFFFFFF",
    completedObjectivesColor = "FF00FF24",

    -- Bar textures
    bar1Texture = "ElvUI Blank",
    bar2Texture = "ElvUI Blank",
    bar3Texture = "ElvUI Blank",
    forcesTexture = "ElvUI Blank",
    forcesOverlayTexture = "ElvUI Blank",

    -- Bar colors
    bar1TextureColor = "FF979797",
    bar2TextureColor = "FF979797",
    bar3TextureColor = "FF979797",
    forcesTextureColor = "FFBB9E22",
    forcesOverlayTextureColor = "FFFF5515",

    -- Font sizes for text parts
    deathsFontSize = 16,
    timerFontSize = 34,
    keyFontSize = 20,
    keyDetailsFontSize = 16,
    objectivesFontSize = 18,

    -- Bar font size
    bar1FontSize = 16,
    bar2FontSize = 16,
    bar3FontSize = 16,
    forcesFontSize = 16,

    -- Offset between bars
    timerBarOffsetX = 5,

    -- Bar text offset
    barFontOffsetX = 3,
    barFontOffsetY = 3,

    -- Bar dimensions
    barWidth = 360,
    barHeight = 10,
    barPadding = 3.8,

    -- Frame padding
    framePadding = 20,
    barFramePaddingTop = 4,
    barFramePaddingBottom = 10,

    -- The vertical offset between elements
    verticalOffset = 2,
    objectivesOffset = 4,

    -- Utility options
    insertKeystoneAutomatically = true,
    showMillisecondsWhenDungeonCompleted = true,

    -- Splits
    splitsEnabled = true,
    showPbsDuringCountdown = true,
    splitFasterTimeColor = "FF64FF64",
    splitSlowerTimeColor = "FFFF5656"
  },
}

function WarpDeplete:InitDb()
  self.db = LibStub("AceDB-3.0"):New("WarpDepleteDB", defaults, true)
end
