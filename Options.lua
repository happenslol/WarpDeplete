local Util = WarpDeplete.Util

local defaults = {
  global = {
    DEBUG = false
  },

  --TODO(happens): Add vars for:
  -- * bar textures
  -- * bar colors

  profile = {
    frameAnchor = "RIGHT",
    frameX = -20,
    frameY = 0,

    -- Element display options
    showForcesPercent = true,
    showForcesCount = true,

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
    timerRunningColor = "#FFFFFFFF",
    timerExpiredColor = "#FFFF2A2E",
    timerSuccessColor = "#FF00FF24",
    keyDetailsColor = "#FFB1B1B1",
    forcesColor = "#FFFFFFFF",
    completedForcesColor = "#FF00FF24",
    objectivesColor = "#FFFFFFFF",
    completedObjectivesColor = "#FF00FF24",

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

local function font(order, name, profileVar, updateFn)
  return {
    order = order,
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
end

local function range(order, name, profileVar, updateFn)
  return {
    order = order,
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
end

local function toggle(order, name, profileVar, updateFn)
  return {
    order = order,
    type = "toggle",
    name = name,
    get = function(info) return WarpDeplete.db.profile[profileVar] end,
    set = function(info, value)
      WarpDeplete.db.profile[profileVar] = value
      WarpDeplete[updateFn](WarpDeplete)
    end
  }
end

local function fontFlags(order, name, profileVar, updateFn)
  return {
    order = order,
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
end

local function lineBreak(order)
  return {
    order = order,
    type = "description",
    name = ""
  }
end

local function color(order, name, profileVar, updateFn)
  return {
    order = order,
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
end

function WarpDeplete:InitOptions()
  self.isUnlocked = false

  local options = {
    name = "WarpDeplete",
    handler = self,
    type = "group",
    args = {
      general = {
        name = "General",
        type = "group",
        args = {
          unlocked = {
            order = 1,
            type = "toggle",
            name = "Unlocked",
            desc = "Unlocks the timer window and allows it to be moved around",
            get = function(info) return WarpDeplete.isUnlocked end,
            set = WarpDeplete.SetUnlocked
          },
          demoMode = {
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

          display = {
            order = 3,
            type = "group",
            inline = true,
            name = "Display",
            args = {
              showForcesPercent = toggle(1, "Show forces percent", "showForcesPercent", "UpdateForcesDisplay"),
              showForcesCount = toggle(2, "Show forces count", "showForcesCount", "UpdateForcesDisplay"),
            }
          },

          fonts = {
            order = 3,
            type = "group",
            name = "Fonts",
            inline = true,
            args = {
              timerFont = font(1, "Timer font", "timerFont", "UpdateLayout"),
              timerFontSize = range(2, "Timer font size", "timerFontSize", "UpdateLayout"),
              timerFontFlags = fontFlags(3, "Timer font flags", "timerFontFlags", "UpdateLayout"),
              timerColor = color(4, "Timer color", "timerRunningColor", "UpdateLayout"),
              timerSuccessColor = color(5, "Timer success color", "timerSuccessColor", "UpdateLayout"),
              timerExpiredColor = color(6, "Timer expired color", "timerExpiredColor", "UpdateLayout"),

              b1 = lineBreak(7),

              forcesFont = font(8, "Forces font", "forcesFont", "UpdateLayout"),
              forcesFontSize = range(9, "Forces font size", "forcesFontSize", "UpdateLayout"),
              forcesFontFlags = fontFlags(10, "Forces font flags", "forcesFontFlags", "UpdateLayout"),
              forcesColor = color(11, "Forces color", "forcesColor", "UpdateLayout"),
              completedForcesColor = color(12, "Completed forces color", "completedForcesColor", "UpdateLayout"),

              b2 = lineBreak(13),

              bar1Font = font(14, "+1 Timer font", "bar1Font", "UpdateLayout"),
              bar1FontSize = range(15, "+1 Timer font size", "bar1FontSize", "UpdateLayout"),
              bar1FontFlags = fontFlags(16, "+1 Timer font flags", "bar1FontFlags", "UpdateLayout"),

              b3 = lineBreak(17),

              bar2Font = font(18, "+2 Timer font", "bar2Font", "UpdateLayout"),
              bar2FontSize = range(19, "+2 Timer font size", "bar2FontSize", "UpdateLayout"),
              bar2FontFlags = fontFlags(20, "+2 Timer font flags", "bar2FontFlags", "UpdateLayout"),

              b4 = lineBreak(18),

              bar3Font = font(19, "+2 Timer font", "bar3Font", "UpdateLayout"),
              bar3FontSize = range(20, "+2 Timer font size", "bar3FontSize", "UpdateLayout"),
              bar3FontFlags = fontFlags(21, "+2 Timer font flags", "bar3FontFlags", "UpdateLayout"),

              b5 = lineBreak(22),

              objectivesFont = font(23, "Objectives font", "objectivesFont", "UpdateLayout"),
              objectivesFontSize = range(24, "Objectives font size", "objectivesFontSize", "UpdateLayout"),
              objectivesFontFlags = fontFlags(25, "Objectives font flags", "objectivesFontFlags", "UpdateLayout"),
              objectivesColor = color(26, "Objectives color", "objectivesColor", "UpdateLayout"),
              completedObjectivesColor = color(27, "Completed objective color", "completedObjectivesColor", "UpdateLayout"),
            },
          }
        }
      }
    }
  }

  local debugOptions = {
    name = "Debug",
    handler = self,
    type = "group",
    args = {
      timerLimit = {
        order = 2,
        type = "range",
        name = "Timer limit (Minutes)",
        min = 1,
        max = 100,
        step = 1,
        get = function(info) return math.floor(WarpDeplete.timerState.limit / 60) end,
        set = function(info, value) WarpDeplete:SetTimerLimit(value * 60) end
      },
      timerRemaining = {
        order = 3,
        type = "range",
        name = "Timer current (Minutes)",
        min = -50,
        max = 100,
        step = 1,
        get = function(info) return math.floor(WarpDeplete.timerState.remaining / 60) end,
        set = function(info, value) WarpDeplete:SetTimerRemaining(value * 60) end
      },
      forcesTotal = {
        order = 4,
        type = "range",
        name = "Forces total",
        min = 1,
        max = 500,
        step = 1,
        get = function(info) return WarpDeplete.forcesState.totalCount end,
        set = function(info, value) WarpDeplete:SetForcesTotal(value) end
      },
      forcesPull = {
        order = 5,
        type = "range",
        name = "Forces pull",
        min = 1,
        max = 500,
        step = 1,
        get = function(info) return WarpDeplete.forcesState.pullCount end,
        set = function(info, value) WarpDeplete:SetForcesPull(value) end
      },
      forcesCurrent = {
        order = 6,
        type = "range",
        name = "Forces current",
        min = 1,
        max = 500,
        step = 1,
        get = function(info) return WarpDeplete.forcesState.currentCount end,
        set = function(info, value) WarpDeplete:SetForcesCurrent(value) end
      }
    }
  }

  self.db = LibStub("AceDB-3.0"):New("WarpDepleteDB", defaults, true)
  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  if self.db.global.DEBUG then options.args.debug = debugOptions end

  self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
  self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("WarpDeplete", options)
  self.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions(
    "WarpDeplete", "WarpDeplete",
    nil, "general"
  )

  if self.db.global.DEBUG then
    self.optionsProfileFrame = AceConfigDialog:AddToBlizOptions(
      "WarpDeplete", "Debug",
      "WarpDeplete", "debug"
    )
  end

  self.optionsProfileFrame = AceConfigDialog:AddToBlizOptions(
    "WarpDeplete", "Profiles",
    "WarpDeplete", "profile"
  )

  self.configDialog = AceConfigDialog
end

function WarpDeplete:InitChatCommands()
  self:RegisterChatCommand("wdp", "HandleChatCommand")
  self:RegisterChatCommand("warpdeplete", "HandleChatCommand")
end

function WarpDeplete:HandleChatCommand(input)
  local cmd = string.lower(input)

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