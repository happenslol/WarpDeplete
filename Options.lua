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
    timerRunningColor = "FFFFFFFF",
    timerExpiredColor = "FFFF2A2E",
    timerSuccessColor = "FF00FF24",
    keyDetailsColor = "FFB1B1B1",
    forcesColor = "FFFFFFFF",
    completedForcesColor = "FF00FF24",
    objectivesColor = "FFFFFFFF",
    completedObjectivesColor = "FF00FF24",

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

local function font(name, profileVar, updateFn)
  return {
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

local function range(name, profileVar, updateFn)
  return {
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

local function toggle(name, profileVar, updateFn)
  return {
    type = "toggle",
    name = name,
    get = function(info) return WarpDeplete.db.profile[profileVar] end,
    set = function(info, value)
      WarpDeplete.db.profile[profileVar] = value
      WarpDeplete[updateFn](WarpDeplete)
    end
  }
end

local function fontFlags(name, profileVar, updateFn)
  return {
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

local function lineBreak()
  return {
    type = "description",
    name = "\n"
  }
end

local function color(name, profileVar, updateFn)
  return {
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

local function group(name, inline, args)
  local order = 1

  local g = {
    name = name,
    inline = inline,
    type = "group",
    args = {}
  }

  for _, arg in pairs(args) do
    arg.order = order
    g.args[arg.type .. order] = arg
    order = order + 1
  end

  return g
end

function WarpDeplete:InitOptions()
  self.isUnlocked = false

  local options = {
    name = "WarpDeplete",
    handler = self,
    type = "group",
    args = {
      general = group("General", false, {
        {
          type = "toggle",
          name = "Unlocked",
          desc = "Unlocks the timer window and allows it to be moved around",
          get = function(info) return WarpDeplete.isUnlocked end,
          set = WarpDeplete.SetUnlocked
        },

        {
          type = "toggle",
          name = "Demo Mode",
          desc = "Enables the demo mode, used for configuring the timer",
          get = function(info) return WarpDeplete.challengeState.demoModeActive end,
          set = function(info, value)
            if value then WarpDeplete:EnableDemoMode()
            else WarpDeplete:DisableDemoMode() end
          end
        },

        group("Display", true, {
          toggle("Show forces percent", "showForcesPercent", "UpdateForcesDisplay"),
          toggle("Show forces count", "showForcesCount", "UpdateForcesDisplay"),
        }),

        group("Fonts", true, {
          font("Timer font", "timerFont", "UpdateLayout"),
          range("Timer font size", "timerFontSize", "UpdateLayout"),
          fontFlags("Timer font flags", "timerFontFlags", "UpdateLayout"),
          color("Timer color", "timerRunningColor", "UpdateLayout"),
          color("Timer success color", "timerSuccessColor", "UpdateLayout"),
          color("Timer expired color", "timerExpiredColor", "UpdateLayout"),

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
        })
      })
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
