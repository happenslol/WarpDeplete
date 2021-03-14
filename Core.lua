WarpDeplete = LibStub("AceAddon-3.0"):NewAddon(
  "WarpDeplete",
  "AceConsole-3.0",
  "AceEvent-3.0",
  "AceTimer-3.0"
)

local wdp = WarpDeplete
wdp.LSM = LibStub("LibSharedMedia-3.0")
wdp.Glow = LibStub("LibCustomGlow-1.0")

function WarpDeplete:OnInitialize()
  local frames = {}

  frames.root = CreateFrame("Frame", "WarpDepleteFrame", UIParent)
  frames.bars = CreateFrame("Frame", "WarpDepleteBars", frames.root)

  self.frames = frames
end

function WarpDeplete:OnEnable()
  wdp:InitOptions()
  wdp:InitChatCommands()
  wdp:InitDisplay()
end

function WarpDeplete:OnDisable()
end