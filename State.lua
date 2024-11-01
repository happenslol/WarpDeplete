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

	timerRunning = false,
	timer = nil,
	timeLimit = nil,

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
	objectiveNames = nil, ---@type string[]|nil

	forcesCompleted = false,
	forcesCompletionTime = 0,

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

	self.state.forcesCompleted = false
	self.state.forcesCompletionTime = 0

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

function WarpDeplete:SetForcesCompletionTime(completionTime)
	self.state.forcesCompleted = true
	self.state.forcesCompletionTime = completionTime

	-- Make sure we always show max forces/100% on completion
	if self.state.challengeCompleted then
		self.state.currentPercent = 1.0

		if self.state.currentCount < self.state.totalCount then
			self.state.currentCount = self.state.totalCount
		end
	end

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

function WarpDeplete:SetObjectives(objectives)
	self.state.objectives = objectives
	self:RenderObjectives()
end

function WarpDeplete:SetKeyDetails(level, deathPenalty, affixes, affixIds, mapId)
	self.state.level = level
	self.state.deathPenalty = deathPenalty
	self.state.affixes = affixes
	self.state.affixIds = affixIds
	self.state.mapId = mapId

	self:RenderKeyDetails()
end

local function parseForcesInfo(info)
	if not info then
		return nil, nil, nil
	end

	local totalCount = info.totalQuantity
	local currentCountStr = info.quantityString

	-- NOTE(happens): The current count contains a percentage sign
	-- even though it's an absolute value.
	local currentCount = currentCountStr and tonumber(currentCountStr:match("%d+")) or 0

	local completionTime = nil
	if currentCount >= totalCount then
		completionTime = select(2, GetWorldElapsedTime(1)) - (info.elapsed or 0)
	end

	return currentCount, totalCount, completionTime
end

function WarpDeplete:LoadObjectives()
	local stepCount = select(3, C_Scenario.GetStepInfo())
	if not stepCount or stepCount <= 0 then
		return
	end

	local anythingCompleted = false

	local objectives = {}
	for i = 1, stepCount - 1 do
		local info = C_ScenarioInfo.GetCriteriaInfo(i)
		local name = info.description

		for j = 1, #self.state.objectiveNames do
			if string.find(info.description, self.state.objectiveNames[j]) then
				name = self.state.objectiveNames[j]
				break
			end
		end

		name = Util.utf8Sub(name, 20)
		local objective = { name = name, time = nil }

		if info.completed and info.elapsed and info.elapsed ~= 0 then
			-- TODO: Why do we need to subtract the elapsed time here?
			local time = select(2, GetWorldElapsedTime(1)) - info.elapsed
			objective.time = time

			anythingCompleted = true
		end

		objectives[i] = objective
	end

	self:SetObjectives(objectives)

	local forcesInfo = C_ScenarioInfo.GetCriteriaInfo(stepCount)
	local currentCount, totalCount, completionTime = parseForcesInfo(forcesInfo)

	self:SetForcesTotal(totalCount)
	self:SetForcesCurrent(currentCount)

	if completionTime then
		self:SetForcesCompletionTime(completionTime)
		anythingCompleted = true
	end

	if anythingCompleted then
		self:UpdateSplits()
	end
end

function WarpDeplete:LoadDeathCount()
	self:SetDeathCount(C_ChallengeMode.GetDeathCount() or 0)
end

function WarpDeplete:LoadKeyDetails()
	local mapId = C_ChallengeMode.GetActiveChallengeMapID()
	local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()

	if level <= 0 or #affixes <= 0 or not mapId then
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
	return true
end

function WarpDeplete:LoadEJBossNames()
	local instanceID = Util.getEJInstanceID()
	if not instanceID then
		self:PrintDebug("No EJ instance ID found")
		return
	end

	-- The encounter journal needs to be opened once
	-- before we can get anything from it
	if not self.encounterJournalOpened then
		C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
		EncounterJournal_OpenJournal(8, instanceID)
		self.encounterJournalOpened = true
		HideUIPanel(EncounterJournal)
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

function WarpDeplete:UpdateObjectives()
	local stepCount = select(3, C_Scenario.GetStepInfo())
	if not stepCount or stepCount <= 0 then
		return
	end

	local bossesChanged = false
	for i = 1, stepCount - 1 do
		local objective = self.state.objectives[i]

		-- Only update the objective if it's not completed yet
		if objective and not objective.time then
			local info = C_ScenarioInfo.GetCriteriaInfo(i)

			if info.completed and info.elapsed and info.elapsed ~= 0 then
				-- TODO: Why do we need to subtract the elapsed time here?
				local time = select(2, GetWorldElapsedTime(1)) - info.elapsed
				objective.time = time
				bossesChanged = true
			end
		end
	end

	if bossesChanged then
		self:RenderObjectives()
	end

	local forcesChanged = false
	local forcesInfo = C_ScenarioInfo.GetCriteriaInfo(stepCount)
	local currentCount, totalCount, completionTime = parseForcesInfo(forcesInfo)
	if currentCount and totalCount then
		self:SetForcesCurrent(currentCount)
	end

	if completionTime and not self.state.forcesCompletionTime then
		self:SetForcesCompletionTime(completionTime)
		forcesChanged = true
	end

	if forcesChanged or bossesChanged then
		self:UpdateSplits()
	end
end

function WarpDeplete:CompleteChallenge()
	self:StopTimerLoop()

	self.state.challengeCompleted = true
	local _, _, timeMs, onTime = C_ChallengeMode.GetCompletionInfo()
	local time = timeMs / 1000

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
		self:SetForcesCompletionTime(time)
	end

	self:UpdateBestSplits()

	self:RenderTimer()
	self:RenderObjectives()
	self:RenderForces()
end
