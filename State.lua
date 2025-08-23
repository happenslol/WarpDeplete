local Util = WarpDeplete.Util
local L = WarpDeplete.L

---@class WarpDepleteObjective
---@field name? string
---@field description string
---@field time integer|nil
---@field dungeonEncounterID integer|nil

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
	-- Time limits for +1, +2 and +3 in order. The first element
	-- will always be equal to timeLimit and is only in here for
	-- ease of access.
	timeLimits = {},

	deathCount = 0,
	deathTimeLost = 0,
	deathDetails = {},

	pullCount = 0,
	currentCount = 0,
	totalCount = 100,

	pullPercent = 0,
	currentPercent = 0,
	pullGlowActive = false,
	currentPull = {}, ---@type table<integer, string|nil|"DEAD">

	objectives = {}, ---@type WarpDepleteObjective[]
	ejObjectiveNames = nil, ---@type string[]|nil
	ejEncounterNames = nil, ---@type table<integer, string>|nil

	forcesCompleted = false,
	forcesCompletionTime = nil,

	level = 0,
	affixes = {}, ---@type string[]
	affixIds = {}, ---@type integer[]
	hasChallengersPeril = false,
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

function WarpDeplete:SetDeathCount(count, timeLost)
	count = count or 0
	timeLost = timeLost or 0

	self.state.deathCount = count
	self.state.deathTimeLost = timeLost

	local deathText = Util.formatDeathText(count, timeLost)
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

	if self.state.hasChallengersPeril then
		local limitWithoutPerilBonus = timeLimit - 90
		self.state.timeLimits = {
			timeLimit,
			(limitWithoutPerilBonus * 0.8) + 90,
			(limitWithoutPerilBonus * 0.6) + 90
		}
	else
		self.state.timeLimits = { timeLimit, timeLimit * 0.8, timeLimit * 0.6 }
	end

	self:RenderTimer()
end

---@param level integer
---@param hasChallengersPeril boolean
---@param affixes string[]
---@param affixIds integer[]
---@param mapId integer
function WarpDeplete:SetKeyDetails(level, hasChallengersPeril, affixes, affixIds, mapId)
	self.state.level = level
	self.state.hasChallengersPeril = hasChallengersPeril
	self.state.affixes = affixes
	self.state.affixIds = affixIds
	self.state.mapId = mapId

	self:RenderKeyDetails()
	self:RenderLayout()
end

function WarpDeplete:LoadDeathCount()
	local deathCount, timeLost = C_ChallengeMode.GetDeathCount()
	self:SetDeathCount(deathCount, timeLost)
end

function WarpDeplete:LoadKeyDetails()
	local mapId = C_ChallengeMode.GetActiveChallengeMapID()
	if not mapId then
		return
	end

	local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()

	if not level or level <= 0 then
		return
	end

	local hasChallengersPeril = false
	local affixNames = {}
	local affixIds = {}
	for i, affixID in ipairs(affixes) do
		local name = C_ChallengeMode.GetAffixInfo(affixID)
		affixNames[i] = Util.formatAffixName(name)
		affixIds[i] = affixID
		if affixID == 152 then
			hasChallengersPeril = true
		end
	end

	self:SetKeyDetails(level, hasChallengersPeril, affixNames, affixIds, mapId)

	local timeLimit = select(3, C_ChallengeMode.GetMapUIInfo(mapId))
	self:SetTimeLimit(timeLimit)
end

function WarpDeplete:GetEJObjectiveNames()
	self:PrintDebug("Loading EJ objective names")
	local instanceID = Util.getEJInstanceID()
	if not instanceID then
		self:PrintDebug("No EJ instance ID found")
		return nil
	end

	local wasShown = EncounterJournal and EncounterJournal:IsShown()
	if not wasShown then
		self:PrintDebug("Opening encounter journal")
		C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
	end

	EncounterJournal_OpenJournal(8, instanceID)

	if not wasShown then
		HideUIPanel(EncounterJournal)
	end

	local result = {}
	local encounterResults = {}

	-- EJ_GetEncounterInfoByIndex requires EJ_SelectInstance to be called at least once during the session when passing a journalInstanceID to not return nil
	EJ_SelectInstance(1267)

	-- There are never more than 20 objectives
	-- (probably way less, but let's be safe here)
	for i = 1, 20 do
		local name, _, _, _, _, _, dungeonEncounterID = EJ_GetEncounterInfoByIndex(i, instanceID)

		if name then
			result[#result + 1] = name
			encounterResults[dungeonEncounterID] = name
			self:PrintDebug("Found boss name ", i, ":", name, " (dungeonEncounterID: ", dungeonEncounterID, ")")
		end
	end

	if #result == 0 then
		return nil
	end

	return result, encounterResults
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

---@param count? integer
function WarpDeplete:RefreshObjectiveNames(count)
	count = count or 6
	self:PrintDebug("Refreshing boss names (" .. tostring(count) .. ")")

	self.state.ejObjectiveNames, self.state.ejEncounterNames = self:GetEJObjectiveNames()
	if not self.state.ejObjectiveNames then
		self:PrintDebug("No EJ objective names received")

		if count > 0 then
			C_Timer.After(2, function()
				self:RefreshObjectiveNames(count - 1)
			end)
		end

		return
	end

	for i, boss in ipairs(self.state.objectives) do
		boss.name = self:FindObjectiveName(boss.description, i, boss.dungeonEncounterID)
	end
end

---@param description string
---@param index integer
---@param dungeonEncounterID integer?
---@return string name
function WarpDeplete:FindObjectiveName(description, index, dungeonEncounterID)
	if dungeonEncounterID and self.state.ejEncounterNames and self.state.ejEncounterNames[dungeonEncounterID] then
		local name = self.state.ejEncounterNames[dungeonEncounterID]
		self:PrintDebug("Using EJ boss name for dungeonEncounterID", dungeonEncounterID, ":", description, "->" .. name)
		return Util.utf8Sub(name, 40)
	end

	local offset = C_ChallengeMode.GetActiveChallengeMapID() == 392 and 5 or 0 -- tazavesh gambit starts at boss 6
	index = index + offset
	if self.state.ejObjectiveNames and self.state.ejObjectiveNames[index] then
		local name = self.state.ejObjectiveNames[index]
		self:PrintDebug("Using EJ boss name at index ", index, ":", description, "->", name)
		return Util.utf8Sub(name, 40)
	end

	local filtered = Util.formatObjectiveName(description)
	self:PrintDebug("No EJ boss name at index", index, ", falling back to string filtering:", description, "->", filtered)
	return Util.utf8Sub(filtered, 40)
end

function WarpDeplete:UpdateObjectives()
	local stepCount = select(3, C_Scenario.GetStepInfo())
	if not stepCount or stepCount <= 0 then
		return
	end

	local completionChanged = false
	local bossesLoaded = false

	for i = 1, 10 do
		-- Unload bosses if we initially got too many (e.g. tazavesh)
		-- TODO: Find out how we can initially get the correct bosses only for the
		-- current challenge. In tazavesh, we get all bosses for both challenges,
		-- and then they update during the countdown.
		if i > stepCount then
			if self.state.objectives[i] then
				bossesLoaded = true
			end
			self.state.objectives[i] = nil

		-- Otherwise, load normally
		else
			local info = C_ScenarioInfo.GetCriteriaInfo(i)
			if not info.isWeightedProgress then
				-- criteriaType 165 = Defeat DungeonEncounter, in which case the assetID will be the DungeonEncounterID
				local dungeonEncounterID = info.criteriaType == 165 and info.assetID or nil
				local name = self:FindObjectiveName(info.description, i, dungeonEncounterID)
				if not self.state.objectives[i] or self.state.objectives[i].name ~= name then
					self.state.objectives[i] = { name = name, description = info.description, time = nil, dungeonEncounterID = dungeonEncounterID }
					bossesLoaded = true
				end

				local objective = self.state.objectives[i]
				if not objective.time and info.completed then
					local time = select(2, GetWorldElapsedTime(1)) - (info.elapsed or 0)
					objective.time = time
					completionChanged = true
				end
			elseif info.isWeightedProgress and info.totalQuantity and info.totalQuantity > 0 then
				if self.state.objectives[i] then 
					bossesLoaded = true
				end
				self.state.objectives[i] = nil
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
	end

	if bossesLoaded then
		self:RenderObjectives()
		self:RenderLayout()

		if not self.state.ejObjectiveNames then
			self:RefreshObjectiveNames()
		end
	end

	if completionChanged then
		self:UpdateSplits()
		self:RenderForces()
		self:RenderObjectives()
	end
end

function WarpDeplete:EnableChallengeMode()
	if self.state.inChallenge then
		self:PrintDebug("Enabling challenge mode while in challenge")
	end

	if self.state.demoModeActive then
		self:Print(L["Disabling demo mode because a challenge has started."])
		self:DisableDemoMode()
	end

	self:PrintDebug("Starting challenge mode")
	self:ResetState()
	self:RegisterChallengeEvents()

	self.state.inChallenge = true

	self:LoadKeyDetails()
	self:LoadDeathCount()

	self.state.ejObjectiveNames, self.state.ejEncounterNames = self:GetEJObjectiveNames()
	self:UpdateObjectives()

	self:Show()
	self:StartTimerLoop()
end

function WarpDeplete:DisableChallengeMode()
	if self.isShown then
		self:Hide()
	end

	if not self.state.inChallenge then
		return
	end

	self:ResetState()
	self:UnregisterChallengeEvents()
end

function WarpDeplete:CompleteChallenge()
	self:StopTimerLoop()
	self:ResetCurrentPull()

	self.state.challengeCompleted = true
	local _, _, timeMs, onTime = C_ChallengeMode.GetCompletionInfo()

	self.state.completedOnTime = onTime
	self.state.completionTimeMs = timeMs

	-- We have to complete all objectives that are not completed yet,
	-- since we might not have gotten the final completion time
	-- if the final objective completed the run.
	for _, objective in pairs(self.state.objectives) do
		if not objective.time then
			objective.time = self.state.timer
		end
	end

	if not self.state.forcesCompletionTime then
		self.state.forcesCompleted = true
		self.state.currentCount = self.state.totalCount
		self.state.currentPercent = 1.0
		self.state.forcesCompletionTime = self.state.timer
	end

	self:UpdateSplits()
	self:UpdateBestSplits()

	self:RenderTimer()
	self:RenderObjectives()
	self:RenderForces()
end
