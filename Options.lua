local defaults = {
  --TODO(happens): Add vars for:
  -- * show forces count instead of percent, or both
  -- * font family for all texts
  -- * bar textures
  -- * bar colors

  profile = {
    frameAnchor = "RIGHT",
    frameX = -20,
    frameY = 0,

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

    insertKeystoneAutomatically = true
  }
}

function WarpDeplete:InitOptions()
  self.isUnlocked = false

  local options = {
    name = "WarpDeplete",
    handler = self,
    type = "group",
    args = {
      general = {
        name = "Display",
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
              if value then
                WarpDeplete:EnableDemoMode()
              else
                WarpDeplete:DisableDemoMode()
              end
            end
          },

          --TODO(happens): Improve layout for options (sections for different texts and bars?)
          --TODO(happens): Implement all options
          forcesFontSize = {
            order = 3,
            type = "range",
            name = "Forces Font Size",
            desc = "Changes the font size for the forces count text",
            min = 8,
            max = 40,
            step = 1,
            get = function(info) return WarpDeplete.db.profile.forcesFontSize end,
            set = function(info, value)
              WarpDeplete.db.profile.forcesFontSize = value
              WarpDeplete:UpdateLayout()
            end
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

  if self.DEBUG then options.args.debug = debugOptions end

  self.db = LibStub("AceDB-3.0"):New("WarpDepleteDB", defaults, true)
  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("WarpDeplete", options)
  self.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions(
    "WarpDeplete", "WarpDeplete",
    nil, "general"
  )

  if self.DEBUG then
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
    if self.timerState.demoModeActive then
      self:DisableDemoMode()
    else
      self:EnableDemoMode()
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
