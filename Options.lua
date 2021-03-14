local defaults = {
  profile = {
    frameAnchor = "RIGHT",
    frameX = -20,
    frameY = 0,
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
          }
        }
      }
    }
  }

  self.db = LibStub("AceDB-3.0"):New("WarpDepleteDB", defaults, true)
  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

  local AceConfigDialog = LibStub("AceConfigDialog-3.0")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("WarpDeplete", options)
  self.optionsGeneralFrame = AceConfigDialog:AddToBlizOptions(
    "WarpDeplete", "WarpDeplete",
    nil, "general"
  )

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
  if string.lower(input) == "toggle" then
    self:SetUnlocked(not self.isUnlocked)
    return
  end

  if string.lower(input) == "unlock" then
    self:SetUnlocked(true)
    return
  end

  if string.lower(input) == "lock" then
    self:SetUnlocked(false)
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
end