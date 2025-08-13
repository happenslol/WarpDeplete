local Util = WarpDeplete.Util

function WarpDeplete:InitRender()
	local frameBackgroundAlpha = 0

	self.frames.root.texture = self.frames.root:CreateTexture(nil, "BACKGROUND")
	self.frames.root.texture:SetColorTexture(0, 0, 0, frameBackgroundAlpha)

	-- Deaths text
	self.frames.root.deathsText = self.frames.root:CreateFontString(nil, "ARTWORK")

	-- Timer text
	self.frames.root.timerText = self.frames.root:CreateFontString(nil, "ARTWORK")

	-- Timer PB text
	self.frames.root.timerSplitText = self.frames.root:CreateFontString(nil, "ARTWORK")

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

	self.bars = { self.bar1, self.bar2, self.bar3 }

	-- Forces bar
	local forces = self:CreateProgressBar(self.frames.bars)
	local forcesText = forces.bar:CreateFontString(nil, "ARTWORK")
	forces.text = forcesText

	local forcesOverlayBar = CreateFrame("StatusBar", nil, forces.frame)
	forces.overlayBar = forcesOverlayBar
	self.forces = forces

	-- Objectives
	local objectiveTexts = {}

	for i = 1, 10 do
		local objectiveText = self.frames.root:CreateFontString(nil, "ARTWORK")
		objectiveTexts[i] = objectiveText
	end

	self.frames.root.objectiveTexts = objectiveTexts

	self:RenderLayout()

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

---@return number bar1 The fraction that the +1 bar should take up
---@return number bar2 The fraction that the +2 bar should take up
---@return number bar3 The fraction that the +3 bar should take up
function WarpDeplete:GetTimerBarFractions()
	if not self.state.hasChallengersPeril then
		return 0.2, 0.2, 0.6
	end

	local fractions = {}
	for i = 1, 3 do
		local timeLimit = self.state.timeLimits[i] or 0
		local barMax = timeLimit - (self.state.timeLimits[i + 1] or 0)
		fractions[i] = barMax / self.state.timeLimit
	end

	return fractions[1], fractions[2], fractions[3]
end

function WarpDeplete:CreateProgressBar(frame)
	local result = {}

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
			insets = { top = 1, right = 1, bottom = 1, left = 1 },
		})
		barFrame:SetBackdropColor(0, 0, 0, 0.5)
		barFrame:SetBackdropBorderColor(0, 0, 0, 1)

		bar:SetPoint("CENTER", 0, 0)
		bar:SetSize(width - 2, height - 2)

		bar:SetStatusBarTexture(WarpDeplete.LSM:Fetch("statusbar", barTexture)--[[@as string]])
		bar:SetStatusBarColor(r, g, b)
	end

	return result
end

function WarpDeplete:RenderLayout()
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
	self.frames.root:SetPoint(self.db.profile.frameAnchor, self.db.profile.frameX, self.db.profile.frameY)
	self.frames.root:SetScale(self.db.profile.frameScale)

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
	timerText:ClearAllPoints()
	timerText:SetPoint(
		alignRight and "TOPRIGHT" or "TOPLEFT",
		alignRight and -framePadding or framePadding,
		-currentOffset
	)

	-- Timer splits text
	local timerSplitText = self.frames.root.timerSplitText
	timerSplitText:SetFont(self.LSM:Fetch("font", timerFont), timerFontSize * 0.6, timerFontFlags)
	timerSplitText:SetNonSpaceWrap(false)
	timerSplitText:SetJustifyH(alignRight and "RIGHT" or "LEFT")
	timerSplitText:ClearAllPoints()
	timerSplitText:SetPoint(
		alignRight and "BOTTOMRIGHT" or "BOTTOMLEFT",
		self.frames.root.timerText,
		alignRight and "BOTTOMLEFT" or "BOTTOMRIGHT",
		alignRight and -8 or 8,
		2
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
	r, g, b = Util.hexToRGB(self.db.profile.timerRunningColor)

	local bar1Fraction, bar2Fraction, bar3Fraction = self:GetTimerBarFractions()

	-- +3 bar
	local bar3Width = barWidth * bar3Fraction
	self.bar3:SetLayout(
		self.db.profile.bar3Texture,
		self.db.profile.bar3TextureColor,
		bar3Width,
		barHeight + timerBarPixelAdjust,
		0,
		barPadding + barHeight / 2
	)
	self.bar3.text:SetFont(self.LSM:Fetch("font", bar3Font)--[[@as string]], bar3FontSize, bar3FontFlags)
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
	local bar2Width = barWidth * bar2Fraction - timerBarOffsetX
	self.bar2:SetLayout(
		self.db.profile.bar2Texture,
		self.db.profile.bar2TextureColor,
		bar2Width,
		barHeight + timerBarPixelAdjust,
		bar3Width + timerBarOffsetX,
		barPadding + barHeight / 2
	)
	self.bar2.text:SetFont(self.LSM:Fetch("font", bar2Font)--[[@as string]], bar2FontSize, bar2FontFlags)
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
	local bar1Width = barWidth * bar1Fraction - timerBarOffsetX
	self.bar1:SetLayout(
		self.db.profile.bar1Texture,
		self.db.profile.bar1TextureColor,
		bar1Width,
		barHeight + timerBarPixelAdjust,
		bar3Width + bar2Width + timerBarOffsetX * 2,
		barPadding + barHeight / 2
	)
	self.bar1.text:SetFont(self.LSM:Fetch("font", bar1Font)--[[@as string]], bar1FontSize, bar1FontFlags)
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
	r, g, b = Util.hexToRGB(self.db.profile.forcesColor)
	self.forces:SetLayout(
		self.db.profile.forcesTexture,
		self.db.profile.forcesTextureColor,
		barWidth,
		barHeight + forcesBarPixelAdjust,
		0,
		-barPadding - barHeight / 2
	)
	self.forces.text:SetFont(self.LSM:Fetch("font", forcesFont)--[[@as string]], forcesFontSize, forcesFontFlags)
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
	self.forces.overlayBar:SetStatusBarTexture(
		self.LSM:Fetch("statusbar", self.db.profile.forcesOverlayTexture) --[[@as string]]
	)
	self.forces.overlayBar:SetStatusBarColor(r, g, b, 0.7)

	local barFrameHeight = timerBarsHeight + forcesBarHeight + barPadding * 2
	self.frames.bars:SetHeight(barFrameHeight)
	currentOffset = currentOffset + barFrameHeight + barFramePaddingBottom + verticalOffset

	-- Objectives
	for i = 1, 10 do
		local objectiveText = self.frames.root.objectiveTexts[i]
		objectiveText:SetFont(self.LSM:Fetch("font", objectivesFont), objectivesFontSize, objectivesFontFlags)
		objectiveText:SetNonSpaceWrap(false)
		objectiveText:SetJustifyH(alignRight and "RIGHT" or "LEFT")
		r, g, b = Util.hexToRGB(self.db.profile.objectivesColor)
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

	-- Render things that set text color through font tags
	self:RenderTimer()
	self:RenderForces()
	self:RenderObjectives()
end

-- This is used as a buffer since this function is called from OnUpdate, to avoid allocating
-- new local variables that need to be garbage collected during each call.
local timerState = {}

function WarpDeplete:RenderTimer()
	wipe(timerState)

	-- Make sure we don't divide by 0
	timerState.percent = self.state.timeLimit > 0 and self.state.timer / self.state.timeLimit or 1

	timerState.timerText = Util.formatTime_OnUpdate(self.state.timer)
		.. " / "
		.. Util.formatTime_OnUpdate(self.state.timeLimit)

	if self.state.challengeCompleted then
		local timerText = ""
		if self.db.profile.showMillisecondsWhenDungeonCompleted then
			timerText = Util.formatTimeMilliseconds(self.state.completionTimeMs)
		else
			timerText = Util.formatTime(self.state.completionTimeMs / 1000)
		end

		timerState.timerText = timerText .. " / " .. Util.formatTime_OnUpdate(self.state.timeLimit)
		timerState.color = self.state.completedOnTime and self.db.profile.timerSuccessColor
			or self.db.profile.timerExpiredColor
		timerState.timerText = "|c" .. timerState.color .. timerState.timerText .. "|r"
	end

	self.frames.root.timerText:SetText(timerState.timerText)

	for i = 1, 3 do
		timerState.barLimit = self.state.timeLimits[i] or 1
		timerState.timeRemaining = timerState.barLimit - self.state.timer

		-- This is the timespan that the current bar represents
		timerState.barMax = timerState.barLimit - (self.state.timeLimits[i + 1] or 0)
		-- This is how far we have progressed into that timespan
		timerState.barElapsed = timerState.barMax - timerState.timeRemaining

		timerState.barValue = Util.clamp(timerState.barElapsed / timerState.barMax, 0.0, 1.0)
		timerState.timeText = Util.formatTime_OnUpdate(math.abs(timerState.timeRemaining))

		if not self.state.challengeCompleted then
			if i == 1 and timerState.timeRemaining < 0 then
				timerState.timeText = "|c" .. self.db.profile.timerExpiredColor .. "-" .. timerState.timeText .. "|r"
			end

			if i ~= 1 and timerState.timeRemaining < 0 then
				timerState.timeText = ""
			end
		else
			if timerState.timeRemaining <= 0 then
				timerState.color = self.db.profile.timerExpiredColor
				timerState.timeText = "-" .. timerState.timeText
			else
				timerState.color = self.db.profile.timerSuccessColor
			end
			timerState.timeText = "|c" .. timerState.color .. timerState.timeText .. "|r"
		end

		self.bars[i].bar:SetValue(timerState.barValue)
		self.bars[i].text:SetText(timerState.timeText)
	end

	self.frames.root.timerSplitText:SetText("")
	if self.db.profile.splitsEnabled then
		-- Show PBs during countdown
		if self.db.profile.showPbsDuringCountdown and not self.state.timerStarted then
			local best = self:GetBestSplit("challenge")

			if best then
				self.frames.root.timerSplitText:SetText("|c"
					.. self.db.profile.splitFasterTimeColor
					.. Util.formatTime(best / 1000)
					.. "|r"
				)
			end
		end

		-- The timer loop isn't running at this point, so we use locals
		if self.state.challengeCompleted or self.state.demoModeActive then
			local diff = self:GetCurrentDiff("challenge")
			if diff then
				local diffColor = diff <= 0 and self.db.profile.splitFasterTimeColor
					or self.db.profile.splitSlowerTimeColor
				local diffStr = "|c" .. diffColor .. Util.formatTime(diff / 1000, true) .. "|r"
				self.frames.root.timerSplitText:SetText(diffStr)
			end
		end
	end
end

function WarpDeplete:RenderForces()
	if self.state.currentPercent < 1.0 then
		-- clamp pull progress so that the bar won't exceed 100%
		local pullPercent = self.state.pullPercent
		if self.state.pullPercent + self.state.currentPercent > 1.0 then
			pullPercent = 1 - self.state.currentPercent
		end

		self.forces.overlayBar:SetValue(pullPercent - 0.005)
	else
		self.forces.overlayBar:SetValue(0)
	end

	self.forces.overlayBar:SetPoint("LEFT", 1 + self.db.profile.barWidth * self.state.currentPercent, 0)
	self.forces.bar:SetValue(self.state.currentPercent)

	self.forces.text:SetText(self:FormatForcesText())

	-- Update glow state
	if self.state.pullGlowActive and (self.state.challengeCompleted or self.state.forcesCompleted) then
		self:HideGlow()
	else
		local percentBeforePull = self.state.currentPercent
		local percentAfterPull = percentBeforePull + self.state.pullPercent
		local shouldGlow = percentBeforePull < 1 and percentAfterPull >= 1.0

		if shouldGlow ~= self.state.pullGlowActive then
			if shouldGlow then
				self:ShowGlow()
			else
				self:HideGlow()
			end
		end
	end
end

function WarpDeplete:ShowGlow()
	self.state.pullGlowActive = true
	local glowR, glowG, glowB = Util.hexToRGB(self.db.profile.forcesGlowColor)
	self.Glow.PixelGlow_Start(
		self.forces.bar, -- frame
		{ glowR, glowG, glowB, 1 }, -- color
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
	self.state.pullGlowActive = false
	self.Glow.PixelGlow_Stop(self.forces.bar, "forcesComplete")
end

function WarpDeplete:RenderObjectives()
	local completionColor = self.db.profile.completedObjectivesColor
	local alignStart = self.db.profile.alignBossClear == "start"

	-- Clear existing objective list
	for i = 1, 10 do
		self.frames.root.objectiveTexts[i]:SetText("")
	end

	for i, boss in ipairs(self.state.objectives) do
		local objectiveStr = boss.name

		if boss.time then
			objectiveStr = Util.colorText(objectiveStr, completionColor)
			local completionTimeStr = "[" .. Util.formatTime(boss.time) .. "]"
			completionTimeStr = Util.colorText(completionTimeStr, completionColor)

			if alignStart then
				objectiveStr = completionTimeStr .. " " .. objectiveStr
			else
				objectiveStr = objectiveStr .. " " .. completionTimeStr
			end

			if self.db.profile.splitsEnabled then
				local diff = self:GetCurrentDiff(i)

				if diff then
					local diffColor = diff <= 0 and self.db.profile.splitFasterTimeColor
						or self.db.profile.splitSlowerTimeColor

					local diffStr = "|c" .. diffColor .. Util.formatTime(diff, true) .. "|r"

					if alignStart then
						objectiveStr = diffStr .. " " .. objectiveStr
					else
						objectiveStr = objectiveStr .. " " .. diffStr
					end
				end
			end
		elseif self.db.profile.splitsEnabled and self.db.profile.showPbsDuringCountdown and not self.state.timerStarted then
			local best = self:GetBestSplit(i)
			if best then
				local bestStr = "|c" .. self.db.profile.splitFasterTimeColor .. Util.formatTime(best) .. "|r"

				if alignStart then
					objectiveStr = bestStr .. " " .. objectiveStr
				else
					objectiveStr = objectiveStr .. " " .. bestStr
				end
			end
		end

		self.frames.root.objectiveTexts[i]:SetText(objectiveStr)
	end
end

function WarpDeplete:RenderKeyDetails()
	local key = ("[%d]"):format(self.state.level)
	self.frames.root.keyText:SetText(key)

	local affixesStr = Util.joinStrings(self.state.affixes or {}, " - ")
	local keyDetails = ("%s"):format(affixesStr)
	self.frames.root.keyDetailsText:SetText(keyDetails)
end

function WarpDeplete:FormatForcesText()
	local completedColor = self.db.profile.completedForcesColor
	local forcesFormat = self.db.profile.forcesFormat
	local customForcesFormat = self.db.profile.customForcesFormat
	local currentPullFormat = self.db.profile.currentPullFormat
	local customCurrentPullFormat = self.db.profile.customCurrentPullFormat
	local pullCount = self.state.pullCount
	local currentCount = self.state.currentCount
	local totalCount = self.state.totalCount
	local completionTime = self.state.forcesCompleted and self.state.forcesCompletionTime or nil
	local splitsEnabled = self.db.profile.splitsEnabled
	local diff = self:GetCurrentDiff("forces")
	local splitFasterTimeColor = self.db.profile.splitFasterTimeColor
	local splitSlowerTimeColor = self.db.profile.splitSlowerTimeColor
	local align = self.db.profile.alignBarTexts

	local best = self:GetBestSplit("forces")
	local isStart = not self.state.timerStarted
	local showPbsDuringCountdown = self.db.profile.showPbsDuringCountdown

	local currentPercent = Util.calcForcesPercent((currentCount / totalCount) * 100)

	local percentText = ("%.2f"):format(currentPercent)
	local countText = ("%d"):format(currentCount)
	local totalCountText = ("%d"):format(totalCount)
	local remainingCountText = ("%d"):format(totalCount - currentCount)
	local remainingPercentText = ("%.2f"):format(100 - currentPercent)
	local result = forcesFormat == ":custom:" and customForcesFormat or forcesFormat

	result = result:gsub(":count:", countText)
	result = result:gsub(":percent:", percentText .. "%%")
	result = result:gsub(":totalcount:", totalCountText)
	result = result:gsub(":remainingcount:", remainingCountText)
	result = result:gsub(":remainingpercent:", remainingPercentText .. "%%")

	if pullCount > 0 then
		local pullText = currentPullFormat == ":custom:" and customCurrentPullFormat or currentPullFormat

		local pullPercent = (pullCount / totalCount) * 100
		local pullPercentText = ("%.2f"):format(pullPercent)
		local pullCountText = ("%d"):format(pullCount)

		local countAfterPull = currentCount + pullCount
		local countAfterPullText = ("%d"):format(countAfterPull)

		local remainingCountAfterPull = totalCount - countAfterPull
		if remainingCountAfterPull < 0 then
			remainingCountAfterPull = 0
		end
		local remainingCountAfterPullText = ("%d"):format(remainingCountAfterPull)

		local remainingPercentAfterPull = 100 - currentPercent - pullPercent
		if remainingPercentAfterPull < 0 then
			remainingPercentAfterPull = 0
		end
		local remainingPercentAfterPullText = ("%.2f"):format(remainingPercentAfterPull)

		local percentAfterPull = Util.calcForcesPercent(pullPercent + currentPercent)
		local pulledPercentText = ("%.2f"):format(percentAfterPull)

		pullText = pullText:gsub(":count:", pullCountText)
		pullText = pullText:gsub(":percent:", pullPercentText .. "%%")

		pullText = pullText:gsub(":countafterpull:", countAfterPullText)
		pullText = pullText:gsub(":remainingcountafterpull:", remainingCountAfterPullText)
		pullText = pullText:gsub(":percentafterpull:", pulledPercentText .. "%%")
		pullText = pullText:gsub(":remainingpercentafterpull:", remainingPercentAfterPullText .. "%%")

		result = result:gsub(":countafterpull:", countAfterPullText)
		result = result:gsub(":remainingcountafterpull:", remainingCountAfterPullText)
		result = result:gsub(":percentafterpull:", pulledPercentText .. "%%")
		result = result:gsub(":remainingpercentafterpull:", remainingPercentAfterPullText .. "%%")

		if pullText and #pullText > 0 then
			result = pullText .. "  " .. result
		end
	else
		result = result:gsub(":countafterpull:", countText)
		result = result:gsub(":remainingcountafterpull:", remainingCountText)
		result = result:gsub(":percentafterpull:", percentText .. "%%")
		result = result:gsub(":remainingpercentafterpull:", remainingPercentText .. "%%")
	end

	if completionTime then
		local completedText = ("[%s]"):format(Util.formatTime(completionTime))
		if align == "right" then
			result = "|c" .. completedColor .. completedText .. " " .. result .. "|r"
		else
			result = "|c" .. completedColor .. result .. " " .. completedText .. "|r"
		end

		if splitsEnabled and diff then
			local diffColor = diff <= 0 and splitFasterTimeColor or splitSlowerTimeColor
			local diffStr = "|c" .. diffColor .. Util.formatTime(diff, true) .. "|r"

			if align == "right" then
				result = diffStr .. " " .. result
			else
				result = result .. " " .. diffStr
			end
		end
	elseif splitsEnabled and isStart and showPbsDuringCountdown and best then
		local bestStr = "|c" .. splitFasterTimeColor .. Util.formatTime(best) .. "|r"
		if align == "right" then
			result = bestStr .. " " .. result
		else
			result = result .. " " .. bestStr
		end
	end

	return result or ""
end