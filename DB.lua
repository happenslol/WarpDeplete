local defaults = {
  global = {
    DEBUG = false,
    mdtAlertShown = false,
    dbVersion = 1,
  },

  profile = {
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
    unclampForcesPercent = false,
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

    -- Timings
    timingsEnabled = true,
    timingsOnlyCompleted = true,
    timingsDisplayStyle = "bestDiff",
    timingsImprovedTimeColor = "FFF3E600",
    timingsWorseTimeColor = "FFFF5614"
  },

  char = {
    --[[
      Used to save timing differences for the
      current run. We might want to update the values
      in the database right away when a boss is killed
      or we might not, so it's safest to persist the values,
      before and after they were changed, so it will stay
      there even if the user disconnects.

      We basically never need to reset this, and will only
      do so when entering demo mode (which will not overwrite
      anything important since demo mode can't be activated
      during an active challenge).
      This works because we never show this unless the objective
      is completed, and it will always be set anew when the
      objective is completed. So if a value is set here, we
      can assume that the objective was cleared during the current
      run and the time saved here is up to date.
      
      Layout: {
        mapId = <number> or <string>,
        objectives = {
          [objectiveIndex] = {
            lastTime = <number> | nil,
            lastBest = <number> | nil,
            newTime = <number>,
            bestUpdated = <boolean>,
          }
        },
      }
    --]]
    currentRunTimings = {},

    --[[
      Used to save the best and last objective clear
      times for each dungeon.

      Layout: { 
        [mapId] = { 
          [keystoneLevel] = { 
            [affixId] = { 
              [objectiveIndex] = {
                best = <number>,
                last = <number>,
              }
            } 
          } 
        }
      }
    --]]
    timings = {},
  }
}

function WarpDeplete:InitDb()
  self.db = LibStub("AceDB-3.0"):New("WarpDepleteDB", defaults, true)
end
