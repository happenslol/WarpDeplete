function WarpDeplete:UpdateSplits()
	self:PrintDebug("Updating splits")
	local splits = self:GetSplitsForCurrentInstance()

	if not splits then
		self:PrintDebug("Could not get splits for current instance")
		return
	end

	local best = splits.best
	if not best then
		best = {}
		splits.best = best
	end

	local current = splits.current
	if not current then
		current = {}
		splits.current = current
	end

	local currentDiff = splits.currentDiff
	if not currentDiff then
		currentDiff = {}
		splits.currentDiff = currentDiff
	end

	for i, boss in ipairs(self.state.objectives) do
		if boss.time and boss.time ~= current[i] then
			self:PrintDebug("Setting current time for " .. tostring(i) .. ": " .. tostring(boss.time))
			current[i] = boss.time

			local bestTime = self:GetBestSplit(i)
			if bestTime then
				currentDiff[i] = boss.time - bestTime
				self:PrintDebug("Setting diff for " .. tostring(i) .. " to " .. tostring(currentDiff[i]))
			end
		elseif not boss.time then
			current[i] = nil
			currentDiff[i] = nil
		end
	end

	if self.state.forcesCompleted and self.state.forcesCompletionTime ~= current.forces then
		self:PrintDebug("Setting current time for forces")
		current.forces = self.state.forcesCompletionTime

		local bestForces = self:GetBestSplit("forces")
		if bestForces then
			currentDiff.forces = self.state.forcesCompletionTime - bestForces
			self:PrintDebug("Setting diff for forces to " .. tostring(currentDiff.forces))
		end
	elseif not self.state.forcesCompleted then
		current.forces = nil
		currentDiff.forces = nil
	end

	if self.state.challengeCompleted and self.state.completionTimeMs ~= current.challenge then
		self:PrintDebug("Setting current time for challenge")
		current.challenge = self.state.completionTimeMs

		local bestChallenge = self:GetBestSplit("challenge")
		if bestChallenge then
			currentDiff.challenge = self.state.completionTimeMs - bestChallenge
			self:PrintDebug("Setting diff for challenge to " .. tostring(currentDiff.challenge))
		end
	elseif not self.state.challengeCompleted then
		current.challenge = nil
		currentDiff.challenge = nil
	end

	self:PrintDebug("Splits updated")
end

---@param objective integer|"forces"|"challenge"
function WarpDeplete:GetCurrentDiff(objective)
	if self.state.demoModeActive then
		if type(objective) == "number" then
			return -60 + (objective * 30)
		end

		if objective == "forces" then
			return -40
		end

		if objective == "challenge" then
			return 100 * 1000
		end

		return 0
	end

	local splits = self:GetSplitsForCurrentInstance()
	if not splits then
		return nil
	end

	local currentDiff = splits.currentDiff
	if not currentDiff then
		return nil
	end

	return currentDiff[objective]
end

---@param objective integer|"forces"|"challenge"
---@return number|nil, number|nil @returns (time, sourceLevel)
function WarpDeplete:GetBestSplit(objective)
	if self.state.demoModeActive then
		if type(objective) == "number" then return 60 * 3 * objective, 30 end
		if objective == "forces" then return 60 * 30, 30 end
		if objective == "challenge" then return 60 * 36 * 1000, 30 end
		return 0, 30
	end

	if not self.state.mapId or not self.state.level then
		return nil, nil
	end

	local mapSplits = self.db.global.splits[self.state.mapId]
	if not mapSplits then return nil, nil end

	-- 1. Look for the exact time for this key level
	if mapSplits[self.state.level] and mapSplits[self.state.level].best and mapSplits[self.state.level].best[objective] then
		return mapSplits[self.state.level].best[objective], self.state.level
	end

	-- 2. Fallback option if no record was found for the current level
	local fallback = self.db.profile.fallbackSplitBehavior
	if not fallback or fallback == "none" then return nil, nil end

	local targetLevel = nil
	local bestTime = nil
	local currentLevel = self.state.level

	for level, splits in pairs(mapSplits) do
		if splits.best and splits.best[objective] then
			if not targetLevel then
				-- First valid record found
				targetLevel = level
				bestTime = splits.best[objective]
			elseif fallback == "highest" then
				-- Strictly pick the highest key level available
				if level > targetLevel then
					targetLevel = level
					bestTime = splits.best[objective]
				end
			elseif fallback == "lowest" then
				-- Strictly pick the lowest key level available
				if level < targetLevel then
					targetLevel = level
					bestTime = splits.best[objective]
				end
			elseif fallback == "closest_lower" then
				local currentIsLower = level < currentLevel
				local bestIsLower = targetLevel < currentLevel
				
				if currentIsLower and not bestIsLower then
					-- Prioritize any lower level over a higher one
					targetLevel = level
					bestTime = splits.best[objective]
				elseif currentIsLower and bestIsLower then
					-- If both are lower, take the highest one (closest to current level)
					if level > targetLevel then
						targetLevel = level
						bestTime = splits.best[objective]
					end
				elseif not currentIsLower and not bestIsLower then
					-- If no lower level exists, fallback to the lowest of the higher ones (closest to current level)
					if level < targetLevel then
						targetLevel = level
						bestTime = splits.best[objective]
					end
				end
			elseif fallback == "closest_higher" then
				local currentIsHigher = level > currentLevel
				local bestIsHigher = targetLevel > currentLevel
				
				if currentIsHigher and not bestIsHigher then
					-- Prioritize any higher level over a lower one
					targetLevel = level
					bestTime = splits.best[objective]
				elseif currentIsHigher and bestIsHigher then
					-- If both are higher, take the lowest one (closest to current level)
					if level < targetLevel then
						targetLevel = level
						bestTime = splits.best[objective]
					end
				elseif not currentIsHigher and not bestIsHigher then
					-- If no higher level exists, fallback to the highest of the lower ones (closest to current level)
					if level > targetLevel then
						targetLevel = level
						bestTime = splits.best[objective]
					end
				end
			end
		end
	end

	return bestTime, targetLevel
end

function WarpDeplete:GetSplitsForCurrentInstance()
	if not self.state.mapId or not self.state.level then
		return nil
	end

	return self:GetSplits(self.state.mapId, self.state.level)
end

function WarpDeplete:GetSplits(mapId, keystoneLevel)
	local mapSplits = self.db.global.splits[mapId]
	if not mapSplits then
		mapSplits = {}
		self.db.global.splits[mapId] = mapSplits
	end

	local keystoneSplits = mapSplits[keystoneLevel]
	if not keystoneSplits then
		keystoneSplits = {}
		mapSplits[keystoneLevel] = keystoneSplits
	end

	return keystoneSplits
end

function WarpDeplete:ResetCurrentSplits()
	local splits = self:GetSplitsForCurrentInstance()
	if not splits then
		return
	end

	splits.current = {}
	splits.currentDiff = {}
end

function WarpDeplete:UpdateBestSplits()
	local splits = self:GetSplitsForCurrentInstance()
	if not splits or not splits.current then
		return
	end

	if not splits.best then
		splits.best = {}
	end

	for k, v in pairs(splits.current) do
		self:PrintDebug("Updating best split for objective " .. tostring(k))
		if not splits.best[k] then
			self:PrintDebug("No best time found, setting " .. tostring(v))
			splits.best[k] = v
		elseif splits.best[k] > v then
			self:PrintDebug("Better time found, setting " .. tostring(v))
			splits.best[k] = v
		end
	end
end
