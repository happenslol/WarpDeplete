local Util = WarpDeplete.Util
local L = WarpDeplete.L

local function font(name, profileVar, updateFn, extraOptions)
  local result = {
    type = "select",
    dialogControl = "LSM30_Font",
    name = name,
    values = WarpDeplete.LSM:HashTable("font"),
    get = function(info) return WarpDeplete.db.profile[profileVar] end,
    set = function(info, value)
      WarpDeplete.db.profile[profileVar] = value
      WarpDeplete[updateFn](WarpDeplete)
    end
  }

  if extraOptions and type(extraOptions) == "table" then
    for k, v in pairs(extraOptions) do
      result[k] = v
    end
  end

  return result
end

local function range(name, profileVar, updateFn, extraOptions)
  local result = {
    type = "range",
    name = name,
    min = 8,
    max = 40,
    step = 1,
    get = function(info) return WarpDeplete.db.profile[profileVar] end,
    set = function(info, value)
      WarpDeplete.db.profile[profileVar] = value
      WarpDeplete[updateFn](WarpDeplete)
    end
  }

  if extraOptions and type(extraOptions) == "table" then
    for k, v in pairs(extraOptions) do
      result[k] = v
    end
  end

  return result
end

local function toggle(name, profileVar, updateFn, extraOptions)
  local result = {
    type = "toggle",
    name = name,
    get = function(info) return WarpDeplete.db.profile[profileVar] end,
    set = function(info, value)
      WarpDeplete.db.profile[profileVar] = value
      WarpDeplete[updateFn](WarpDeplete)
    end
  }

  if extraOptions and type(extraOptions) == "table" then
    for k, v in pairs(extraOptions) do
      result[k] = v
    end
  end

  return result
end

local function fontFlags(name, profileVar, updateFn, extraOptions)
  local result = {
    type = "select",
    name = name,
    desc = L["Default:"] .. " " .. L["OUTLINE"],
    values = {
      ["OUTLINE"] = L["OUTLINE"],
      ["THICKOUTLINE"] = L["THICKOUTLINE"],
      ["MONOCHROME"] = L["MONOCHROME"],
      ["NONE"] = L["NONE"]
    },
    get = function(info) return WarpDeplete.db.profile[profileVar] end,
    set = function(info, value)
      WarpDeplete.db.profile[profileVar] = value
      WarpDeplete[updateFn](WarpDeplete)
    end
  }

  if extraOptions and type(extraOptions) == "table" then
    for k, v in pairs(extraOptions) do
      result[k] = v
    end
  end

  return result
end

local function lineBreak(hidden, width)
  local result = {
    type = "description",
    name = "\n",
    hidden = hidden or false,
  }

  if width then result.width = width end

  return result
end

local function color(name, profileVar, updateFn, extraOptions)
  local result = {
    type = "color",
    name = name,
    get = function(info)
      local r, g, b, a = Util.hexToRGB(WarpDeplete.db.profile[profileVar])
      return r, g, b, a or 1
    end,
    set = function(info, r, g, b, a)
      WarpDeplete.db.profile[profileVar] = Util.rgbToHex(r, g, b, a)
      WarpDeplete[updateFn](WarpDeplete)
    end
  }

  if extraOptions and type(extraOptions) == "table" then
    for k, v in pairs(extraOptions) do
      result[k] = v
    end
  end

  return result
end

local function barTexture(name, profileVar, updateFn, extraOptions)
  local result = {
    name = name,
    type = "select",
    dialogControl = 'LSM30_Statusbar',
    values = WarpDeplete.LSM:HashTable("statusbar"),
    get = function(info) return WarpDeplete.db.profile[profileVar] end,
    set = function(info, value)
      WarpDeplete.db.profile[profileVar] = value
      WarpDeplete[updateFn](WarpDeplete)
    end
  }

  if extraOptions and type(extraOptions) == "table" then
    for k, v in pairs(extraOptions) do
      result[k] = v
    end
  end

  return result
end

local function group(name, inline, args, extraOptions)
  local order = 1

  local result = {
    name = name,
    inline = inline,
    type = "group",
    args = {}
  }

  for _, arg in pairs(args) do
    arg.order = order
    result.args[arg.type .. order] = arg
    order = order + 1
  end

  if extraOptions and type(extraOptions) == "table" then
    for k, v in pairs(extraOptions) do
      result[k] = v
    end
  end

  return result
end

function WarpDeplete:InitOptions()
  self.isUnlocked = false

  local options = {
    name = "WarpDeplete",
    handler = self,
    type = "group",
    childGroups = "tab",
    args = {
        unlocked = {
          order = 1,
          type = "toggle",
          name = L["Unlocked"],
          desc = L["Unlocks the timer window and allows it to be moved around"],
          get = function(info) return WarpDeplete.isUnlocked end,
          set = WarpDeplete.SetUnlocked
        },

        demo = {
          order = 2,
          type = "toggle",
          name = L["Demo Mode"],
          desc = L["Enables the demo mode, used for configuring the timer"],
          get = function(info) return WarpDeplete.challengeState.demoModeActive end,
          set = function(info, value)
            if value then WarpDeplete:EnableDemoMode()
            else WarpDeplete:DisableDemoMode() end
          end
        },
      general = group(L["General"], false, {
        lineBreak(),
        toggle(L["Insert keystone automatically"], "insertKeystoneAutomatically", "UpdateLayout"),
        toggle(L["Show millisecond precision after dungeon completion"], "showMillisecondsWhenDungeonCompleted", "UpdateLayout"),
        lineBreak(),

        group(L["Forces Display"], true, {
          {
            type = "select",
            name = L["Forces text format"],
            desc = L["Choose how your forces progress will be displayed"],
            sorting = {
              ":percent:",
              ":count:/:totalcount:",
              ":count:/:totalcount: - :percent:",
              ":custom:"
            },
            values = {
              [":percent:"] = "82.52%",
              [":count:/:totalcount:"] = "198/240",
              [":count:/:totalcount: - :percent:"] = "198/240 - 82.52%",
              [":custom:"] = L["Custom"],
            },
            get = function(info) return WarpDeplete.db.profile.forcesFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.forcesFormat = value
              WarpDeplete:UpdateLayout()
            end
          },
          lineBreak(function() return WarpDeplete.db.profile.forcesFormat == ":custom:" end, 2),

          {
            type = "input",
            name = L["Custom forces text format"],
            desc = L["Use the following tags to set your custom format"] .. ":"
              .. "\n- :percent: " .. L["Shows the current forces percentage (e.g. 82.52%)"]
              .. "\n- :count: " .. L["Shows the current forces count (e.g. 198)"]
              .. "\n- :totalcount: " .. L["Shows the total forces count (e.g. 240)"]
              .. "\n- :remainingcount: " .. L["Shows the remaining amount of forces needed to complete"]
              .. "\n- :remainingcountafterpull: " .. L["Shows the remaining amount of forces needed to complete after current pull"]
              .. "\n- :remainingpercent: " .. L["Shows the remaining percentage of forces to achieve 100%"]
              .. "\n- :remainingpercentafterpull: " .. L["Shows the remaining percentage of forces to achieve 100% after current pull"],
            multiline = false,
            width = 2,
            hidden = function() return WarpDeplete.db.profile.forcesFormat ~= ":custom:" end,
            get = function(info) return WarpDeplete.db.profile.customForcesFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.customForcesFormat = value
              WarpDeplete:UpdateLayout()
            end,
          },

          {
            type = "select",
            name = L["Current pull text format"],
            desc = L["Choose how your current pull count will be displayed"],
            sorting = {
              "(+:percent:)",
              "(+:count:)",
              "(+:count: - :percent:)",
              ":custom:"
            },
            values = {
              ["(+:percent:)"] = "(+5.32%)",
              ["(+:count:)"] = "(+14)",
              ["(+:count: - :percent:)"] = "(+14 / 5.32%)",
              [":custom:"] = L["Custom"],
            },
            get = function(info) return WarpDeplete.db.profile.currentPullFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.currentPullFormat = value
              WarpDeplete:UpdateLayout()
            end
          },
          lineBreak(function() return WarpDeplete.db.profile.currentPullFormat == ":custom:" end, 2),

          {
            type = "input",
            name = L["Custom current pull text format"],
            desc = L["Use the following tags to set your custom format"] .. ":"
              .. "\n- :percent: " .. L["Shows the current forces percentage (e.g. 82.52%)"]
              .. "\n- :count: " .. L["Shows the current forces count (e.g. 198)"],
            multiline = false,
            width = 2,
            hidden = function() return WarpDeplete.db.profile.currentPullFormat ~= ":custom:" end,
            get = function(info) return WarpDeplete.db.profile.customCurrentPullFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.customCurrentPullFormat = value
              WarpDeplete:UpdateLayout()
            end,
          },
        }),

        group(L["Forces count in tooltip"], true, {
          toggle(L["Show forces count in tooltip"], "showTooltipCount", "UpdateLayout", {
            desc = L["Add a line to the tooltip, showing how much count a mob will award upon death"]
          }),
          lineBreak(function() return not WarpDeplete.db.profile.showTooltipCount end, 3),

          {
            type = "select",
            name = L["Tooltip forces text format"],
            desc = L["Choose how count will be displayed in the tooltip"],
            sorting = {
              "+:count: / :percent:",
              "+:count:",
              "+:percent:",
              ":custom:"
            },
            values = {
              ["+:percent:"] = "+5.32%",
              ["+:count:"] = "+14",
              ["+:count: / :percent:"] = "+14 / 5.32%",
              [":custom:"] = L["Custom"],
            },
            hidden = function() return not WarpDeplete.db.profile.showTooltipCount end,
            get = function(info) return WarpDeplete.db.profile.tooltipCountFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.tooltipCountFormat = value
              WarpDeplete:UpdateLayout()
            end
          },

          {
            type = "input",
            name = L["Custom tooltip forces count format"],
            desc = L["Use the following tags to set your custom format"] .. ":"
              .. "\n- :percent: ".. L["Shows the forces percentage the enemy will award (e.g. 1.4%)"]
              .. "\n- :count: ".. L["Shows the count the enemy will award (e.g. 4)"],
            multiline = false,
            width = 2,
            hidden = function()
              return WarpDeplete.db.profile.tooltipCountFormat ~= ":custom:" or
                not WarpDeplete.db.profile.showTooltipCount
            end,
            get = function(info) return WarpDeplete.db.profile.customTooltipCountFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.customTooltipCountFormat = value
              WarpDeplete:UpdateLayout()
            end,
          },
        }),

        group(L["Forces Glow"], true, {
          {
            type = "toggle",
            name = L["Show Forces Glow"],
            desc = L["Show a glow around the forces action bar if the current pull will bring it to 100%"],
            get = function(info) return WarpDeplete.db.profile.showForcesGlow end,
            set = function(info, value)
              WarpDeplete.db.profile.showForcesGlow = value
              WarpDeplete:UpdateDemoModeForces()
              WarpDeplete:UpdateLayout()
            end
          },

          {
            type = "toggle",
            name = L["Show in Demo Mode"],
            desc = L["Show the forces glow in demo mode"],
            hidden = function() return not WarpDeplete.db.profile.showForcesGlow end,
            get = function(info) return WarpDeplete.db.profile.demoForcesGlow end,
            set = function(info, value)
              WarpDeplete.db.profile.demoForcesGlow = value
              WarpDeplete:UpdateDemoModeForces()
              WarpDeplete:UpdateLayout()
            end
          },

          lineBreak(function() return not WarpDeplete.db.profile.showForcesGlow end, 3),

          color(L["Color"], "forcesGlowColor", "UpdateGlowAppearance", {
            hidden = function() return not WarpDeplete.db.profile.showForcesGlow end,
            width = 1 / 2,
          }),

          lineBreak(function() return not WarpDeplete.db.profile.showForcesGlow end, 3),

          range(L["Line Count"], "forcesGlowLineCount", "UpdateGlowAppearance", {
            hidden = function() return not WarpDeplete.db.profile.showForcesGlow end,
            min = 1, max = 30, step = 1, width = 5 / 6,
          }),

          range(L["Line Length"], "forcesGlowLength", "UpdateGlowAppearance", {
            hidden = function() return not WarpDeplete.db.profile.showForcesGlow end,
            min = 1, max = 10, step = 1, width = 5 / 6,
          }),

          range(L["Line Thickness"], "forcesGlowThickness", "UpdateGlowAppearance", {
            hidden = function() return not WarpDeplete.db.profile.showForcesGlow end,
            min = 1, max = 5, step = 0.1, width = 5 / 6,
          }),

          range(L["Frequency"], "forcesGlowFrequency", "UpdateGlowAppearance", {
            hidden = function() return not WarpDeplete.db.profile.showForcesGlow end,
            min = 0.05, max = 0.5, step = 0.01, width = 5 / 6,
          }),
        }),

        group(L["Death log tooltip"], true, {
          {
            type = "toggle",
            name = L["Show death log when hovering deaths text"],
            desc = L["NOTE: This will only record deaths that happen while you're online. If you disconnect and/or reconnect, this will not show deaths that happened previously."],
            get = function(info) return WarpDeplete.db.profile.showDeathsTooltip end,
            set = function(info, value) WarpDeplete.db.profile.showDeathsTooltip = value end,
            width = 3 / 2,
          },
          {
            type = "select",
            name = L["Death log style"],
            desc = L["Choose how players deaths will be displayed in the tooltip. Hover the deaths text while in demo mode for a preview."],
            sorting = {
              "count",
              "time"
            },
            values = {
              ["count"] = L["Overall amount of deaths by player"],
              ["time"] = L["Recent deaths with timestamps"]
            },
            hidden = function() return not WarpDeplete.db.profile.showDeathsTooltip end,
            get = function(info) return WarpDeplete.db.profile.deathLogStyle end,
            set = function(info, value) WarpDeplete.db.profile.deathLogStyle = value end,
            width = 3 / 2
          }
        }),

        group(L["Timings"], true, {
          {
            type = "toggle",
            name = L["Enable timings"],
            desc = L["Enable recording of timestamps at which bosses have been killed"],
            get = function(info) return WarpDeplete.db.profile.timingsEnabled end,
            set = function(info, value)
               WarpDeplete.db.profile.timingsEnabled = value
               self:UpdateLayout()
            end,
            width = 1
          },
          {
            type = "toggle",
            name = L["Only record completed runs"],
            desc = L["When active, timestamps are only recorded once the key has been finished"],
            get = function(info) return WarpDeplete.db.profile.timingsOnlyCompleted end,
            set = function(info, value) WarpDeplete.db.profile.timingsOnlyCompleted = value end,
            width = 2
          }
        })
      }, { order = 3 }),

      texts = group(L["Display"], false, {
        group(L["General"], true, {
          {
            type = "select",
            name = L["Text Alignment"],
            desc = L["Choose the alignment for all texts in the timer window"],
            sorting = { "right", "left" },
            values = {
              ["left"] = L["Left"],
              ["right"] = L["Right"],
            },
            get = function(info) return WarpDeplete.db.profile.alignTexts end,
            set = function(info, value)
              WarpDeplete.db.profile.alignTexts = value
              WarpDeplete:UpdateLayout()
            end
          },
          {
            type = "select",
            name = L["Bar Text Alignment"],
            desc = L["Choose the alignment for the captions on the timer and forces bars"],
            sorting = { "right", "left" },
            values = {
              ["left"] = L["Left"],
              ["right"] = L["Right"],
            },
            get = function(info) return WarpDeplete.db.profile.alignBarTexts end,
            set = function(info, value)
              WarpDeplete.db.profile.alignBarTexts = value
              WarpDeplete:UpdateLayout()
            end
          },
          {
            type = "select",
            name = L["Boss Clear Time Position"],
            desc = L["Choose where the clear times for bosses will be displayed"],
            sorting = { "start", "end" },
            values = {
              ["start"] = L["Start"],
              ["end"] = L["End"],
            },
            get = function(info) return WarpDeplete.db.profile.alignBossClear end,
            set = function(info, value)
              WarpDeplete.db.profile.alignBossClear = value
              WarpDeplete:UpdateObjectivesDisplay()
            end
          },

          lineBreak(),

          range(L["Element Padding"], "verticalOffset", "UpdateLayout",
            { min = 0, max = 100, step = 0.01 }),
          range(L["Boss Name Padding"], "objectivesOffset", "UpdateLayout",
            { min = 0, max = 100, step = 0.01 }),
          range(L["Bar Padding"], "barPadding", "UpdateLayout",
            { min = 0, max = 100, step = 0.01 }),
        }),

        group(L["Timer Colors"], true, {
          color(L["Timer color"], "timerRunningColor", "UpdateLayout"),
          color(L["Timer success color"], "timerSuccessColor", "UpdateLayout"),
          color(L["Timer expired color"], "timerExpiredColor", "UpdateLayout"),
        }, { desc = L["These colors are used for both the main timer, as well as the bar texts."] }),

        group(L["Main Timer"], true, {
          font(L["Timer font"], "timerFont", "UpdateLayout"),
          range(L["Timer font size"], "timerFontSize", "UpdateLayout", { max = 80 }),
          fontFlags(L["Timer font flags"], "timerFontFlags", "UpdateLayout"),
        }),

        group(L["Deaths"], true, {
          font(L["Deaths font"], "deathsFont", "UpdateLayout"),
          range(L["Deaths font size"], "deathsFontSize", "UpdateLayout"),
          fontFlags(L["Deaths font flags"], "deathsFontFlags", "UpdateLayout"),
          color(L["Deaths color"], "deathsColor", "UpdateLayout"),
        }),

        group(L["Key Details"], true, {
          font(L["Key font"], "keyFont", "UpdateLayout"),
          range(L["Key font size"], "keyFontSize", "UpdateLayout"),
          fontFlags(L["Key font flags"], "keyFontFlags", "UpdateLayout"),
          color(L["Key color"], "keyColor", "UpdateLayout"),

          lineBreak(),
          
          font(L["Key details font"], "keyDetailsFont", "UpdateLayout"),
          range(L["Key details font size"], "keyDetailsFontSize", "UpdateLayout"),
          fontFlags(L["Key details font flags"], "keyDetailsFontFlags", "UpdateLayout"),
          color(L["Key details color"], "keyDetailsColor", "UpdateLayout"),
        }),

        group(L["Bars"], true, {
          range(L["Bar width"], "barWidth", "UpdateLayout",
            { width = "full", min = 10, max = 600 }),
          range(L["Bar height"], "barHeight", "UpdateLayout",
            { width = "full", min = 4, max = 50 })
        }),

        group(L["+1 Timer"], true, {
          font(L["+1 Timer font"], "bar1Font", "UpdateLayout"),
          range(L["+1 Timer font size"], "bar1FontSize", "UpdateLayout"),
          fontFlags(L["+1 Timer font flags"], "bar1FontFlags", "UpdateLayout"),

          barTexture(L["+1 Timer bar texture"], "bar1Texture", "UpdateLayout", { width = "double" }),
          color(L["+1 Timer bar color"], "bar1TextureColor", "UpdateLayout"),
        }),

        group(L["+2 Timer"], true, {
          font(L["+2 Timer font"], "bar2Font", "UpdateLayout"),
          range(L["+2 Timer font size"], "bar2FontSize", "UpdateLayout"),
          fontFlags(L["+2 Timer font flags"], "bar2FontFlags", "UpdateLayout"),

          barTexture(L["+2 Timer bar texture"], "bar2Texture", "UpdateLayout", { width = "double" }),
          color(L["+2 Timer bar color"], "bar2TextureColor", "UpdateLayout") ,
        }),

        group(L["+3 Timer"], true, {
          font(L["+3 Timer font"], "bar3Font", "UpdateLayout"),
          range(L["+3 Timer font size"], "bar3FontSize", "UpdateLayout"),
          fontFlags(L["+3 Timer font flags"], "bar3FontFlags", "UpdateLayout"),

          barTexture(L["+3 Timer bar texture"], "bar3Texture", "UpdateLayout", { width = "double" }),
          color(L["+3 Timer bar color"], "bar3TextureColor", "UpdateLayout"),
        }),

        group(L["Forces"], true, {
          font(L["Forces font"], "forcesFont", "UpdateLayout"),
          range(L["Forces font size"], "forcesFontSize", "UpdateLayout"),
          fontFlags(L["Forces font flags"], "forcesFontFlags", "UpdateLayout"),
          color(L["Forces color"], "forcesColor", "UpdateLayout"),
          color(L["Completed forces color"], "completedForcesColor", "UpdateLayout"),

          lineBreak(),

          barTexture(L["Forces bar texture"], "forcesTexture", "UpdateLayout", { width = "double" }),
          color(L["Forces bar color"], "forcesTextureColor", "UpdateLayout"),

          lineBreak(),

          barTexture(L["Current pull bar texture"], "forcesOverlayTexture", "UpdateLayout", { width = "double" }),
          color(L["Current pull bar color"], "forcesOverlayTextureColor", "UpdateLayout"),
        }),

        group(L["Objectives"], true, {
          font(L["Objectives font"], "objectivesFont", "UpdateLayout", { width = 3 / 2 }),
          fontFlags(L["Objectives font flags"], "objectivesFontFlags", "UpdateLayout", { width = 3 / 2 }),
          range(L["Objectives font size"], "objectivesFontSize", "UpdateLayout", { width = 3 / 2 }),
          {
            type = "select",
            name = L["Objectives time difference"],
            desc = L["How to display timing differences in the objective display"],
            sorting = {
              "hidden",
              "bestDiff",
              "lastDiff"
            },
            values = {
              ["hidden"] = L["Hidden"],
              ["bestDiff"] = L["Difference to best kill time"],
              ["lastDiff"] = L["Difference to last kill time"]
            },
            hidden = function() return not WarpDeplete.db.profile.timingsEnabled end,
            get = function(info) return WarpDeplete.db.profile.timingsDisplayStyle end,
            set = function(info, value)
              WarpDeplete.db.profile.timingsDisplayStyle = value
              self:UpdateLayout()
            end,
            width = 3 / 2
          },
          color(L["Objectives color"], "objectivesColor", "UpdateLayout"),
          color(L["Completed objective color"], "completedObjectivesColor", "UpdateLayout"),
          color(L["New best objective clear time"], "timingsImprovedTimeColor", "UpdateLayout", {
            desc = L["The color to use when you've set a new best objective clear time"]
          }),
          color(L["Slower objective clear time"], "timingsWorseTimeColor", "UpdateLayout", {
            desc = L["The color to use for objective clear times slower than your best time"]
          }),
        }),
      }, { order = 4 }),
    }
  }

  local debugOptions = group("Debug", false, {
    {
      type = "range",
      name = L["Timer limit (Minutes)"],
      min = 1,
      max = 100,
      step = 1,
      get = function(info) return math.floor(WarpDeplete.timerState.limit / 60) end,
      set = function(info, value) WarpDeplete:SetTimerLimit(value * 60) end
    },

    {
      type = "range",
      name = L["Timer current (Minutes)"],
      min = -50,
      max = 100,
      step = 1,
      get = function(info) return math.floor(WarpDeplete.timerState.remaining / 60) end,
      set = function(info, value) WarpDeplete:SetTimerRemaining(value * 60) end
    },

    {
      type = "range",
      name = L["Forces total"],
      min = 1,
      max = 500,
      step = 1,
      get = function(info) return WarpDeplete.forcesState.totalCount end,
      set = function(info, value) WarpDeplete:SetForcesTotal(value) end
    },

    {
      type = "range",
      name = L["Forces pull"],
      min = 1,
      max = 500,
      step = 1,
      get = function(info) return WarpDeplete.forcesState.pullCount end,
      set = function(info, value) WarpDeplete:SetForcesPull(value) end
    },

    {
      type = "range",
      name = L["Forces current"],
      min = 1,
      max = 500,
      step = 1,
      get = function(info) return WarpDeplete.forcesState.currentCount end,
      set = function(info, value) WarpDeplete:SetForcesCurrent(value) end
    }
  })

  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  if self.db.global.DEBUG then options.args.debug = debugOptions end

  self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("WarpDeplete", options)
  self.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions("WarpDeplete", "WarpDeplete")

  self.configDialog = AceConfigDialog
end

function WarpDeplete:InitChatCommands()
  self:RegisterChatCommand("wdp", "HandleChatCommand")
  self:RegisterChatCommand("warp", "HandleChatCommand")
  self:RegisterChatCommand("warpdeplete", "HandleChatCommand")
  self:RegisterChatCommand("WarpDeplete", "HandleChatCommand")
end

function WarpDeplete:HandleChatCommand(input)
  local cmd = string.lower(input)

  if cmd == "timerstatus" then
    self:PrintDebug("Offset: " .. self.timerState.startOffset .. ", " .. WarpDeplete.Util.formatTime(self.timerState.startOffset))
    self:PrintDebug("Start time: " .. self.timerState.startTime)
    self:PrintDebug("Deaths: " .. self.timerState.deaths)
    local deathPenalty = self.timerState.deaths * 5
    local current = GetTime() - self.timerState.startTime 
    local currentWithOffset = current + self.timerState.startOffset
    self:PrintDebug("Current: " .. current .. ", " .. WarpDeplete.Util.formatTime(current))
    self:PrintDebug("Current With Offset: " .. currentWithOffset .. ", " .. WarpDeplete.Util.formatTime(currentWithOffset))
    local blizzardCurrent = select(2, GetWorldElapsedTime(1))
    self:PrintDebug("Blizzard Current: " .. blizzardCurrent .. ", " .. WarpDeplete.Util.formatTime(blizzardCurrent))
    local blizzardCurrentWODeaths = blizzardCurrent - deathPenalty
    self:PrintDebug("Blizzard Current w/o deaths: " .. blizzardCurrentWODeaths .. ", " .. WarpDeplete.Util.formatTime(blizzardCurrentWODeaths))
    self:PrintDebug("isBlizzardTimer: " .. tostring(self.timerState.isBlizzardTimer))
    return
  end

  if cmd == "toggle" then
    self:SetUnlocked(not self.isUnlocked)
    return
  end

  if cmd == "unlock" then
    self:SetUnlocked(true)
    return
  end

  if cmd == "lock" then
    self:SetUnlocked(false)
    return
  end

  if cmd == "demo" then
    if self.challengeState.demoModeActive then self:DisableDemoMode()
    else self:EnableDemoMode() end
    return
  end

  if cmd == "debug" then
    self.db.global.DEBUG = not self.db.global.DEBUG
    if self.db.global.DEBUG then
      self:Print("|cFF479AEDDEBUG|r Debug mode enabled")
    else
      self:Print("|cFF479AEDDEBUG|r Debug mode disabled")
    end
    return
  end

  -- We have to call this twice in a row due to a stupid bug...
  -- See https://www.wowinterface.com/forums/showthread.php?t=54599
  InterfaceOptionsFrame_OpenToCategory("WarpDeplete")
  InterfaceOptionsFrame_OpenToCategory("WarpDeplete")
end

function WarpDeplete.SetUnlocked(info, value)
  local self = WarpDeplete
  if value == self.isUnlocked then return end

  self.isUnlocked = value
  self.frames.root.texture:SetColorTexture(0, 0, 0, self.isUnlocked and 0.3 or 0)
  self.frames.root:SetMovable(self.isUnlocked)
  self.frames.root:EnableMouse(self.isUnlocked)
end

function WarpDeplete:OnProfileChanged()
  self:UpdateLayout()

  self:UpdateForcesDisplay()
  self:UpdateTimerDisplay()
  self:UpdateObjectivesDisplay()
end
