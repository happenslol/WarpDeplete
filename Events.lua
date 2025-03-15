local Util = WarpDeplete.Util
local L = WarpDeplete.L

---@type table<string, boolean>
WarpDeplete.registeredChallengeEvents = {}

function WarpDeplete:RegisterGlobalEvent(event)
	self:RegisterEvent(event, event)
end

function WarpDeplete:RegisterChallengeEvent(event)
	self:RegisterEvent(event, event)
	self.registeredChallengeEvents[event] = true
end

function WarpDeplete:UnregisterChallengeEvents()
	for event, _ in pairs(self.registeredChallengeEvents) do
		self:UnregisterEvent(event)
	end

	self.registeredChallengeEvents = {}
end

-- These events are used to detect whether we are in challenge mode
-- or whether we should put a key in the socket, and will always stay registered.
function WarpDeplete:RegisterGlobalEvents()
	-- Events where we could theoretically need to check for an active challenge mode
	self:RegisterGlobalEvent("PLAYER_ENTERING_WORLD")
	self:RegisterGlobalEvent("ZONE_CHANGED")
	self:RegisterGlobalEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterGlobalEvent("ZONE_CHANGED_INDOORS")
	self:RegisterGlobalEvent("PLAYER_DIFFICULTY_CHANGED")
	self:RegisterGlobalEvent("CHALLENGE_MODE_START")

	-- Fired when we open the keystone socket
	self:RegisterGlobalEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN")

	-- Register tooltip count display
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, WarpDeplete.DisplayCountInTooltip)

	-- Tooltip events
	self.frames.deathsTooltip:SetScript("OnEnter", WarpDeplete.TooltipOnEnter)
	self.frames.deathsTooltip:SetScript("OnLeave", WarpDeplete.TooltipOnLeave)
end

function WarpDeplete:RegisterChallengeEvents()
	-- Challenge mode triggers
	self:RegisterChallengeEvent("CHALLENGE_MODE_COMPLETED")
	self:RegisterChallengeEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
	self:RegisterChallengeEvent("WORLD_STATE_TIMER_START")

	-- Scenario Triggers
	self:RegisterChallengeEvent("SCENARIO_POI_UPDATE")
	self:RegisterChallengeEvent("SCENARIO_CRITERIA_UPDATE")

	-- Combat triggers
	self:RegisterChallengeEvent("ENCOUNTER_END")
	self:RegisterChallengeEvent("PLAYER_REGEN_ENABLED")

	self:RegisterChallengeEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterChallengeEvent("UNIT_THREAT_LIST_UPDATE")
end

function WarpDeplete:PLAYER_ENTERING_WORLD()
	self:CheckForChallengeMode()
end

function WarpDeplete:ZONE_CHANGED()
	self:CheckForChallengeMode()
end

function WarpDeplete:ZONE_CHANGED_NEW_AREA()
	self:CheckForChallengeMode()
end

function WarpDeplete:ZONE_CHANGED_INDOORS()
	self:CheckForChallengeMode()
end

function WarpDeplete:PLAYER_DIFFICULTY_CHANGED()
	self:CheckForChallengeMode()
end

-- We receive this when the 10s countdown after key insertion starts
function WarpDeplete:CHALLENGE_MODE_START()
	self:EnableChallengeMode()
end

function WarpDeplete:CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN()
	if not self.db.profile.insertKeystoneAutomatically then
		return
	end
	local difficulty = select(3, GetInstanceInfo())

	if difficulty ~= 8 and difficulty ~= 23 then
		return
	end

	local found = nil
	for bagIndex = 0, NUM_BAG_SLOTS do
		for invIndex = 1, C_Container.GetContainerNumSlots(bagIndex) do
			local itemID = C_Container.GetContainerItemID(bagIndex, invIndex)

			if itemID and C_Item.IsItemKeystoneByID(itemID) then
				found = { bagIndex = bagIndex, invIndex = invIndex }
				break
			end
		end

		if found then
			break
		end
	end

	if found then
		C_Container.UseContainerItem(found.bagIndex, found.invIndex)
	end
end

function WarpDeplete:CHALLENGE_MODE_COMPLETED()
	self:CompleteChallenge()
end

function WarpDeplete:WORLD_STATE_TIMER_START()
	-- Rerender everything once in case we were displaying PBs
	self.state.timerStarted = true

	self:RenderTimer()
	self:RenderForces()
	self:RenderObjectives()
end

function WarpDeplete:CHALLENGE_MODE_DEATH_COUNT_UPDATED()
	local deathCount, timeLost = C_ChallengeMode.GetDeathCount()
	self:SetDeathCount(deathCount, timeLost)
end

function WarpDeplete:SCENARIO_POI_UPDATE()
	self:UpdateObjectives()
end

function WarpDeplete:SCENARIO_CRITERIA_UPDATE()
	self:UpdateObjectives()
end

function WarpDeplete:ENCOUNTER_END()
	self:ResetCurrentPull()
end

function WarpDeplete:PLAYER_REGEN_ENABLED()
	self:ResetCurrentPull()
end

function WarpDeplete:COMBAT_LOG_EVENT_UNFILTERED()
	local _, subEv, _, _, _, _, _, guid, name = CombatLogGetCurrentEventInfo()
	if subEv ~= "UNIT_DIED" then
		return
	end
	if not guid then
		return
	end

	-- NOTE: We have to check health since we'd count feign death otherwise
	if UnitInParty(name) and UnitHealth(name) <= 1 then
		local unitName = UnitName(name)
		local class = select(2, UnitClass(name))
		self:AddDeathDetails(self.state.timer, unitName, class)
		return
	end

	if not self.state.currentPull[guid] then
		return
	end
	self.state.currentPull[guid] = "DEAD"
	local pullCount = Util.calcPullCount(self.state.currentPull, self.state.totalCount)
	self:SetForcesPull(pullCount)
end

function WarpDeplete:UNIT_THREAT_LIST_UPDATE(_, unit)
	if not MDT then
		return
	end

	if not InCombatLockdown() or not unit or not UnitExists(unit) then
		return
	end

	-- NOTE: There seem to be cases where a Unit will throw a threat list update
	-- after it has died, which falsely re-adds it to the current pull. We set that units'
	-- count value to "DEAD" when it dies, and due to the check if the guid already exists
	-- in the table, it won't be overwritten after the unit has died.
	local guid = UnitGUID(unit)
	if not guid or self.state.currentPull[guid] then
		return
	end

	local npcID = select(6, strsplit("-", guid))
	local count = MDT:GetEnemyForces(tonumber(npcID))
	if not count or count <= 0 then
		return
	end

	self.state.currentPull[guid] = count
	local pullCount = Util.calcPullCount(self.state.currentPull, self.state.totalCount)
	self:SetForcesPull(pullCount)
end

function WarpDeplete.TooltipOnEnter()
	local self = WarpDeplete
	if not self.db.profile.showDeathsTooltip then
		return
	end

	GameTooltip:SetOwner(self.frames.deathsTooltip, "ANCHOR_BOTTOMLEFT", self.frames.deathsTooltip.offsetWidth)

	GameTooltip:ClearLines()

	local count = #self.state.deathDetails
	if count == 0 then
		GameTooltip:AddLine(L["No Recorded Player Deaths"], 1, 1, 1)
		GameTooltip:Show()
		return
	end

	GameTooltip:AddLine(L["Player Deaths"], 1, 1, 1)
	if self.db.profile.deathLogStyle == "time" then
		local showFrom = 0
		if count > 20 then
			showFrom = count - 20
		end

		for i, d in ipairs(self.state.deathDetails) do
			if i >= showFrom then
				local color = select(4, GetClassColor(d.class))
				local time = Util.formatTime(d.time)
				GameTooltip:AddLine(time .. " - |c" .. color .. d.name .. "|r")
			end
		end
	elseif self.db.profile.deathLogStyle == "count" then
		local countTable = {}
		for _, d in ipairs(self.state.deathDetails) do
			if not countTable[d.name] then
				countTable[d.name] = {
					color = select(4, GetClassColor(d.class)),
					count = 0,
				}
			end

			countTable[d.name].count = countTable[d.name].count + 1
		end

		for name, deaths in pairs(countTable) do
			GameTooltip:AddLine("|c" .. deaths.color .. name .. "|r|cFFFFFFFF: " .. tostring(deaths.count) .. "|r")
		end
	end

	GameTooltip:Show()
end

function WarpDeplete.TooltipOnLeave()
	GameTooltip_Hide()
end

function WarpDeplete.DisplayCountInTooltip(tt, data)
	if not tt or tt ~= GameTooltip or not data or not data.guid then
		return
	end

	if not WarpDeplete.state.inChallenge then
		return
	end

	if not MDT or not WarpDeplete.db.profile.showTooltipCount then
		return
	end

	local npcID = select(6, strsplit("-", data.guid))
	local count, max = MDT:GetEnemyForces(tonumber(npcID))

	if count and max and count ~= 0 and max ~= 0 then
		local percentText = ("%.2f"):format(count / max * 100)
		local countText = ("%d"):format(count)
		local result = WarpDeplete.db.profile.tooltipCountFormat ~= ":custom:"
				and WarpDeplete.db.profile.tooltipCountFormat
			or WarpDeplete.db.profile.customTooltipCountFormat

		result = gsub(result, ":percent:", percentText .. "%%")
		result = gsub(result, ":count:", countText)
		GameTooltip:AddLine("Count: |cFFFFFFFF" .. result .. "|r")
		GameTooltip:Show()
	end
end
