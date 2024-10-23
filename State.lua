local Util = WarpDeplete.Util

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
	self:PrintDebug("Setting forces completion time")
	self.state.forcesCompleted = true
	self.state.forcesCompletionTime = completionTime

	-- Make sure we always show max forces/100% on completion
	if self.state.challengeCompleted then
		self.state.currentPercent = 1.0

		if self.state.currentCount < self.state.totalCount then
			self.state.currentCount = self.state.totalCount
		end
	end

	self:UpdateSplits()
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

function WarpDeplete:LoadObjectives()
	-- GetObjectivesInfo
	-- local gotForcesInfo, stepCount = self:GetForcesInfo()
	-- if not gotForcesInfo then
	-- 	return false
	-- end
	--
	-- local objectives = {}
	-- for i = 1, stepCount - 1 do
	-- 	local CriteriaInfo = C_ScenarioInfo.GetCriteriaInfo(i)
	-- 	if CriteriaInfo == nil then
	-- 		return false
	-- 	end
	--
	-- 	local name = CriteriaInfo.description
	-- 	local completed = CriteriaInfo.completed
	-- 	if not name then
	-- 		break
	-- 	end
	--
	-- 	name = name:gsub(" defeated", "")
	-- 	name = name:gsub(" Defeated", "")
	-- 	self:PrintDebug("Got boss name for index " .. i .. ": " .. tostring(name))
	-- 	objectives[i] = { name = name, time = completed and 0 or nil }
	-- end
	--
	-- if #objectives <= 0 then
	-- 	self:PrintDebug("No objectives received")
	-- 	return false
	-- end
	--
	-- self:SetObjectives(objectives)
	-- return true

	-- GetForcesInfo
	-- -- The last step is forces, all previous steps are bosses
	-- local stepCount = select(3, C_Scenario.GetStepInfo())
	-- if stepCount <= 0 then
	-- 	self:PrintDebug("No steps received, can't update objective info")
	-- 	return false, 0
	-- end
	--
	-- local currentCount, totalCount, completionTime = self:GetEnemyForcesCount()
	-- self:PrintDebug("Got forces info: " .. tonumber(currentCount) .. "/" .. tonumber(totalCount))
	--
	-- if currentCount == nil or totalCount == nil then
	-- 	self:PrintDebug("No mob count received in GetObjectivesInfo")
	-- 	return false, 0
	-- end
	--
	-- self:SetForcesTotal(totalCount)
	-- self:SetForcesCurrent(currentCount)
	--
	-- if completionTime ~= nil then
	-- 	self:PrintDebug("Setting forces completion in GetObjectivesInfo")
	-- 	self:SetForcesCompletionTime(completionTime)
	-- end
	--
	-- return true, stepCount
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
	-- UpdateObjectives
	-- if not self.challengeState.inChallenge then
	-- 	return
	-- end
	--
	-- local objectives = Util.copy(self.objectivesState)
	-- local changed = false
	--
	-- self:PrintDebug("Updating objectives")
	-- local stepCount = select(3, C_Scenario.GetStepInfo())
	-- for i = 1, stepCount - 1 do
	-- 	if not objectives[i] or not objectives[i].time then
	-- 		local info = C_ScenarioInfo.GetCriteriaInfo(i)
	--
	-- 		-- DEBUG
	-- 		local dbg = "Objective " .. tostring(i) .. ":"
	-- 		for k, v in pairs(info) do
	-- 			dbg = dbg .. " " .. tostring(k) .. "=" .. tostring(v)
	-- 		end
	--
	-- 		self:PrintDebug(dbg)
	--
	-- 		if info ~= nil and info.completed then
	-- 			objectives[i] = objectives[i] or {}
	-- 			objectives[i].time = select(2, GetWorldElapsedTime(1)) - (info.elapsed or 0)
	-- 			changed = true
	-- 		end
	-- 	end
	-- end
	--
	-- if changed then
	-- 	self:UpdateSplits()
	-- 	self:SetObjectives(objectives)
	-- end

	-- UpdateForces
	-- if not self.state.inChallenge then
	-- 	return
	-- end
	--
	-- local currentCount, totalCount, completionTime = self:GetEnemyForcesCount()
	-- -- This mostly happens when we have already completed the dungeon
	-- if currentCount == nil or totalCount == nil then
	-- 	self:PrintDebug("Got no forces total or current on UpdateForces")
	-- 	return
	-- end
	--
	-- self:PrintDebug("Count: " .. tostring(currentCount) .. "/" .. tostring(totalCount))
	--
	-- self:SetForcesCurrent(currentCount)
	--
	-- if completionTime ~= nil then
	-- 	self:PrintDebug("Setting forces completion in UpdateForces")
	-- 	self:SetForcesCompletionTime(completionTime)
	-- end
end

function WarpDeplete:GetForcesCompletionTime()
	self:PrintDebug("Getting forces completion time")
	local stepCount = select(3, C_Scenario.GetStepInfo())
	local info = C_Scenario.GetCriteriaInfo(stepCount)
	local completionTime = info and info.elapsed or nil

	if not completionTime then
		return nil
	end

	return select(2, GetWorldElapsedTime(1)) - completionTime
end

function WarpDeplete:GetEnemyForcesCount()
	self:PrintDebug("Getting enemy forces count")
	local stepCount = select(3, C_Scenario.GetStepInfo())
	local info = C_ScenarioInfo.GetCriteriaInfo(stepCount)
	if not info then
		self:PrintDebug("Got no criteria info in GetEnemyForcesCount")
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
		self:PrintDebug("Returning completion time: " .. tostring(completionTime))
	end

	return currentCount, totalCount, completionTime
end
