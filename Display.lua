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

  -- Key text
  local keyText = self.frames.root:CreateFontString(nil, "ARTWORK")
  self.frames.root.keyText = keyText

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
  local alignRight = self.db.profile.alignTexts == "right"
  local alignBarTextRight = self.db.profile.alignBarTexts == "right"

  local deathsFontSize = self.db.profile.deathsFontSize
  local timerFontSize = self.db.profile.timerFontSize
  local keyFontSize = self.db.profile.keyFontSize
  local keyDetailsFontSize = self.db.profile.keyDetailsFontSize
  local objectivesFontSize = self.db.profile.objectivesFontSize

  local bar1FontSize = self.db.profile.bar1FontSize
  local bar2FontSize = self.db.profile.bar2FontSize
  local bar3FontSize = self.db.profile.bar3FontSize
  local forcesFontSize = self.db.profile.forcesFontSize

  local deathsFont = self.db.profile.deathsFont
  local timerFont = self.db.profile.timerFont
  local keyFont = self.db.profile.keyFont
  local keyDetailsFont = self.db.profile.keyDetailsFont
  local bar1Font = self.db.profile.bar1Font
  local bar2Font = self.db.profile.bar2Font
  local bar3Font = self.db.profile.bar3Font
  local forcesFont = self.db.profile.forcesFont
  local objectivesFont = self.db.profile.objectivesFont

  -- Font flags
  local deathsFontFlags = self.db.profile.deathsFontFlags
  local timerFontFlags = self.db.profile.timerFontFlags
  local keyFontFlags = self.db.profile.keyFontFlags
  local keyDetailsFontFlags = self.db.profile.keyDetailsFontFlags
  local bar1FontFlags = self.db.profile.bar1FontFlags
  local bar2FontFlags = self.db.profile.bar2FontFlags
  local bar3FontFlags = self.db.profile.bar3FontFlags
  local forcesFontFlags = self.db.profile.forcesFontFlags
  local objectivesFontFlags = self.db.profile.objectivesFontFlags

  local timerBarOffsetX = self.db.profile.timerBarOffsetX

  local barFontOffsetX = self.db.profile.barFontOffsetX
  local barFontOffsetY = self.db.profile.barFontOffsetY

  local barWidth = self.db.profile.barWidth
  local barHeight = self.db.profile.barHeight
  local barPadding = self.db.profile.barPadding

  local framePadding = self.db.profile.framePadding
  local barFramePaddingTop = self.db.profile.barFramePaddingTop
  local barFramePaddingBottom = self.db.profile.barFramePaddingBottom

  local verticalOffset = self.db.profile.verticalOffset
  local objectivesOffset = self.db.profile.objectivesOffset

  -- We can only set width here, since height is calculated
  -- dynamically from the elements
  self.frames.root:SetWidth(barWidth + framePadding * 2)
  self.frames.root:SetPoint(
    self.db.profile.frameAnchor,
    self.db.profile.frameX,
    self.db.profile.frameY
  )

  self.frames.root.texture:SetAllPoints(self.frames.root)

  local r, g, b

  local currentOffset = 0 + framePadding

  -- Deaths text
  local deathsText = self.frames.root.deathsText
  deathsText:SetFont(self.LSM:Fetch("font", deathsFont), deathsFontSize, deathsFontFlags)
  deathsText:SetNonSpaceWrap(false)
  deathsText:SetJustifyH(alignRight and "RIGHT" or "LEFT")
  r, g, b = Util.hexToRGB(self.db.profile.deathsColor)
  deathsText:SetTextColor(r, g, b, 1)
  deathsText:SetPoint(
    alignRight and "TOPRIGHT" or "TOPLEFT",
    alignRight and -framePadding - 4 or framePadding + 4,
    -currentOffset
  )

  local deathsTooltipFrameHeight = deathsFontSize + verticalOffset + framePadding
  local deathsTooltipFrameWidth = deathsText:GetStringWidth() + framePadding
  self.frames.deathsTooltip.offsetWidth = deathsTooltipFrameWidth - framePadding
  self.frames.deathsTooltip:SetHeight(deathsTooltipFrameHeight)
  self.frames.deathsTooltip:SetWidth(deathsTooltipFrameWidth)
  self.frames.deathsTooltip:SetPoint(
    alignRight and "TOPRIGHT" or "TOPLEFT",
    alignRight and -framePadding * 0.5 or framePadding * 0.5,
    -framePadding * 0.5
  )

  currentOffset = currentOffset + deathsText:GetStringHeight() + verticalOffset

  -- Timer text
  local timerText = self.frames.root.timerText
  timerText:SetFont(self.LSM:Fetch("font", timerFont), timerFontSize, timerFontFlags)
  timerText:SetNonSpaceWrap(false)
  timerText:SetJustifyH(alignRight and "RIGHT" or "LEFT")
  r, g, b = Util.hexToRGB(self.db.profile.timerRunningColor)
  timerText:SetTextColor(r, g, b, 1)
  timerText:SetPoint(
    alignRight and "TOPRIGHT" or "TOPLEFT",
    alignRight and -framePadding or framePadding,
    -currentOffset
  )

  currentOffset = currentOffset + timerText:GetStringHeight() + verticalOffset

  -- Key details text
  local keyDetailsText = self.frames.root.keyDetailsText
  keyDetailsText:SetFont(self.LSM:Fetch("font", keyDetailsFont), keyDetailsFontSize, keyDetailsFontFlags)
  keyDetailsText:SetNonSpaceWrap(false)
  keyDetailsText:SetJustifyH(alignRight and "RIGHT" or "LEFT")
  r, g, b = Util.hexToRGB(self.db.profile.keyDetailsColor)
  keyDetailsText:SetTextColor(r, g, b, 1)
  
  -- Key level Text
  local keyText = self.frames.root.keyText
  keyText:SetFont(self.LSM:Fetch("font", keyFont), keyFontSize, keyFontFlags)
  keyText:SetNonSpaceWrap(false)
  keyText:SetJustifyH(alignRight and "RIGHT" or "LEFT")
  r, g, b = Util.hexToRGB(self.db.profile.keyColor)
  keyText:SetTextColor(r, g, b, 1)

  -- Reset these because they depend on each other
  keyText:ClearAllPoints()
  keyDetailsText:ClearAllPoints()

  -- Find out which one is bigger, we'll position the other one according to that
  local keyTextHeight = keyText:GetStringHeight()
  local keyDetailsTextHeight = keyDetailsText:GetStringHeight()
  local keyRowHeight = math.max(keyTextHeight, keyDetailsTextHeight)

  -- Basically, whenever we're right aligned we're absolutely positioning the keyDetails,
  -- and when we're left aligned it's the key level. Then the other one is attached
  -- to the left/right.
  -- This makes the vertical centering a bit messy, since we need to get the offset
  -- between the two (larger - smaller) / 2 and then shift the smaller one by that amount
  -- compared to the larger one, which changes depending on alignment.
  -- Note that what the element that was smaller (and thus offset) is the anchor, we need
  -- to subtract the anchor again from the bigger element to cancel it out.
  -- Also, all offsets are negative, as usual.
  if keyTextHeight >= keyDetailsTextHeight then
    local offset = (keyTextHeight - keyDetailsTextHeight) / 2

    if alignRight then
      keyDetailsText:SetPoint("TOPRIGHT", -framePadding - 3, -currentOffset - offset - 1)
      keyText:SetPoint("TOPRIGHT", keyDetailsText, "TOPLEFT", -3, offset)
    else
      keyText:SetPoint("TOPLEFT", framePadding, -currentOffset)
      keyDetailsText:SetPoint("TOPLEFT", keyText, "TOPRIGHT", 3, -offset - 1)
    end
  else
    local offset = (keyDetailsTextHeight - keyTextHeight) / 2

    if alignRight then
      keyDetailsText:SetPoint("TOPRIGHT", -framePadding - 3, -currentOffset - 1)
      keyText:SetPoint("TOPRIGHT", keyDetailsText, "TOPLEFT", -3, -offset)
    else
      keyText:SetPoint("TOPLEFT", framePadding, -currentOffset - offset)
      keyDetailsText:SetPoint("TOPLEFT", keyText, "TOPRIGHT", 3, offset - 1)
    end
  end

  currentOffset = currentOffset + keyRowHeight + verticalOffset + barFramePaddingTop + 1

  -- Bars frame
  self.frames.bars:SetWidth(barWidth)
  self.frames.bars:SetPoint(
    alignRight and "TOPRIGHT" or "TOPLEFT",
    alignRight and -framePadding or framePadding,
    -currentOffset
  )

  self.frames.bars.texture:SetAllPoints()

  -- Bars
  local timerBarPixelAdjust = 0.5
  local r, g, b = Util.hexToRGB(self.db.profile.timerRunningColor)

  -- +3 bar
  local bar3Width = barWidth / 100 * 60
  self.bar3:SetLayout(self.db.profile.bar3Texture, self.db.profile.bar3TextureColor,
    bar3Width, barHeight + timerBarPixelAdjust,
    0, barPadding + barHeight / 2)
  self.bar3.text:SetFont(self.LSM:Fetch("font", bar3Font), bar3FontSize, bar3FontFlags)
  self.bar3.text:SetNonSpaceWrap(false)
  self.bar3.text:SetJustifyH(alignBarTextRight and "RIGHT" or "LEFT")
  self.bar3.text:SetTextColor(r, g, b, 1)
  self.bar3.text:SetPoint(
    alignBarTextRight and "BOTTOMRIGHT" or "BOTTOMLEFT",
    alignBarTextRight and -barFontOffsetX or barFontOffsetX,
    barFontOffsetY
  )

  local bar3Height = math.max(barHeight, self.bar3.text:GetStringHeight() + barFontOffsetY)

  -- +2 bar
  local bar2Width = barWidth / 100 * 20 - timerBarOffsetX
  self.bar2:SetLayout(self.db.profile.bar2Texture, self.db.profile.bar2TextureColor,
    bar2Width, barHeight + timerBarPixelAdjust,
    bar3Width + timerBarOffsetX,
    barPadding + barHeight / 2)
  self.bar2.text:SetFont(self.LSM:Fetch("font", bar2Font), bar2FontSize, bar2FontFlags)
  self.bar2.text:SetNonSpaceWrap(false)
  self.bar2.text:SetJustifyH(alignBarTextRight and "RIGHT" or "LEFT")
  self.bar2.text:SetTextColor(r, g, b, 1)
  self.bar2.text:SetPoint(
    alignBarTextRight and "BOTTOMRIGHT" or "BOTTOMLEFT",
    alignBarTextRight and -barFontOffsetX or barFontOffsetX,
    barFontOffsetY
  )

  local bar2Height = math.max(barHeight, self.bar2.text:GetStringHeight() + barFontOffsetY)

  -- +1 bar
  local bar1Width = barWidth / 100 * 20 - timerBarOffsetX
  self.bar1:SetLayout(self.db.profile.bar1Texture, self.db.profile.bar1TextureColor,
    bar1Width, barHeight + timerBarPixelAdjust,
    bar3Width + bar2Width + timerBarOffsetX * 2,
    barPadding + barHeight / 2)
  self.bar1.text:SetFont(self.LSM:Fetch("font", bar1Font), bar1FontSize, bar1FontFlags)
  self.bar1.text:SetNonSpaceWrap(false)
  self.bar1.text:SetJustifyH(alignBarTextRight and "RIGHT" or "LEFT")
  self.bar1.text:SetTextColor(r, g, b, 1)
  self.bar1.text:SetPoint(
    alignBarTextRight and "BOTTOMRIGHT" or "BOTTOMLEFT",
    alignBarTextRight and -barFontOffsetX or barFontOffsetX,
    barFontOffsetY
  )

  local bar1Height = math.max(barHeight, self.bar1.text:GetStringHeight() + barFontOffsetY)

  local timerBarsHeight = math.max(bar1Height, bar2Height, bar3Height)

  -- Forces bar
  local forcesBarPixelAdjust = 0.5
  local r, g, b = Util.hexToRGB(self.db.profile.forcesColor)
  self.forces:SetLayout(self.db.profile.forcesTexture, self.db.profile.forcesTextureColor,
    barWidth, barHeight + forcesBarPixelAdjust, 0, -barPadding - barHeight / 2)
  self.forces.text:SetFont(self.LSM:Fetch("font", forcesFont), forcesFontSize, forcesFontFlags)
  self.forces.text:SetNonSpaceWrap(false)
  self.forces.text:SetJustifyH(alignBarTextRight and "RIGHT" or "LEFT")
  self.forces.text:SetTextColor(r, g, b, 1)
  self.forces.text:SetPoint(
    alignBarTextRight and "TOPRIGHT" or "TOPLEFT",
    alignBarTextRight and -barFontOffsetX or barFontOffsetX,
    -barFontOffsetY
  )

  local forcesBarHeight = math.max(barHeight, self.forces.text:GetStringHeight() + barFontOffsetY)

  r, g, b = Util.hexToRGB(self.db.profile.forcesOverlayTextureColor)
  self.forces.overlayBar:SetMinMaxValues(0, 1)
  self.forces.overlayBar:SetValue(0)
  self.forces.overlayBar:SetPoint("LEFT", 0, 0)
  self.forces.overlayBar:SetSize(barWidth - 2, barHeight - 2)
  self.forces.overlayBar:SetStatusBarTexture(self.LSM:Fetch("statusbar", self.db.profile.forcesOverlayTexture))
  self.forces.overlayBar:SetStatusBarColor(r, g, b, 0.7)

  local barFrameHeight = timerBarsHeight + forcesBarHeight + barPadding * 2
  self.frames.bars:SetHeight(barFrameHeight)
  currentOffset = currentOffset + barFrameHeight + barFramePaddingBottom + verticalOffset

  -- Objectives
  for i = 1, 5 do
    local objectiveText = self.frames.root.objectiveTexts[i]
    objectiveText:SetFont(self.LSM:Fetch("font", objectivesFont), objectivesFontSize, objectivesFontFlags)
    objectiveText:SetNonSpaceWrap(false)
    objectiveText:SetJustifyH(alignRight and "RIGHT" or "LEFT")
    local r, g, b = Util.hexToRGB(self.db.profile.objectivesColor)
    objectiveText:SetTextColor(r, g, b, 1)
    objectiveText:SetPoint(
      alignRight and "TOPRIGHT" or "TOPLEFT",
      alignRight and -framePadding or framePadding,
      -currentOffset
    )

    currentOffset = currentOffset + objectiveText:GetStringHeight() + objectivesOffset
  end

  currentOffset = currentOffset + framePadding
  self.frames.root:SetHeight(currentOffset)

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

  if self.challengeState.challengeCompleted then
    local blizzardTime = select(3, C_ChallengeMode.GetCompletionInfo())
    local blizzardTimeText = ''
    if self.db.profile.showMillisecondsWhenDungeonCompleted then
      blizzardTimeText = Util.formatTimeMilliseconds(blizzardTime)
    else
      blizzardTimeText = Util.formatTime(blizzardTime/1000)
    end

    if self.timerState.current <= self.timerState.limit then
      state.timerText =  blizzardTimeText ..
              " / " .. Util.formatTime_OnUpdate(self.timerState.limit)
      state.timerText = "|c" .. state.successColor .. state.timerText .. "|r"
    elseif self.timerState.current > self.timerState.limit then
      state.timerText =  blizzardTimeText ..
              " / " .. Util.formatTime_OnUpdate(self.timerState.limit)
      state.timerText = "|c" .. state.expiredColor .. state.timerText .. "|r"
    end
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

-- Expects direct forces value
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
function WarpDeplete:SetForcesCurrent(currentCount)
  -- The current count can only ever go up. The only place where it should
  -- ever decrease is when it's reset in ResetState.
  -- It seems that the API reports a current count of 0 when the dungeon is
  -- finished, but possibly right before the challengeCompleted flag is triggered.
  -- So, to make sure we don't reset the bar to 0 in that case, we only allow
  -- the count to go up here.
  if currentCount >= self.forcesState.currentCount then
    self.forcesState.currentCount = currentCount
  end

  local currentPercent = self.forcesState.totalCount > 0
    and self.forcesState.currentCount / self.forcesState.totalCount or 0

  if currentPercent > 1.0 then currentPercent = 1.0 end
  self.forcesState.currentPercent = currentPercent

  self:UpdateForcesDisplay()
end

function WarpDeplete:SetForcesCompletionTime(completionTime)
  self:PrintDebug("Setting forces completion time")
  self.forcesState.completed = true
  self.forcesState.completedTime = completionTime

  -- Make sure we always show max forces/100% on completion
  if self.challengeState.challengeCompleted then
    self.forcesState.currentPercent = 1.0

    if self.forcesState.currentCount < self.forcesState.totalCount then
      self.forcesState.currentCount = self.forcesState.totalCount
    end
  end

  self:UpdateTimings()
  self:UpdateForcesDisplay()
end

-- Expects direct forces value
function WarpDeplete:SetForcesPull(pullCount)
  self.forcesState.pullCount = pullCount
  self.forcesState.pullPercent = self.forcesState.totalCount > 0
    and pullCount / self.forcesState.totalCount or 0

  self:UpdateForcesDisplay()
end

function WarpDeplete:UpdateForcesDisplay()
  if self.forcesState.currentPercent < 1.0 then
    -- clamp pull progress so that the bar won't exceed 100%
    local pullPercent = self.forcesState.pullPercent
    if self.forcesState.pullPercent + self.forcesState.currentPercent > 1.0 then
      pullPercent = 1 - self.forcesState.currentPercent
    end

    self.forces.overlayBar:SetValue(pullPercent - 0.005)
  else
    self.forces.overlayBar:SetValue(0)
  end

  self.forces.overlayBar:SetPoint("LEFT", 1 + self.db.profile.barWidth * self.forcesState.currentPercent, 0)

  self.forces.bar:SetValue(self.forcesState.currentPercent)

  self.forces.text:SetText(
    Util.formatForcesText(
      self.db.profile.completedForcesColor,
      self.db.profile.forcesFormat,
      self.db.profile.customForcesFormat,
      self.db.profile.unclampForcesPercent,
      self.db.profile.currentPullFormat,
      self.db.profile.customCurrentPullFormat,
      self.forcesState.pullCount,
      self.forcesState.currentCount,
      self.forcesState.totalCount,
      self.forcesState.completed and self.forcesState.completedTime or nil,
      self.db.profile.timingsEnabled,
      self:GetCurrentDiff("forces"),
      self.db.profile.timingsImprovedTimeColor,
      self.db.profile.timingsWorseTimeColor,
      self.db.profile.alignBarTexts
    )
  )
  self:UpdateGlow()
end

function WarpDeplete:UpdateGlowAppearance()
  if not self.forcesState.glowActive then return end

  -- LibCustomGlow doesn't let us change the glow properties
  -- once it's running, so this is the easiest way. Pretty sure
  -- everybody does this.
  self:HideGlow()
  self:ShowGlow()
end

function WarpDeplete:UpdateGlow()
  if self.forcesState.glowActive and (
    self.challengeState.challengeCompleted or
    self.forcesState.completed
  ) then
    self:HideGlow()
    return
  end

  local percentBeforePull = self.forcesState.currentPercent
  local percentAfterPull = percentBeforePull + self.forcesState.pullPercent
  local shouldGlow = percentBeforePull < 1 and percentAfterPull >= 1.0

  -- Already in the correct state
  if shouldGlow == self.forcesState.glowActive then return end

  if shouldGlow then self:ShowGlow()
  else self:HideGlow() end
end

function WarpDeplete:ShowGlow()
  self.forcesState.glowActive = true
  local glowR, glowG, glowB = Util.hexToRGB(self.db.profile.forcesGlowColor)
  self.Glow.PixelGlow_Start(
    self.forces.bar, -- frame
    {glowR, glowG, glowB, 1}, -- color
    self.db.profile.forcesGlowLineCount, -- line count
    self.db.profile.forcesGlowFrequency, -- frequency
    self.db.profile.forcesGlowLength, -- length
    self.db.profile.forcesGlowThickness, -- thiccness
    1.5, -- x offset
    1.5, -- y offset
    false, -- draw border
    "forcesComplete", -- tag
    0 -- draw layer
  )
end

function WarpDeplete:HideGlow()
  self.forcesState.glowActive = false
  self.Glow.PixelGlow_Stop(self.forces.bar, "forcesComplete")
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
  local completionColor = self.db.profile.completedObjectivesColor
  local alignStart = self.db.profile.alignBossClear == "start"

  -- Clear existing objective list
  for i = 1, 5 do
    self.frames.root.objectiveTexts[i]:SetText("")
  end

  local timings = self:GetTimingsForCurrentInstance()

  for i, boss in ipairs(self.objectivesState) do
    local objectiveStr = boss.name

    if boss.time ~= nil then
      objectiveStr = Util.colorText(boss.name, completionColor)
    end

    if boss.time ~= nil and boss.time > 0 then
      local completionTimeStr = "[" .. Util.formatTime(boss.time) .. "]"
      completionTimeStr = Util.colorText(completionTimeStr, completionColor)

      if alignStart then
        objectiveStr = completionTimeStr .. " " .. objectiveStr
      else
        objectiveStr = objectiveStr .. " " .. completionTimeStr
      end

      if self.db.profile.timingsEnabled then
        local diff = self:GetCurrentDiff(i)

        if diff ~= nil then
          local diffColor = diff <= 0 and
            self.db.profile.timingsImprovedTimeColor or
            self.db.profile.timingsWorseTimeColor

          diffStr = "|c" .. diffColor ..  Util.formatTime(diff, true) .. "|r"

          if alignStart then
            objectiveStr = diffStr .. " " .. objectiveStr
          else
            objectiveStr = objectiveStr .. " " .. diffStr
          end
        end
      end
    end

    -- TODO allow users to provide a custom format string for the objectiveStr
    self.frames.root.objectiveTexts[i]:SetText(objectiveStr)
  end
end

-- Expects level as number and affixes as string array, e.g. {"Tyrannical", "Bolstering"}
function WarpDeplete:SetKeyDetails(level, deathPenalty, affixes, affixIds, mapId)
  self.keyDetailsState.level = level
  self.keyDetailsState.deathPenalty = deathPenalty
  self.keyDetailsState.affixes = affixes
  self.keyDetailsState.affixIds = affixIds
  self.keyDetailsState.mapId = mapId

  self:UpdateKeyDetailsDisplay()
end

function WarpDeplete:UpdateKeyDetailsDisplay()
  local key = ("[%d]"):format(self.keyDetailsState.level)
  self.frames.root.keyText:SetText(key)

  local affixesStr = Util.joinStrings(self.keyDetailsState.affixes or {}, " - ")
  local keyDetails = ("%s"):format(affixesStr)
  self.frames.root.keyDetailsText:SetText(keyDetails)
end
