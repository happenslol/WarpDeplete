function WarpDeplete:InitDisplay()
  local frameBackgroundAlpha = self.isUnlocked and 0.3 or 0

  local deathsFontSize = 16
  local timerFontSize = 34
  local keyDetailsFontSize = 16
  local objectivesFontSize = 18
  local bar1FontSize = 16
  local bar2FontSize = 16
  local bar3FontSize = 16
  local forcesFontSize = 16

  local verticalOffset = 4

  local barFrameHeight = 64
  local barWidth = 360
  local barHeight = 10
  local framePadding = 20

  local frameHeight = deathsFontSize + verticalOffset +
    timerFontSize + verticalOffset +
    keyDetailsFontSize + verticalOffset +
    barFrameHeight + verticalOffset +
    objectivesFontSize * 5 + verticalOffset * 4 +
    framePadding * 2

  self.frames.root:SetWidth(barWidth + framePadding * 2)
  self.frames.root:SetHeight(frameHeight)
  self.frames.root:SetPoint(
    self.db.profile.frameAnchor,
    self.db.profile.frameX,
    self.db.profile.frameY
  )

  local rootFrameTexture = self.frames.root:CreateTexture(nil, "BACKGROUND")
  rootFrameTexture:SetAllPoints(self.frames.root)
  rootFrameTexture:SetColorTexture(0, 0, 0, frameBackgroundAlpha)
  self.frames.root.texture = rootFrameTexture

  local currentOffset = 0 - framePadding

  -- Deaths text

  local deathsText = self.frames.root:CreateFontString(nil, "ARTWORK")
  deathsText:SetFont(self.LSM:Fetch("font", "Expressway"), deathsFontSize, "OUTLINE")
  deathsText:SetJustifyH("RIGHT")
  deathsText:SetText("5 Deaths")
  deathsText:SetTextColor(1, 1, 1, 1)
  deathsText:SetPoint("TOPRIGHT", -framePadding, currentOffset)
  self.frames.root.deathsText = deathsText

  currentOffset = currentOffset - (deathsFontSize + verticalOffset)

  -- Timer text

  local timerText = self.frames.root:CreateFontString(nil, "ARTWORK")
  timerText:SetFont(self.LSM:Fetch("font", "Expressway"), timerFontSize, "OUTLINE")
  timerText:SetJustifyH("RIGHT")
  timerText:SetText("00:00 / 00:00")
  timerText:SetTextColor(1, 1, 1, 1)
  timerText:SetPoint("TOPRIGHT", -framePadding, currentOffset)
  self.frames.root.timerText = timerText

  currentOffset = currentOffset - (timerFontSize + verticalOffset)

  -- Key details text

  local keyDetailsText = self.frames.root:CreateFontString(nil, "ARTWORK")
  keyDetailsText:SetFont(self.LSM:Fetch("font", "Expressway"), keyDetailsFontSize, "OUTLINE")
  keyDetailsText:SetJustifyH("RIGHT")
  keyDetailsText:SetText("[30] Tyrannical - Bolstering - Spiteful - Prideful")
  local r, g, b = hexToRGB("#B1B1B1")
  keyDetailsText:SetTextColor(r, g, b, 1)
  keyDetailsText:SetPoint("TOPRIGHT", -framePadding, currentOffset)
  self.frames.root.keyDetailsText = keyDetailsText

  currentOffset = currentOffset - (keyDetailsFontSize + verticalOffset)

  -- Bars frame

  self.frames.bars:SetWidth(barWidth)
  self.frames.bars:SetHeight(barFrameHeight)
  self.frames.bars:SetPoint("TOPRIGHT", -framePadding, currentOffset)

  local barFrameTexture = self.frames.bars:CreateTexture(nil, "BACKGROUND")
  barFrameTexture:SetAllPoints()
  barFrameTexture:SetColorTexture(0, 0, 0, frameBackgroundAlpha)
  self.frames.bars.texture = barFrameTexture

  -- Bars

  local timerBarOffsetX = 8
  local timerBarOffsetY = 8.4
  local barFontOffsetFactorY = 0.15

  -- +3 bar
  local bar3Width = barWidth / 100 * 60
  local bar3 = self:CreateProgressBar(
    self.frames.bars, "#979797",
    bar3Width, barHeight,
    0, timerBarOffsetY
  )

  local bar3Text = bar3.bar:CreateFontString(nil, "ARTWORK")
  bar3Text:SetFont(self.LSM:Fetch("font", "Expressway"), bar3FontSize, "OUTLINE")
  bar3Text:SetJustifyH("RIGHT")
  bar3Text:SetText("00:00")
  bar3Text:SetTextColor(1, 1, 1, 1)
  bar3Text:SetPoint("BOTTOMRIGHT", -3, bar3FontSize * barFontOffsetFactorY)
  bar3Text:SetDrawLayer("ARTWORK", 5)
  bar3.text = bar3Text

  -- +2 bar
  local bar2Width = barWidth / 100 * 20 - timerBarOffsetX
  local bar2 = self:CreateProgressBar(
    self.frames.bars, "#979797",
    bar2Width, barHeight,
    bar3Width + timerBarOffsetX, timerBarOffsetY
  )

  local bar2Text = bar2.bar:CreateFontString(nil, "ARTWORK")
  bar2Text:SetFont(self.LSM:Fetch("font", "Expressway"), bar2FontSize, "OUTLINE")
  bar2Text:SetJustifyH("RIGHT")
  bar2Text:SetText("00:00")
  bar2Text:SetTextColor(1, 1, 1, 1)
  bar2Text:SetPoint("BOTTOMRIGHT", -3, bar2FontSize * barFontOffsetFactorY)
  bar2Text:SetDrawLayer("ARTWORK", 5)
  bar2.text = bar2Text

  -- +1 bar
  local bar1Width = barWidth / 100 * 20 - timerBarOffsetX
  local bar1 = self:CreateProgressBar(
    self.frames.bars, "#979797",
    bar1Width, barHeight,
    bar3Width + bar2Width + timerBarOffsetX * 2, timerBarOffsetY
  )

  local bar1Text = bar1.bar:CreateFontString(nil, "ARTWORK")
  bar1Text:SetFont(self.LSM:Fetch("font", "Expressway"), bar1FontSize, "OUTLINE")
  bar1Text:SetJustifyH("RIGHT")
  bar1Text:SetText("00:00")
  bar1Text:SetTextColor(1, 1, 1, 1)
  bar1Text:SetPoint("BOTTOMRIGHT", -3, bar1FontSize * barFontOffsetFactorY)
  bar1Text:SetDrawLayer("ARTWORK", 5)
  bar1.text = bar1Text

  -- Forces bar
  local forces = self:CreateProgressBar(
    self.frames.bars, "#bb9e22",
    barWidth, barHeight,
    0, -timerBarOffsetY
  )

  local forcesText = forces.bar:CreateFontString(nil, "ARTWORK")
  forcesText:SetFont(self.LSM:Fetch("font", "Expressway"), forcesFontSize, "OUTLINE")
  forcesText:SetJustifyH("RIGHT")
  forcesText:SetText("(+2.50%)  30.00%")
  forcesText:SetTextColor(1, 1, 1, 1)
  forcesText:SetPoint("TOPRIGHT", -3, forcesFontSize * barFontOffsetFactorY * -1)
  forcesText:SetDrawLayer("ARTWORK", 5)
  forces.text = forcesText

  local r, g, b = hexToRGB("#ff5515")
  local forcesOverlayBar = CreateFrame("StatusBar", nil, forces.frame)
  forcesOverlayBar:SetPoint("LEFT", (barWidth - 2) * 0.5, 0)
  forcesOverlayBar:SetSize(barWidth - 2, barHeight - 2)
  forcesOverlayBar:SetMinMaxValues(0, 1)
  forcesOverlayBar:SetValue(0.05)
  forcesOverlayBar:SetStatusBarTexture(self.LSM:Fetch("statusbar", "ElvUI Blank"))
  forcesOverlayBar:SetStatusBarColor(r, g, b, 0.7)
  forces.overlayBar = forcesOverlayBar

  local glowR, glowG, glowB = hexToRGB("#CB091E")
  self.Glow.PixelGlow_Start(forces.bar, {glowR, glowG, glowB, 1}, 16, 0.13, 18, 2, 1.5, 1.5, false, "pride", 0)

  currentOffset = currentOffset - (barFrameHeight + verticalOffset)

  -- Objectives

  local objectiveTexts = {}
  local objectivesOffset = 4

  for i = 1, 5 do
    local objectiveText = self.frames.root:CreateFontString(nil, "ARTWORK")
    objectiveText:SetFont(self.LSM:Fetch("font", "Expressway"), objectivesFontSize, "OUTLINE")

    local objectiveTextStr = "[10:53] Test Boss Name " .. i
    if i < 3 then
      objectiveTextStr = "|cFF00FF24" .. objectiveTextStr .. "|r"
    end

    objectiveText:SetJustifyH("RIGHT")
    objectiveText:SetText(objectiveTextStr)
    objectiveText:SetTextColor(1, 1, 1, 1)
    objectiveText:SetPoint("TOPRIGHT", -framePadding, currentOffset)
    objectiveTexts[i] = objectiveText

    currentOffset = currentOffset - (objectivesFontSize + objectivesOffset)
  end

  self.frames.root.objectiveTexts = objectiveTexts

  self.frames.root:SetMovable(self.isUnlocked)
  self.frames.root:SetScript("OnMouseDown", function(frame, button)
    if self.isUnlocked and button == "LeftButton" and not frame.isMoving then
      frame:StartMoving()
      frame.isMoving = true
    end
  end)

  self.frames.root:SetScript("OnMouseUp", function(frame, button)
    if button == "LeftButton" and frame.isMoving then
      frame:StopMovingOrSizing()
      frame.isMoving = false

      local frameAnchor, _, _, frameX, frameY = self.frames.root:GetPoint(1)
      self.db.profile.frameAnchor = frameAnchor
      self.db.profile.frameX = frameX
      self.db.profile.frameY = frameY
    end
  end)

  self.frames.root:SetScript("OnHide", function(frame)
    if frame.isMoving then
      frame:StopMovingOrSizing()
      frame.isMoving = false
    end
  end)
end

function WarpDeplete:CreateProgressBar(frame, color, width, height, xOffset, yOffset)
  local result = {}
  local r, g, b = hexToRGB(color)
  local progress = 0.5

  local barFrame = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  barFrame:SetSize(width, height)
  barFrame:SetPoint("LEFT", xOffset, yOffset)
  barFrame:SetBackdrop({
    bgFile = self.LSM:Fetch("statusbar", "ElvUI Blank"),
    edgeFile = self.LSM:Fetch("border", "Square Full White"),
    edgeSize = 1,
    insets = { top = 1, right = 1, bottom = 1, left = 1 }
  })
  barFrame:SetBackdropColor(0, 0, 0, 0.5)
  barFrame:SetBackdropBorderColor(0, 0, 0, 1)
  result.frame = barFrame

  local bar = CreateFrame("StatusBar", nil, barFrame)
  bar:SetPoint("CENTER", 0, 0)
  bar:SetSize(width - 2, height - 2)
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(progress)
  bar:SetStatusBarTexture(self.LSM:Fetch("statusbar", "ElvUI Blank"))
  bar:SetStatusBarColor(r, g, b)
  result.bar = bar

  function result:SetProgress(p)
    progress = p
    bar:SetValue(p)
  end

  function result:SetWidth(w)
    barFrame:SetWidth(w)
  end

  return result
end

function hexToRGB(hex)
  local hex = hex:gsub("#","")
  if hex:len() == 3 then
    return (tonumber("0x"..hex:sub(1,1))*17)/255, (tonumber("0x"..hex:sub(2,2))*17)/255, (tonumber("0x"..hex:sub(3,3))*17)/255
  else
    return tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255
  end
end