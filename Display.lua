local Util = WarpDeplete.Util

WarpDeplete.defaultForcesState = {
  pullCount = 0,
  currentCount = 0,
  totalCount = 100,

  pullPercent = 0,
  currentPercent = 0,

  prideGlowActive = false,
  completed = false,
  completedTime = 0,
}

WarpDeplete.defaultTimeLimit = 60 * 30
WarpDeplete.defaultTimerState = {
  current = 0,
  remaining = WarpDeplete.defaultTimeLimit,
  limit = WarpDeplete.defaultTimeLimit,

  plusTwo = WarpDeplete.defaultTimeLimit * 0.8,
  plusThree = WarpDeplete.defaultTimeLimit * 0.6
}

function WarpDeplete:InitDisplay()
  self.forcesState = Util.copy(self.defaultForcesState)
  self.timerState = Util.copy(self.defaultTimerState)

  local frameBackgroundAlpha = 0

  -- Retrieve values from profile config
  local deathsFontSize = self.db.profile.deathsFontSize
  local timerFontSize = self.db.profile.timerFontSize
  local keyDetailsFontSize = self.db.profile.keyDetailsFontSize
  local objectivesFontSize = self.db.profile.objectivesFontSize

  local bar1FontSize = self.db.profile.bar1FontSize
  local bar2FontSize = self.db.profile.bar2FontSize
  local bar3FontSize = self.db.profile.bar3FontSize
  local forcesFontSize = self.db.profile.forcesFontSize

  local timerBarOffsetX = self.db.profile.timerBarOffsetX
  local timerBarOffsetY = self.db.profile.timerBarOffsetY

  local barFontOffsetX = self.db.profile.barFontOffsetX
  local barFontOffsetY = self.db.profile.barFontOffsetY

  local barWidth = self.db.profile.barWidth
  local barHeight = self.db.profile.barHeight
  local barPadding = self.db.profile.barPadding

  local framePadding = self.db.profile.framePadding
  local barFramePaddingTop = self.db.profile.barFramePaddingTop
  local barFramePaddingBottom = self.db.profile.barFramePaddingBottom

  local verticalOffset = self.db.profile.verticalOffset
  
  local barFrameHeight =
    -- Add max font height for timer bars
    math.max(bar1FontSize, bar2FontSize, bar3FontSize) +
    2 + -- Account for status bar borders
    (barPadding / 2) + -- Account for padding between bars
    forcesFontSize -- Add forces font size

  local frameHeight = deathsFontSize + verticalOffset +
    timerFontSize + verticalOffset +
    keyDetailsFontSize + barFramePaddingTop +
    barFrameHeight + barFramePaddingBottom +
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
  deathsText:SetPoint("TOPRIGHT", -framePadding - 4, currentOffset)
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
  local r, g, b = Util.hexToRGB("#B1B1B1")
  keyDetailsText:SetTextColor(r, g, b, 1)
  keyDetailsText:SetPoint("TOPRIGHT", -framePadding - 3, currentOffset)
  self.frames.root.keyDetailsText = keyDetailsText

  currentOffset = currentOffset - (keyDetailsFontSize + barFramePaddingTop)

  -- Bars frame

  self.frames.bars:SetWidth(barWidth)
  self.frames.bars:SetHeight(barFrameHeight)
  self.frames.bars:SetPoint("TOPRIGHT", -framePadding, currentOffset)

  local barFrameTexture = self.frames.bars:CreateTexture(nil, "BACKGROUND")
  barFrameTexture:SetAllPoints()
  barFrameTexture:SetColorTexture(0, 0, 0, frameBackgroundAlpha)
  self.frames.bars.texture = barFrameTexture

  -- Bars
  local barPixelAdjust = 0.5

  -- +3 bar
  local bar3Width = barWidth / 100 * 60
  local bar3 = self:CreateProgressBar(
    self.frames.bars, "#979797",
    bar3Width, barHeight,
    0, timerBarOffsetY - barPixelAdjust
  )

  local bar3Text = bar3.bar:CreateFontString(nil, "ARTWORK")
  bar3Text:SetFont(self.LSM:Fetch("font", "Expressway"), bar3FontSize, "OUTLINE")
  bar3Text:SetJustifyH("RIGHT")
  bar3Text:SetText("")
  bar3Text:SetTextColor(1, 1, 1, 1)
  bar3Text:SetPoint("BOTTOMRIGHT", -barFontOffsetX, barFontOffsetY)
  bar3.text = bar3Text

  self.bar3 = bar3

  -- +2 bar
  local bar2Width = barWidth / 100 * 20 - timerBarOffsetX
  local bar2 = self:CreateProgressBar(
    self.frames.bars, "#979797",
    bar2Width, barHeight,
    bar3Width + timerBarOffsetX, timerBarOffsetY - barPixelAdjust
  )

  local bar2Text = bar2.bar:CreateFontString(nil, "ARTWORK")
  bar2Text:SetFont(self.LSM:Fetch("font", "Expressway"), bar2FontSize, "OUTLINE")
  bar2Text:SetJustifyH("RIGHT")
  bar2Text:SetText("")
  bar2Text:SetTextColor(1, 1, 1, 1)
  bar2Text:SetPoint("BOTTOMRIGHT", -barFontOffsetX, barFontOffsetY)
  bar2.text = bar2Text

  self.bar2 = bar2

  -- +1 bar
  local bar1Width = barWidth / 100 * 20 - timerBarOffsetX
  local bar1 = self:CreateProgressBar(
    self.frames.bars, "#979797",
    bar1Width, barHeight,
    bar3Width + bar2Width + timerBarOffsetX * 2, timerBarOffsetY - barPixelAdjust
  )

  local bar1Text = bar1.bar:CreateFontString(nil, "ARTWORK")
  bar1Text:SetFont(self.LSM:Fetch("font", "Expressway"), bar1FontSize, "OUTLINE")
  bar1Text:SetJustifyH("RIGHT")
  bar1Text:SetText("")
  bar1Text:SetTextColor(1, 1, 1, 1)
  bar1Text:SetPoint("BOTTOMRIGHT", -barFontOffsetX, barFontOffsetY)
  bar1.text = bar1Text

  self.bar1 = bar1

  -- Forces bar
  local forces = self:CreateProgressBar(
    self.frames.bars, "#bb9e22",
    barWidth, barHeight,
    0, -timerBarOffsetY
  )

  local forcesText = forces.bar:CreateFontString(nil, "ARTWORK")
  forcesText:SetFont(self.LSM:Fetch("font", "Expressway"), forcesFontSize, "OUTLINE")
  forcesText:SetJustifyH("RIGHT")
  forcesText:SetText("")
  forcesText:SetTextColor(1, 1, 1, 1)
  forcesText:SetPoint("TOPRIGHT", -barFontOffsetX, -barFontOffsetY)
  forces.text = forcesText

  local r, g, b = Util.hexToRGB("#ff5515")
  local forcesOverlayBar = CreateFrame("StatusBar", nil, forces.frame)
  forcesOverlayBar:SetPoint("LEFT", 0, 0)
  forcesOverlayBar:SetSize(barWidth - 2, barHeight - 2)
  forcesOverlayBar:SetMinMaxValues(0, 1)
  forcesOverlayBar:SetValue(0)
  forcesOverlayBar:SetStatusBarTexture(self.LSM:Fetch("statusbar", "ElvUI Blank"))
  forcesOverlayBar:SetStatusBarColor(r, g, b, 0.7)
  forces.overlayBar = forcesOverlayBar

  self.forces = forces

  currentOffset = currentOffset - (barFrameHeight + barFramePaddingBottom)

  -- Objectives

  local objectiveTexts = {}
  local objectivesOffset = 4

  for i = 1, 5 do
    local objectiveText = self.frames.root:CreateFontString(nil, "ARTWORK")
    objectiveText:SetFont(self.LSM:Fetch("font", "Expressway"), objectivesFontSize, "OUTLINE")

    local objectiveTextStr = "Test Boss Name " .. i
    if i < 3 then
      objectiveTextStr = "|cFF00FF24[10:53] " .. objectiveTextStr .. "|r"
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

  -- Disable mouse for the entire frame
  self.frames.root:EnableMouse(false)

  -- Update for initial values
  self:UpdateTimerDisplay()
  self:UpdateForcesDisplay()
end

function WarpDeplete:CreateProgressBar(frame, color, width, height, xOffset, yOffset)
  local result = {}
  local r, g, b = Util.hexToRGB(color)
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
  bar:SetValue(0)
  bar:SetStatusBarTexture(self.LSM:Fetch("statusbar", "ElvUI Blank"))
  bar:SetStatusBarColor(r, g, b)
  result.bar = bar

  return result
end

-- Expects value in seconds
function WarpDeplete:SetTimerLimit(limit)
  self.timerState.limit = limit
  self.timerState.plusTwo = limit * 0.8
  self.timerState.plusThree = limit * 0.6

  self.timerState.remaining = limit - self.timerState.current
  self:UpdateTimerDisplay()
end

-- Expects value in seconds
function WarpDeplete:SetTimerRemaining(remaining)
  self.timerState.remaining = remaining
  self.timerState.current = self.timerState.limit - remaining
  self:UpdateTimerDisplay()
end

-- Expects value in seconds
function WarpDeplete:SetTimerCurrent(time)
  self.timerState.remaining = self.timerState.limit - time
  self.timerState.current = time
end

function WarpDeplete:UpdateTimerDisplay()
  local percent = self.timerState.current / self.timerState.limit
  local bars = {self.bar1, self.bar2, self.bar3}
  local timeLimits = {self.timerState.limit, self.timerState.plusTwo, self.timerState.plusThree}

  local timerText = Util.formatTime(self.timerState.current) ..
    " / " .. Util.formatTime(self.timerState.limit)

  self.frames.root.timerText:SetText(timerText)

  for i = 1, 3 do
    local timeRemaining = timeLimits[i] - self.timerState.current

    local barValue = Util.getBarPercent(i, percent)
    local timeText = Util.formatTime(math.abs(timeRemaining))

    if i == 1 and timeRemaining < 0 then
      timeText = "|c00FF2A2E-".. timeText .. "|r"
    end

    if i ~= 1 and timeRemaining <= 0 then
      timeText = ""
    end

    bars[i].bar:SetValue(barValue)
    bars[i].text:SetText(timeText)
  end
end

function WarpDeplete:SetForcesTotal(totalCount)
  self.forcesState.totalCount = totalCount
  self.forcesState.pullPercent = self.forcesState.pullCount / totalCount

  local currentPercent = self.forcesState.currentCount / totalCount
  if currentPercent > 1.0 then currentPercent = 1.0 end
  self.forcesState.currentPercent = currentPercent

  self.forcesState.completed = false
  self.forcesState.completedTime = 0
  self:UpdateForcesDisplay()
end

-- Expects direct forces value
function WarpDeplete:SetForcesPull(pullCount)
  self.forcesState.pullCount = pullCount
  self.forcesState.pullPercent = pullCount / self.forcesState.totalCount
  self:UpdateForcesDisplay()
end

-- Expects direct forces value
function WarpDeplete:SetForcesCurrent(currentCount)
  if self.forcesState.currentCount < self.forcesState.totalCount and
    currentCount >= self.forcesState.totalCount
  then
    self.forcesState.completed = true
    self.forcesState.completedTime = self.timerState.current
  end

  self.forcesState.currentCount = currentCount

  local currentPercent = self.forcesState.currentCount / self.forcesState.totalCount
  if currentPercent > 1.0 then currentPercent = 1.0 end
  self.forcesState.currentPercent = currentPercent

  self:UpdateForcesDisplay()
end

function WarpDeplete:UpdateForcesDisplay()
  -- clamp pull progress so that the bar won't exceed 100%
  local pullPercent = self.forcesState.pullPercent
  if self.forcesState.pullPercent + self.forcesState.currentPercent > 1 then
    pullPercent = 1 - self.forcesState.currentPercent
  end

  self.forces.overlayBar:SetValue(pullPercent - 0.005)
  self.forces.overlayBar:SetPoint("LEFT", 1 + self.db.profile.barWidth * self.forcesState.currentPercent, 0)
  self.forces.bar:SetValue(self.forcesState.currentPercent)

  self.forces.text:SetText(
    Util.formatForcesText(
      self.forcesState.pullCount,
      self.forcesState.currentCount,
      self.forcesState.totalCount,
      self.forcesState.completed and self.forcesState.completedTime or nil
    )
  )

  self:UpdatePrideGlow()
end

function WarpDeplete:UpdatePrideGlow()
  local percentBeforePull = self.forcesState.currentPercent
  local currentPrideFraction = (percentBeforePull % 0.2)
  local prideFractionAfterPull = currentPrideFraction + self.forcesState.pullPercent
  local shouldGlow = percentBeforePull < 1.0 and prideFractionAfterPull >= 0.2

  -- Already in the correct state
  if shouldGlow == self.forcesState.prideGlowActive then return end

  self.forcesState.prideGlowActive = shouldGlow
  local glowColor = "#CB091E"

  if shouldGlow then
    local glowR, glowG, glowB = Util.hexToRGB(glowColor)
    self.Glow.PixelGlow_Start(
      self.forces.bar, -- frame
      {glowR, glowG, glowB, 1}, -- color
      16, -- line count
      0.13, -- frequency
      18, -- length
      2, -- thiccness
      1.5, -- x offset
      1.5, -- y offset
      false, -- draw border
      "pride", -- tag
      0 -- draw layer
    )
  else
    self.Glow.PixelGlow_Stop(self.forces.bar, "pride")
  end
end

function WarpDeplete:SetDeaths(count)
  local deathText = Util.formatDeathText(count)
  self.frames.root.deathsText:SetText(deathText)
end
