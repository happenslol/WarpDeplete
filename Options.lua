local Util = WarpDeplete.Util

local defaults = {
  global = {
    DEBUG = false,
    mdtAlertShown = false,
  },

  profile = {
    frameAnchor = "RIGHT",
    frameX = -20,
    frameY = 0,

    -- Element display options
    forcesFormat = ":percent:",
    customForcesFormat = ":percent:",
    currentPullFormat = "(+:percent:)",
    customCurrentPullFormat = "(+:percent:)",

    showTooltipCount = true,
    tooltipCountFormat = "+:count: - :percent:",
    customTooltipCountFormat = "+:count: - :percent:",

    showDeathsTooltip = true,
    deathLogStyle = "time",
    showObjectives = true,

    -- Font families
    deathsFont = "Expressway",
    timerFont = "Expressway",
    keyDetailsFont = "Expressway",
    bar1Font = "Expressway",
    bar2Font = "Expressway",
    bar3Font = "Expressway",
    forcesFont = "Expressway",
    objectivesFont = "Expressway",

    -- Font flags
    deathsFontFlags = "OUTLINE",
    timerFontFlags = "OUTLINE",
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
    keyDetailsFontSize = 16,
    objectivesFontSize = 18,

    -- Bar font size
    bar1FontSize = 16,
    bar2FontSize = 16,
    bar3FontSize = 16,
    forcesFontSize = 16,

    -- Offset between bars
    timerBarOffsetX = 5,
    timerBarOffsetY = 8.55,

    -- Bar text offset
    barFontOffsetX = 3,
    barFontOffsetY = 3,

    -- Bar dimensions
    barWidth = 360,
    barHeight = 10,
    barPadding = 0,

    -- Frame and bar frame padding
    framePadding = 20,
    barFramePaddingTop = 12,
    barFramePaddingBottom = 16,

    -- The vertical offset between elements
    verticalOffset = 2,

    -- Utility options
    insertKeystoneAutomatically = true
  }
}

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
    desc = "Default: OUTLINE",
    values = {
      ["OUTLINE"] = "OUTLINE",
      ["THICKOUTLINE"] = "THICKOUTLINE",
      ["MONOCHROME"] = "MONOCHROME",
      ["NONE"] = "NONE"
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

local function lineBreak(hidden)
  return {
    type = "description",
    name = "\n",
    hidden = hidden or false
  }
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
          name = "Unlocked",
          desc = "Unlocks the timer window and allows it to be moved around",
          get = function(info) return WarpDeplete.isUnlocked end,
          set = WarpDeplete.SetUnlocked
        },

        demo = {
          order = 2,
          type = "toggle",
          name = "Demo Mode",
          desc = "Enables the demo mode, used for configuring the timer",
          get = function(info) return WarpDeplete.challengeState.demoModeActive end,
          set = function(info, value)
            if value then WarpDeplete:EnableDemoMode()
            else WarpDeplete:DisableDemoMode() end
          end
        },
      general = group("General", false, {

        group("Forces Display", true, {
          {
            type = "select",
            name = "Forces text format",
            desc = "Choose how your forces progress will be displayed",
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
              [":custom:"] = "Custom",
            },
            get = function(info) return WarpDeplete.db.profile.forcesFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.forcesFormat = value
              WarpDeplete:UpdateLayout()
            end
          },

          {
            type = "input",
            name = "Custom forces text format",
            desc = "Use the following tags to set your custom format:\n"
              .. "- :percent: Shows the current forces percentage (e.g. 82.52%)\n"
              .. "- :count: Shows the current forces count (e.g. 198)\n"
              .. "- :totalcount: Shows the total forces count (e.g. 240)",
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
            name = "Current pull text format",
            desc = "Choose how your current pull count will be displayed",
            sorting = {
              "(+:percent:)",
              "(+:count:)",
              "(+:count:/:totalcount: - :percent:)",
              ":custom:"
            },
            values = {
              ["(+:percent:)"] = "(+5.32%)",
              ["(+:count:)"] = "(+14)",
              ["(+:count: / :totalcount: - :percent:)"] = "(+14 / 5.32%)",
              [":custom:"] = "Custom",
            },
            get = function(info) return WarpDeplete.db.profile.currentPullFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.currentPullFormat = value
              WarpDeplete:UpdateLayout()
            end
          },

          {
            type = "input",
            name = "Custom current pull text format",
            desc = "Use the following tags to set your custom format:\n"
              .. "- :percent: Shows the current forces percentage (e.g. 82.52%)\n"
              .. "- :count: Shows the current forces count (e.g. 198)",
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

        group("Forces count in tooltip", true, {
          toggle("Show forces count in tooltip", "showTooltipCount", "UpdateLayout", {
            desc = "Add a line to the tooltip, showing how much count a mob will award upon death"
          }),
          lineBreak(function() return not WarpDeplete.db.profile.showTooltipCount end),

          {
            type = "select",
            name = "Tooltip forces text format",
            desc = "Choose how count will be displayed in the tooltip",
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
              [":custom:"] = "Custom",
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
            name = "Custom tooltip forces count format",
            desc = "Use the following tags to set your custom format:\n"
              .. "- :percent: Shows the current forces percentage (e.g. 82.52%)\n"
              .. "- :count: Shows the current forces count (e.g. 198)",
            multiline = false,
            width = 2,
            hidden = function() return WarpDeplete.db.profile.tooltipCountFormat ~= ":custom:" end,
            get = function(info) return WarpDeplete.db.profile.customTooltipCountFormat end,
            set = function(info, value)
              WarpDeplete.db.profile.customTooltipCountFormat = value
              WarpDeplete:UpdateLayout()
            end,
          },
        }),

        group("Death log tooltip", true, {
          {
            type = "toggle",
            name = "Show death log when hovering deaths text",
            desc = "NOTE: This will only record deaths that happen while you're online. If you disconnect and/or reconnect, this will not show deaths that happened previously.",
            get = function(info) return WarpDeplete.db.profile.showDeathsTooltip end,
            set = function(info, value) WarpDeplete.db.profile.showDeathsTooltip = value end,
            width = 3 / 2,
          },
          {
            type = "select",
            name = "Death log style",
            desc = "Choose how players deaths will be displayed in the tooltip. Hover the deaths text while in demo mode for a preview.",
            sorting = {
              "count",
              "time"
            },
            values = {
              ["count"] = "Overall amount of deaths by player",
              ["time"] = "Recent deaths with timestamps"
            },
            get = function(info) return WarpDeplete.db.profile.deathLogStyle end,
            set = function(info, value) WarpDeplete.db.profile.deathLogStyle = value end,
            width = 3 / 2
          }
        })
      }, { order = 3 }),

      texts = group("Texts", false, {
        group("Timer Color", true, {
          font("Timer font", "timerFont", "UpdateLayout"),
          range("Timer font size", "timerFontSize", "UpdateLayout"),
          fontFlags("Timer font flags", "timerFontFlags", "UpdateLayout"),
          color("Timer color", "timerRunningColor", "UpdateLayout"),
          color("Timer success color", "timerSuccessColor", "UpdateLayout"),
          color("Timer expired color", "timerExpiredColor", "UpdateLayout"),

          lineBreak(),

          font("Key details font", "keyDetailsFont", "UpdateLayout"),
          range("Key details font size", "keyDetailsFontSize", "UpdateLayout"),
          fontFlags("Key details font flags", "keyDetailsFontFlags", "UpdateLayout"),
          color("Key details color", "keyDetailsColor", "UpdateLayout"),

          lineBreak(),

          font("Forces font", "forcesFont", "UpdateLayout"),
          range("Forces font size", "forcesFontSize", "UpdateLayout"),
          fontFlags("Forces font flags", "forcesFontFlags", "UpdateLayout"),
          color("Forces color", "forcesColor", "UpdateLayout"),
          color("Completed forces color", "completedForcesColor", "UpdateLayout"),

          lineBreak(),

          font("+1 Timer font", "bar1Font", "UpdateLayout"),
          range("+1 Timer font size", "bar1FontSize", "UpdateLayout"),
          fontFlags("+1 Timer font flags", "bar1FontFlags", "UpdateLayout"),

          lineBreak(),

          font("+2 Timer font", "bar2Font", "UpdateLayout"),
          range("+2 Timer font size", "bar2FontSize", "UpdateLayout"),
          fontFlags("+2 Timer font flags", "bar2FontFlags", "UpdateLayout"),

          lineBreak(),

          font("+2 Timer font", "bar3Font", "UpdateLayout"),
          range("+2 Timer font size", "bar3FontSize", "UpdateLayout"),
          fontFlags("+2 Timer font flags", "bar3FontFlags", "UpdateLayout"),

          lineBreak(),

          font("Objectives font", "objectivesFont", "UpdateLayout"),
          range("Objectives font size", "objectivesFontSize", "UpdateLayout"),
          fontFlags("Objectives font flags", "objectivesFontFlags", "UpdateLayout"),
          color("Objectives color", "objectivesColor", "UpdateLayout"),
          color("Completed objective color", "completedObjectivesColor", "UpdateLayout"),
        }),
      }, { order = 4 }),

      bars = group("Bars", false, {
        {
          type = "toggle",
          name = "Show objective bars",
          desc = "Show bars responsible for tracking boss kill times.",
          get = function(info) return WarpDeplete.db.profile.showObjectives end,
          set = function(info, value)
                WarpDeplete.db.profile.showObjectives = value 
                WarpDeplete["UpdateObjectivesDisplay"](WarpDeplete)
          end,
          width = "full",
        },
        group("Size", true, {
          range("Bar width", "barWidth", "UpdateLayout", { width = "full", min = 10, max = 600 }),
          range("Bar height", "barHeight", "UpdateLayout", { width = "full", min = 4, max = 20 })
        }),

        group("Textures and Colors", true, {
          barTexture("+1 Timer bar texture", "bar1Texture", "UpdateLayout", { width = "double" }),
          color("+1 Timer bar color", "bar1TextureColor", "UpdateLayout"),

          lineBreak(),

          barTexture("+2 Timer bar texture", "bar2Texture", "UpdateLayout", { width = "double" }),
          color("+2 Timer bar color", "bar2TextureColor", "UpdateLayout") ,

          lineBreak(),

          barTexture("+3 Timer bar texture", "bar3Texture", "UpdateLayout", { width = "double" }),
          color("+3 Timer bar color", "bar3TextureColor", "UpdateLayout"),

          lineBreak(),

          barTexture("Forces bar texture", "forcesTexture", "UpdateLayout", { width = "double" }),
          color("Forces bar color", "forcesTextureColor", "UpdateLayout"),

          lineBreak(),

          barTexture("Forces bar texture", "forcesTexture", "UpdateLayout", { width = "double" }),
          color("Forces bar color", "forcesTextureColor", "UpdateLayout"),

          lineBreak(),

          barTexture("Current pull bar texture", "forcesOverlayTexture", "UpdateLayout", { width = "double" }),
          color("Current pull bar color", "forcesOverlayTextureColor", "UpdateLayout"),
        })
      }, { order = 5 }),
    }
  }

  local debugOptions = group("Debug", false, {
    {
      type = "range",
      name = "Timer limit (Minutes)",
      min = 1,
      max = 100,
      step = 1,
      get = function(info) return math.floor(WarpDeplete.timerState.limit / 60) end,
      set = function(info, value) WarpDeplete:SetTimerLimit(value * 60) end
    },

    {
      type = "range",
      name = "Timer current (Minutes)",
      min = -50,
      max = 100,
      step = 1,
      get = function(info) return math.floor(WarpDeplete.timerState.remaining / 60) end,
      set = function(info, value) WarpDeplete:SetTimerRemaining(value * 60) end
    },

    {
      type = "range",
      name = "Forces total",
      min = 1,
      max = 500,
      step = 1,
      get = function(info) return WarpDeplete.forcesState.totalCount end,
      set = function(info, value) WarpDeplete:SetForcesTotal(value) end
    },

    {
      type = "range",
      name = "Forces pull",
      min = 1,
      max = 500,
      step = 1,
      get = function(info) return WarpDeplete.forcesState.pullCount end,
      set = function(info, value) WarpDeplete:SetForcesPull(value) end
    },

    {
      type = "range",
      name = "Forces current",
      min = 1,
      max = 500,
      step = 1,
      get = function(info) return WarpDeplete.forcesState.currentCount end,
      set = function(info, value) WarpDeplete:SetForcesCurrent(value) end
    }
  })

  self.db = LibStub("AceDB-3.0"):New("WarpDepleteDB", defaults, true)
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
    if self.timerState.demoModeActive then self:DisableDemoMode()
    else self:EnableDemoMode() end
    return
  end

  if cmd == "debug" then
    self.db.global.DEBUG = not self.db.global.DEBUG
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
