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

	-- Also get reference best for fallback diff calculation
	local referenceSplits = self:GetReferenceSplits()
	local referenceBest = (referenceSplits and referenceSplits.best) or best

	for i, boss in ipairs(self.state.objectives) do
		if boss.time and boss.time ~= current[i] then
			self:PrintDebug("Setting current time for " .. tostring(i) .. ": " .. tostring(boss.time))
			current[i] = boss.time

			if referenceBest[i] then
				currentDiff[i] = boss.time - referenceBest[i]
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

		if referenceBest.forces then
			currentDiff.forces = self.state.forcesCompletionTime - referenceBest.forces
			self:PrintDebug("Setting diff for forces to " .. tostring(currentDiff.forces))
		end
	elseif not self.state.forcesCompleted then
		current.forces = nil
		currentDiff.forces = nil
	end

	if self.state.challengeCompleted and self.state.completionTimeMs ~= current.challenge then
		self:PrintDebug("Setting current time for challenge")
		current.challenge = self.state.completionTimeMs

		if referenceBest.challenge then
			currentDiff.challenge = self.state.completionTimeMs - referenceBest.challenge
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
function WarpDeplete:GetBestSplit(objective)
	if self.state.demoModeActive then
		if type(objective) == "number" then
			return 60 * 3 * objective
		end

		if objective == "forces" then
			return 60 * 30
		end

		if objective == "challenge" then
			return 60 * 36 * 1000
		end

		return 0
	end

	local splits, sourceLevel = self:GetReferenceSplits()
	if not splits then
		return nil
	end

	local best = splits.best
	if not best then
		return nil
	end

	return best[objective], sourceLevel
end

function WarpDeplete:GetSplitsForCurrentInstance()
	if not self.state.mapId or not self.state.level then
		return nil
	end

	return self:GetSplits(self.state.mapId, self.state.level)
end

function WarpDeplete:GetReferenceSplits()
	if not self.state.mapId or not self.state.level then
		return nil
	end

	local currentSplits = self:GetSplits(self.state.mapId, self.state.level)

	-- If we have best splits for the current level, use them
	if currentSplits and currentSplits.best and next(currentSplits.best) then
		return currentSplits, self.state.level
	end

	local behavior = self.db.profile.fallbackSplitBehavior or "none"
	if behavior == "none" then
		return currentSplits, nil
	end

	local mapSplits = self.db.global.splits[self.state.mapId]
	if not mapSplits then
		return currentSplits, nil
	end

	local levels = {}
	for level, data in pairs(mapSplits) do
		if data.best and next(data.best) then
			table.insert(levels, level)
		end
	end

	if #levels == 0 then
		return currentSplits, nil
	end

	table.sort(levels)

	local targetLevel = nil
	if behavior == "highest" then
		targetLevel = levels[#levels]
	elseif behavior == "lowest" then
		targetLevel = levels[1]
	elseif behavior == "closest_higher" then
		for _, l in ipairs(levels) do
			if l > self.state.level then
				targetLevel = l
				break
			end
		end
		if not targetLevel then
			targetLevel = levels[#levels]
		end
	elseif behavior == "closest_lower" then
		for i = #levels, 1, -1 do
			if levels[i] < self.state.level then
				targetLevel = levels[i]
				break
			end
		end
		if not targetLevel then
			targetLevel = levels[1]
		end
	end

	if targetLevel then
		return mapSplits[targetLevel], targetLevel
	end

	return currentSplits, nil
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