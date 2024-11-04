local Util = WarpDeplete.Util

---@class WarpDepleteObjective
---@field name string
---@field time integer|nil

---@class WarpDepleteState
WarpDeplete.defaultState = {
	isShown = false,
	demoModeActive = false,

	inChallenge = false,
	challengeCompleted = false,

	completedOnTime = nil, ---@type boolean|nil
	completionTimeMs = nil, ---@type integer|nil

	timerLoopRunning = false,
	timerStarted = false,
	timer = 0,
	timeLimit = 0,

	deathCount = 0,
	deathDetails = {},

	pullCount = 0,
	currentCount = 0,
	totalCount = 100,

	pullPercent = 0,
	currentPercent = 0,
	pullGlowActive = false,
	currentPull = {}, ---@type table<integer, string|nil|"DEAD">

	objectives = {}, ---@type WarpDepleteObjective[]
	objectiveNames = {}, ---@type string[]

	forcesCompleted = false,
	forcesCompletionTime = nil,

	level = 0,
	deathPenalty = 0,
	affixes = {}, ---@type string[]
	affixIds = {}, ---@type integer[]
	mapId = nil, ---@type integer|nil
}

-- Expects absolute forces value
function WarpDeplete:SetForcesTotal(totalCount)
	self.state.totalCount = totalCount
	self.state.pullPercent = totalCount > 0 and self.state.pullCount / totalCount or 0

	local currentPercent = totalCount > 0 and self.state.currentCount / totalCount or 0
	self.state.currentPercent = math.min(currentPercent, 1.0)

	self:RenderForces()
end

-- Expects absolute forces value
function WarpDeplete:SetForcesCurrent(currentCount)
	-- The current count can only ever go up. The only place where it should
	-- ever decrease is when it's reset in ResetState (or in demo mode).
	-- It seems that the API reports a current count of 0 when the dungeon is
	-- finished, but possibly right before the challengeCompleted flag is triggered.
	-- So, to make sure we don't reset the bar to 0 in that case, we only allow
	-- the count to go up here.
	if currentCount >= self.state.currentCount or self.state.demoModeActive then
		self.state.currentCount = currentCount
	end

	local currentPercent = self.state.totalCount > 0 and self.state.currentCount / self.state.totalCount or 0

	if currentPercent > 1.0 then
		currentPercent = 1.0
	end
	self.state.currentPercent = currentPercent

	self:RenderForces()
end

-- Expects absolute forces value
function WarpDeplete:SetForcesPull(pullCount)
	self.state.pullCount = pullCount
	self.state.pullPercent = self.state.totalCount > 0 and pullCount / self.state.totalCount or 0

	self:RenderForces()
end

function WarpDeplete:SetDeathCount(count)
	self.state.deathCount = count
	local deathText = Util.formatDeathText(count)
	self.frames.root.deathsText:SetText(deathText)

	local deathsTooltipFrameWidth = self.frames.root.deathsText:GetStringWidth() + self.db.profile.framePadding
	self.frames.deathsTooltip:SetWidth(deathsTooltipFrameWidth)
end

function WarpDeplete:SetTimer(timer)
	self.state.timer = timer
	self:RenderTimer()
end

function WarpDeplete:SetTimeLimit(timeLimit)
	self.state.timeLimit = timeLimit
	self:RenderTimer()
end

function WarpDeplete:SetKeyDetails(level, deathPenalty, affixes, affixIds, mapId)
	self.state.level = level
	self.state.deathPenalty = deathPenalty
	self.state.affixes = affixes
	self.state.affixIds = affixIds
	self.state.mapId = mapId

	self:RenderKeyDetails()
end

function WarpDeplete:LoadDeathCount()
	self:SetDeathCount(C_ChallengeMode.GetDeathCount() or 0)
end

function WarpDeplete:LoadKeyDetails()
	local mapId = C_ChallengeMode.GetActiveChallengeMapID()
	if not mapId then
		return
	end

	local timeLimit = select(3, C_ChallengeMode.GetMapUIInfo(mapId))
	self:SetTimeLimit(timeLimit)

	local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()

	if level <= 0 or #affixes <= 0 then
		return
	end

	local affixNames = {}
	local affixIds = {}
	local deathPenalty = 5
	for i, affixID in ipairs(affixes) do
		local name = C_ChallengeMode.GetAffixInfo(affixID)
		affixNames[i] = Util.formatAffixName(name)
		affixIds[i] = affixID
		if affixID == 152 then
			deathPenalty = 15
		end
	end

	self:SetKeyDetails(level or 0, deathPenalty, affixNames, affixIds, mapId)
end

function WarpDeplete:LoadEJBossNames()
	self:PrintDebug("Loading EJ boss names")
	local instanceID = Util.getEJInstanceID()
	if not instanceID then
		self:PrintDebug("No EJ instance ID found")
		return
	end

	-- The encounter journal needs to be opened once
	-- before we can get anything from it
	if not self.encounterJournalOpened then
		self:PrintDebug("Opening encounter journal")
		C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
		EncounterJournal_OpenJournal(8, instanceID)
		self.encounterJournalOpened = true
		HideUIPanel(EncounterJournal)
	else
		self:PrintDebug("Encounter journal already open")
	end

	local result = {}

	-- There are never more than 20 objectives
	-- (probably way less, but let's be safe here)
	for i = 1, 20 do
		local name = EJ_GetEncounterInfoByIndex(i, instanceID)

		if name then
			result[#result + 1] = name
		end
	end

	for i, bossName in ipairs(result) do
		self:PrintDebug("Found boss name " .. tostring(i) .. ": " .. tostring(bossName))
	end
	self.state.objectiveNames = result
end

function WarpDeplete:ResetCurrentPull()
	for k, _ in pairs(self.state.currentPull) do
		self.state.currentPull[k] = nil
	end

	self:SetForcesPull(0)
end

function WarpDeplete:AddDeathDetails(time, name, class)
	self.state.deathDetails[#self.state.deathDetails + 1] = {
		time = time,
		name = name,
		class = class,
	}
end

---@param count integer
function WarpDeplete:RefreshObjectiveNames(count)
	local nameFound = false

	self:LoadEJBossNames()
	for _, boss in pairs(self.state.objectives) do
		for _, objName in ipairs(self.state.objectiveNames) do
			if string.find(boss.name, objName) then
				boss.name = objName
				nameFound = true
				break
			end
		end
	end

	if not nameFound then
		self:PrintDebug("No names found on try " .. tostring(count))
		if count <= 5 then
			C_Timer.After(2, function()
				self:RefreshObjectiveNames(count + 1)
			end)
		end
	end
end

function WarpDeplete:UpdateObjectives()
	local stepCount = select(3, C_Scenario.GetStepInfo())
	if not stepCount or stepCount <= 0 then
		return
	end

	local completionChanged = false
	local bossesLoaded = false
	local ejBossNameFound = false

	for i = 1, stepCount do
		local info = C_ScenarioInfo.GetCriteriaInfo(i)
		if not info.isWeightedProgress then
			if not self.state.objectives[i] then
				local name = info.description
				for _, objName in ipairs(self.state.objectiveNames) do
					if string.find(info.description, objName) then
						name = objName
						ejBossNameFound = true
						break
					end
				end

				name = Util.utf8Sub(name, 40)
				self.state.objectives[i] = { name = name, time = nil }
				bossesLoaded = true
			end

			local objective = self.state.objectives[i]
			if not objective.time and info.completed then
				local time = select(2, GetWorldElapsedTime(1)) - (info.elapsed or 0)
				objective.time = time
				completionChanged = true
			end
		elseif info.isWeightedProgress and info.totalQuantity and info.totalQuantity > 0 then
			-- NOTE: The current count contains a percentage sign
			-- even though it's an absolute value.
			local currentCount = info.quantityString and tonumber(info.quantityString:match("%d+")) or 0

			if currentCount ~= self.state.currentCount then
				self:SetForcesCurrent(currentCount)
			end

			if info.totalQuantity ~= self.state.totalCount then
				self:SetForcesTotal(info.totalQuantity)
			end

			if currentCount >= info.totalQuantity then
				if not self.state.forcesCompleted then
					self:PrintDebug("Setting forces to completed")
					self.state.forcesCompleted = true
					self:RenderForces()
				end

				if not self.state.forcesCompletionTime then
					self:PrintDebug("Setting forces completion time")
					self.state.forcesCompletionTime = select(2, GetWorldElapsedTime(1)) - (info.elapsed or 0)
					completionChanged = true
				end
			end
		end
	end

	if bossesLoaded then
		self:RenderObjectives()
		self:RenderLayout()
	end

	if completionChanged then
		self:UpdateSplits()
		self:RenderForces()
		self:RenderObjectives()
	end

	if bossesLoaded then
		if not ejBossNameFound then
			self:PrintDebug("No boss names found, starting retry loop")
			C_Timer.After(2, function()
				self:RefreshObjectiveNames(1)
			end)
		else
			self:PrintDebug("Boss names found")
		end
	end
end

function WarpDeplete:CompleteChallenge()
	self:StopTimerLoop()
	self:ResetCurrentPull()

	self.state.challengeCompleted = true
	local _, _, timeMs, onTime = C_ChallengeMode.GetCompletionInfo()
	local time = math.ceil(timeMs / 1000)

	self.state.completedOnTime = onTime
	self.state.completionTimeMs = timeMs
	self.state.timer = time

	-- We have to complete all objectives that are not completed yet,
	-- since we might not have gotten the final completion time
	-- if the final objective completed the run.
	for _, objective in pairs(self.state.objectives) do
		if not objective.time then
			objective.time = time
		end
	end

	if not self.state.forcesCompletionTime then
		self.state.forcesCompleted = true
		self.state.currentCount = self.state.totalCount
		self.state.currentPercent = 1.0
		self.state.forcesCompletionTime = time
	end

	self:UpdateSplits()
	self:UpdateBestSplits()

	self:RenderTimer()
	self:RenderObjectives()
	self:RenderForces()
end
