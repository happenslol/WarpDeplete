local Util = WarpDeplete.Util

function WarpDeplete:InitDisplay()
  local frameBackgroundAlpha = 0

  self.frames.root.texture = self.frames.root:CreateTexture(nil, "BACKGROUND")
  self.frames.root.texture:SetColorTexture(0, 0, 0, frameBackgroundAlpha)

  -- Deaths text
  self.frames.root.deathsText = self.frames.root:CreateFontString(nil, "ARTWORK")

  -- Timer text
  self.frames.root.timerText = self.frames.root:CreateFontString(nil, "ARTWORK")

  -- Key details text
  local keyDetailsText = self.frames.root:CreateFontString(nil, "ARTWORK")
  self.frames.root.keyDetailsText = keyDetailsText

  local barFrameTexture = self.frames.bars:CreateTexture(nil, "BACKGROUND")
  barFrameTexture:SetColorTexture(0, 0, 0, frameBackgroundAlpha)
  self.frames.bars.texture = barFrameTexture

  -- +3 bar
  local bar3 = self:CreateProgressBar(self.frames.bars)

  local bar3Text = bar3.bar:CreateFontString(nil, "ARTWORK")
  bar3.text = bar3Text
  self.bar3 = bar3

  -- +2 bar
  local bar2 = self:CreateProgressBar(self.frames.bars)
  local bar2Text = bar2.bar:CreateFontString(nil, "ARTWORK")
  bar2.text = bar2Text
  self.bar2 = bar2

  -- +1 bar
  local bar1 = self:CreateProgressBar(self.frames.bars)
  local bar1Text = bar1.bar:CreateFontString(nil, "ARTWORK")
  bar1.text = bar1Text
  self.bar1 = bar1

  self.bars = {self.bar1, self.bar2, self.bar3}

  -- Forces bar
  local forces = self:CreateProgressBar(self.frames.bars)
  local forcesText = forces.bar:CreateFontString(nil, "ARTWORK")
  forces.text = forcesText

  local forcesOverlayBar = CreateFrame("StatusBar", nil, forces.frame)
  forces.overlayBar = forcesOverlayBar
  self.forces = forces

  -- Objectives
  local objectiveTexts = {}

  for i = 1, 5 do
    local objectiveText = self.frames.root:CreateFontString(nil, "ARTWORK")
    objectiveTexts[i] = objectiveText
  end

  self.frames.root.objectiveTexts = objectiveTexts

  self:UpdateLayout()

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
end

function WarpDeplete:CreateProgressBar(frame)
  local result = {}
  local progress = 0

  local barFrame = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  result.frame = barFrame

  local bar = CreateFrame("StatusBar", nil, barFrame)
  bar:SetValue(0)
  bar:SetMinMaxValues(0, 1)
  result.bar = bar

  function result:SetLayout(barTexture, color, width, height, xOffset, yOffset)
    local r, g, b = Util.hexToRGB(color)

    barFrame:SetSize(width, height)
    barFrame:SetPoint("LEFT", xOffset, yOffset)
    barFrame:SetBackdrop({
      bgFile = WarpDeplete.LSM:Fetch("statusbar", "ElvUI Blank"),
      edgeFile = WarpDeplete.LSM:Fetch("border", "Square Full White"),
      edgeSize = 1,
      insets = { top = 1, right = 1, bottom = 1, left = 1 }
    })
    barFrame:SetBackdropColor(0, 0, 0, 0.5)
    barFrame:SetBackdropBorderColor(0, 0, 0, 1)

    bar:SetPoint("CENTER", 0, 0)
    bar:SetSize(width - 2, height - 2)
    bar:SetStatusBarTexture(WarpDeplete.LSM:Fetch("statusbar", barTexture))
    bar:SetStatusBarColor(r, g, b)
  end

  return result
end

function WarpDeplete:UpdateLayout()
  -- Retrieve values from profile config
  local deathsFontSize = self.db.profile.deathsFontSize
  local timerFontSize = self.db.profile.timerFontSize
  local keyDetailsFontSize = self.db.profile.keyDetailsFontSize
  local objectivesFontSize = self.db.profile.objectivesFontSize

  local bar1FontSize = self.db.profile.bar1FontSize
  local bar2FontSize = self.db.profile.bar2FontSize
  local bar3FontSize = self.db.profile.bar3FontSize
  local forcesFontSize = self.db.profile.forcesFontSize

  local deathsFont = self.db.profile.deathsFont
  local timerFont = self.db.profile.timerFont
  local keyDetailsFont = self.db.profile.keyDetailsFont
  local bar1Font = self.db.profile.bar1Font
  local bar2Font = self.db.profile.bar2Font
  local bar3Font = self.db.profile.bar3Font
  local forcesFont = self.db.profile.forcesFont
  local objectivesFont = self.db.profile.objectivesFont

  -- Font flags
  local deathsFontFlags = self.db.profile.deathsFontFlags
  local timerFontFlags = self.db.profile.timerFontFlags
  local keyDetailsFontFlags = self.db.profile.keyDetailsFontFlags
  local bar1FontFlags = self.db.profile.bar1FontFlags
  local bar2FontFlags = self.db.profile.bar2FontFlags
  local bar3FontFlags = self.db.profile.bar3FontFlags
  local forcesFontFlags = self.db.profile.forcesFontFlags
  local objectivesFontFlags = self.db.profile.objectivesFontFlags

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
  
  --TODO(happens): Figure out how to calculate this better, this doesn't seem
  -- accurate at all. Maybe we need to use GetTextHeight or something?
  local barFrameHeight =
    -- Add max font height for timer bars
    math.max(bar1FontSize, bar2FontSize, bar3FontSize) * 1.25 +
    2 + -- Account for status bar borders
    (barPadding / 2) + -- Account for padding between bars
    forcesFontSize * 1.25 -- Add forces font size

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

  self.frames.root.texture:SetAllPoints(self.frames.root)

  local r, g, b

  local currentOffset = 0 - framePadding

  -- Deaths text
  local deathsText = self.frames.root.deathsText
  deathsText:SetFont(self.LSM:Fetch("font", deathsFont), deathsFontSize, deathsFontFlags)
  deathsText:SetJustifyH("RIGHT")
  r, g, b = Util.hexToRGB(self.db.profile.deathsColor)
  deathsText:SetTextColor(r, g, b, 1)
  deathsText:SetPoint("TOPRIGHT", -framePadding - 4, currentOffset)

  local deathsTooltipFrameHeight = deathsFontSize + verticalOffset + framePadding
  local deathsTooltipFrameWidth = deathsText:GetStringWidth() + framePadding
  self.frames.deathsTooltip:SetHeight(deathsTooltipFrameHeight)
  self.frames.deathsTooltip:SetWidth(deathsTooltipFrameWidth)
  self.frames.deathsTooltip:SetPoint("TOPRIGHT", -framePadding * 0.5, -framePadding * 0.5)

  currentOffset = currentOffset - (deathsFontSize + verticalOffset)

  -- Timer text
  local timerText = self.frames.root.timerText
  timerText:SetFont(self.LSM:Fetch("font", timerFont), timerFontSize, timerFontFlags)
  timerText:SetJustifyH("RIGHT")
  r, g, b = Util.hexToRGB(self.db.profile.timerRunningColor)
  timerText:SetTextColor(r, g, b, 1)
  timerText:SetPoint("TOPRIGHT", -framePadding, currentOffset)

  currentOffset = currentOffset - (timerFontSize + verticalOffset)

  -- Key details text
  local keyDetailsText = self.frames.root.keyDetailsText
  keyDetailsText:SetFont(self.LSM:Fetch("font", keyDetailsFont), keyDetailsFontSize, keyDetailsFontFlags)
  keyDetailsText:SetJustifyH("RIGHT")
  r, g, b = Util.hexToRGB(self.db.profile.keyDetailsColor)
  keyDetailsText:SetTextColor(r, g, b, 1)
  keyDetailsText:SetPoint("TOPRIGHT", -framePadding - 3, currentOffset)

  currentOffset = currentOffset - (keyDetailsFontSize + barFramePaddingTop)

  -- Bars frame
  self.frames.bars:SetWidth(barWidth)
  self.frames.bars:SetHeight(barFrameHeight)
  self.frames.bars:SetPoint("TOPRIGHT", -framePadding, currentOffset)

  self.frames.bars.texture:SetAllPoints()

  -- Bars
  local barPixelAdjust = 0.5
  local r, g, b = Util.hexToRGB(self.db.profile.timerRunningColor)

  -- +3 bar
  local bar3Width = barWidth / 100 * 60
  self.bar3:SetLayout(self.db.profile.bar3Texture, self.db.profile.bar3TextureColor, bar3Width, barHeight, 0,
    timerBarOffsetY - barPixelAdjust)
  self.bar3.text:SetFont(self.LSM:Fetch("font", bar3Font), bar3FontSize, bar3FontFlags)
  self.bar3.text:SetJustifyH("RIGHT")
  self.bar3.text:SetTextColor(r, g, b, 1)
  self.bar3.text:SetPoint("BOTTOMRIGHT", -barFontOffsetX, barFontOffsetY)

  -- +2 bar
  local bar2Width = barWidth / 100 * 20 - timerBarOffsetX
  self.bar2:SetLayout(self.db.profile.bar2Texture, self.db.profile.bar2TextureColor, bar2Width, barHeight,
    bar3Width + timerBarOffsetX, timerBarOffsetY - barPixelAdjust)
  self.bar2.text:SetFont(self.LSM:Fetch("font", bar2Font), bar2FontSize, bar2FontFlags)
  self.bar2.text:SetJustifyH("RIGHT")
  self.bar2.text:SetTextColor(r, g, b, 1)
  self.bar2.text:SetPoint("BOTTOMRIGHT", -barFontOffsetX, barFontOffsetY)

  -- +1 bar
  local bar1Width = barWidth / 100 * 20 - timerBarOffsetX
  self.bar1:SetLayout(self.db.profile.bar1Texture, self.db.profile.bar1TextureColor, bar1Width, barHeight,
    bar3Width + bar2Width + timerBarOffsetX * 2, timerBarOffsetY - barPixelAdjust)
  self.bar1.text:SetFont(self.LSM:Fetch("font", bar1Font), bar1FontSize, bar1FontFlags)
  self.bar1.text:SetJustifyH("RIGHT")
  self.bar1.text:SetTextColor(r, g, b, 1)
  self.bar1.text:SetPoint("BOTTOMRIGHT", -barFontOffsetX, barFontOffsetY)

  -- Forces bar
  local r, g, b = Util.hexToRGB(self.db.profile.forcesColor)
  self.forces:SetLayout(self.db.profile.forcesTexture, self.db.profile.forcesTextureColor,
    barWidth, barHeight, 0, -timerBarOffsetY)
  self.forces.text:SetFont(self.LSM:Fetch("font", forcesFont), forcesFontSize, forcesFontFlags)
  self.forces.text:SetJustifyH("RIGHT")
  self.forces.text:SetTextColor(r, g, b, 1)
  self.forces.text:SetPoint("TOPRIGHT", -barFontOffsetX, -barFontOffsetY)

  r, g, b = Util.hexToRGB(self.db.profile.forcesOverlayTextureColor)
  self.forces.overlayBar:SetMinMaxValues(0, 1)
  self.forces.overlayBar:SetValue(0)
  self.forces.overlayBar:SetPoint("LEFT", 0, 0)
  self.forces.overlayBar:SetSize(barWidth - 2, barHeight - 2)
  self.forces.overlayBar:SetStatusBarTexture(self.LSM:Fetch("statusbar", self.db.profile.forcesOverlayTexture))
  self.forces.overlayBar:SetStatusBarColor(r, g, b, 0.7)

  currentOffset = currentOffset - (barFrameHeight + barFramePaddingBottom)

  -- Objectives
  local objectivesOffset = 4
  for i = 1, 5 do
    local objectiveText = self.frames.root.objectiveTexts[i]
    objectiveText:SetFont(self.LSM:Fetch("font", objectivesFont), objectivesFontSize, objectivesFontFlags)
    objectiveText:SetJustifyH("RIGHT")
    local r, g, b = Util.hexToRGB(self.db.profile.objectivesColor)
    objectiveText:SetTextColor(r, g, b, 1)
    objectiveText:SetPoint("TOPRIGHT", -framePadding, currentOffset)

    currentOffset = currentOffset - (objectivesFontSize + objectivesOffset)
  end

  -- Update things that set text color through font tags
  self:UpdateTimerDisplay()
  self:UpdateForcesDisplay()
  self:UpdateObjectivesDisplay()
end

-- Expects value in seconds
function WarpDeplete:SetTimerLimit(limit)
  self.timerState.limit = limit
  self.timerState.plusTwo = limit * 0.8
  self.timerState.plusThree = limit * 0.6
  self.timerState.limits = { self.timerState.limit, self.timerState.plusTwo, self.timerState.plusThree }

  self.timerState.remaining = limit - self.timerState.current
  self:UpdateTimerDisplay()
end

-- Expects value in seconds
function WarpDeplete:SetTimerRemaining(remaining)
  if self.timerState.remaining == remaining then
    return
  end
  if self.timerState.current == self.timerState.limit - remaining then
    return
  end
  self.timerState.remaining = remaining
  self.timerState.current = self.timerState.limit - remaining
  self:UpdateTimerDisplay()
end

-- Expects value in seconds
function WarpDeplete:SetTimerCurrent(time)
  if self.timerState.limit - time == self.timerState.remaining then
    return
  end
  if self.timerState.current == time then
    return
  end
  self.timerState.remaining = self.timerState.limit - time
  self.timerState.current = time
  self:UpdateTimerDisplay()
end

-- This is used as a buffer since this function is called from OnUpdate, to avoid allocating
-- new local variables that need to be garbage collected during each call.
local state = {}
function WarpDeplete:UpdateTimerDisplay()
  state.expiredColor = self.db.profile.timerExpiredColor
  state.successColor = self.db.profile.timerSuccessColor

  state.percent = self.timerState.limit > 0 and self.timerState.current / self.timerState.limit or 0

  state.timerText = Util.formatTime_OnUpdate(self.timerState.current) ..
    " / " .. Util.formatTime_OnUpdate(self.timerState.limit)

  if self.challengeState.challengeCompleted and self.timerState.current <= self.timerState.limit then
    state.timerText = "|c" .. state.successColor .. state.timerText .. "|r"
  elseif self.challengeState.challengeCompleted and self.timerState.current > self.timerState.limit then
    state.timerText = "|c" .. state.expiredColor .. state.timerText .. "|r"
  end

  self.frames.root.timerText:SetText(state.timerText)

  for i = 1, 3 do
    state.timeRemaining = self.timerState.limits[i] - self.timerState.current

    state.barValue = Util.getBarPercent_OnUpdate(i, state.percent)
    state.timeText = Util.formatTime_OnUpdate(math.abs(state.timeRemaining))

    if not self.challengeState.challengeCompleted then
      if i == 1 and state.timeRemaining < 0 then
        state.timeText = "|c" .. state.expiredColor .. "-".. state.timeText .. "|r"
      end

      if i ~= 1 and state.timeRemaining < 0 then
        state.timeText = ""
      end
    else
      if state.timeRemaining <= 0 then
        state.color = state.expiredColor
        state.timeText = "-" .. state.timeText
      else
        state.color = state.successColor
      end

      state.timeText = "|c" .. state.color .. state.timeText .. "|r"
    end

    self.bars[i].bar:SetValue(state.barValue)
    self.bars[i].text:SetText(state.timeText)
  end
end

function WarpDeplete:SetForcesTotal(totalCount)
  self.forcesState.totalCount = totalCount
  self.forcesState.pullPercent = totalCount > 0 and self.forcesState.pullCount / totalCount or 0

  local currentPercent = totalCount > 0 and self.forcesState.currentCount / totalCount or 0
  if currentPercent > 1.0 then currentPercent = 1.0 end
  self.forcesState.currentPercent = currentPercent

  self.forcesState.completed = false
  self.forcesState.completedTime = 0
  self:UpdateForcesDisplay()
end

-- Expects direct forces value
function WarpDeplete:SetForcesPull(pullCount)
  self.forcesState.pullCount = pullCount
  self.forcesState.pullPercent = self.forcesState.totalCount > 0
    and pullCount / self.forcesState.totalCount or 0

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

  local currentPercent = self.forcesState.totalCount > 0
    and self.forcesState.currentCount / self.forcesState.totalCount or 0

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
      self.db.profile.completedForcesColor,
      self.db.profile.forcesFormat,
      self.db.profile.customForcesFormat,
      self.db.profile.currentPullFormat,
      self.db.profile.customCurrentPullFormat,
      self.forcesState.pullCount,
      self.forcesState.currentCount,
      self.forcesState.totalCount,
      self.forcesState.completed and self.forcesState.completedTime or nil
    )
  )

  self:UpdatePrideGlow()
end

function WarpDeplete:UpdatePrideGlow()
  if self.keyDetailsState.level < 10 then return end

  if self.challengeState.challengeCompleted then
    if self.forcesState.prideGlowActive then self:HidePrideGlow() end
    return
  end

  local percentBeforePull = self.forcesState.currentPercent
  local currentPrideFraction = (percentBeforePull % 0.2)
  local prideFractionAfterPull = currentPrideFraction + self.forcesState.pullPercent
  local shouldGlow = percentBeforePull < 1.0 and prideFractionAfterPull >= 0.2

  -- Already in the correct state
  if shouldGlow == self.forcesState.prideGlowActive then return end
  self.forcesState.prideGlowActive = shouldGlow

  if shouldGlow then self:ShowPrideGlow()
  else self:HidePrideGlow() end
end

function WarpDeplete:ShowPrideGlow()
  local glowColor = "CB091E"
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
end

function WarpDeplete:HidePrideGlow()
  self.Glow.PixelGlow_Stop(self.forces.bar, "pride")
end

-- Expect death count as number
function WarpDeplete:SetDeaths(count)
  self.timerState.deaths = count
  local deathText = Util.formatDeathText(count)
  self.frames.root.deathsText:SetText(deathText)

  local deathsTooltipFrameWidth = self.frames.root.deathsText:GetStringWidth() + self.db.profile.framePadding
  self.frames.deathsTooltip:SetWidth(deathsTooltipFrameWidth)
end

-- Expects objective list in format {{name: "Boss1", time: nil}, {name: "Boss2", time: 123}}
-- Completion time is nil if not completed, or completion time in seconds from start
function WarpDeplete:SetObjectives(objectives)
  self.objectivesState = objectives
  self:UpdateObjectivesDisplay()
end

function WarpDeplete:UpdateObjectivesDisplay()
  if not self.db.profile.showObjectives then 
    for i, boss in ipairs(self.objectivesState) do
      self.frames.root.objectiveTexts[i]:SetText("")
    end
    return
  end
  local completionColor = self.db.profile.completedObjectivesColor

  -- Clear existing objective list
  for i = 1, 5 do
    self.frames.root.objectiveTexts[i]:SetText("")
  end

  for i, boss in ipairs(self.objectivesState) do
    local objectiveStr = boss.name

    if boss.time ~= nil then
      if boss.time > 0 then
        local completionTimeStr = Util.formatTime(boss.time)
        objectiveStr = "[" .. completionTimeStr .. "] " .. objectiveStr
      end

      objectiveStr = "|c" .. completionColor .. objectiveStr .. "|r"
    end

    self.frames.root.objectiveTexts[i]:SetText(objectiveStr)
  end
end

-- Expects level as number and affixes as string array, e.g. {"Tyrannical", "Bolstering"}
function WarpDeplete:SetKeyDetails(level, affixes)
  self.keyDetailsState.level = level
  self.keyDetailsState.affixes = affixes

  self:UpdateKeyDetailsDisplay()
end

function WarpDeplete:UpdateKeyDetailsDisplay()
  local affixesStr = Util.joinStrings(self.keyDetailsState.affixes or {}, " - ")
  local keyDetails = ("[%d] %s"):format(self.keyDetailsState.level, affixesStr)
  self.frames.root.keyDetailsText:SetText(keyDetails)
end
