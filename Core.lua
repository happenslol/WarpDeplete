---@class WarpDeplete: AceAddon,AceComm-3.0,AceConsole-3.0,AceEvent-3.0,AceTimer-3.0
---@field state WarpDepleteState
WarpDeplete =
	LibStub("AceAddon-3.0"):NewAddon("WarpDeplete", "AceComm-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

WarpDeplete.isShown = false

WarpDeplete.L = LibStub("AceLocale-3.0"):GetLocale("WarpDeplete", true)
local L = WarpDeplete.L

local Util = {}
WarpDeplete.Util = Util

WarpDeplete.LSM = LibStub("LibSharedMedia-3.0")
WarpDeplete.Glow = LibStub("LibCustomGlow-1.0")

-- Check if Kaliel's Tracker is loaded, since it creates a
-- background frame for the objective window that will not be
-- hidden if only the objective window itself is hidden.
---@class KT : AceAddon
---@field frame Frame
local KT = LibStub("AceAddon-3.0"):GetAddon("!KalielsTracker", true)

function WarpDeplete:OnInitialize()
	local frames = {}

	frames.root = CreateFrame("Frame", "WarpDepleteFrame", UIParent)
	frames.bars = CreateFrame("Frame", "WarpDepleteBars", frames.root)
	frames.deathsTooltip = CreateFrame("Frame", "WarpDepleteDeathsTooltip", frames.root)

	-- We use an empty frame to which we parent the blizzard objective tracker.
	-- This can then be hidden and not be affected by blizzard unhiding the
	-- objective tracker itself.
	frames.hiddenObjectiveTrackerParent = CreateFrame("frame")
	frames.hiddenObjectiveTrackerParent:Hide()

	self.frames = frames
end

function WarpDeplete:OnEnable()
	self.state = Util.copy(self.defaultState)

	self:InitDb()
	self:InitOptions()
	self:InitChatCommands()
	self:InitRender()

	self:RegisterGlobalEvents()
	self:Hide()

	if not self.db.global.mdtAlertShown and not MDT then
		self.db.global.mdtAlertShown = true
		self:ShowMDTAlert()
	end
end

function WarpDeplete:ShowMDTAlert()
	Util.showAlert(
		"MDT_NOT_FOUND",
		L["Mythic Dungeon Tools (MDT) is not installed."]
			.. "\n\n"
			.. L["WarpDeplete will not display the count for your current pull."]
			.. " \n\n"
			.. L["Install MDT to enable this functionality."]
	)
end

function WarpDeplete:OnDisable() end

function WarpDeplete:EnableDemoMode()
	if self.state.inChallenge then
		self:Print(L["Can't enable demo mode while in an active challenge!"])
		return
	end

	if self.state.demoModeActive then
		return
	end

	self:ResetState()
	self.state.demoModeActive = true

	local objectives = {}
	for i = 1, 5 do
		objectives[i] = { name = L["Test Boss Name"] .. " " .. i }

		if i < 4 then
			objectives[i].time = 520 * i
		end
	end

	self.state.objectives = objectives
	self:RenderObjectives()

	self:SetKeyDetails(30, 15, { L["Ascendance"], L["Tyrannical"], L["Fortified"], L["Peril"] }, { 9, 7, 123, 152 })

	self:SetTimeLimit(35 * 60)
	self:SetTimer(20 * 60)
	self:SetDeathCount(3)

	local classTable = {
		"SHAMAN",
		"DEMONHUNTER",
		"MONK",
		"DRUID",
		"MAGE",
	}

	local nameTable = {
		"GroupMember1",
		"GroupMember2",
		"GroupMember3",
		"GroupMember4",
		"GroupMember5",
	}

	for i = 1, 30 do
		local class = classTable[(i % #classTable) + 1]
		local name = nameTable[(i % #nameTable) + 1]
		local time = i * 7

		self:AddDeathDetails(time, name, class)
	end

	self:Show()
end

function WarpDeplete:DisableDemoMode()
	if not self.state.demoModeActive then
		return
	end
	self.state.demoModeActive = false

	self:Hide()
	self:ResetState()
end

function WarpDeplete:ShowBlizzardObjectiveTracker()
	-- As SylingTracker replaces the blizzard objective tracker in hiding
	-- it, we prevent WarpDeplete to reshown the tracker.
	if C_AddOns.IsAddOnLoaded("SylingTracker") then
		return
	end

	-- FIXME(happens): See HideBlizzardObjectiveTracker
	ObjectiveTrackerFrame:SetAlpha(1)
	ObjectiveTrackerFrame:Show()

	if ObjectiveTrackerFrame:GetParent() == self.frames.hiddenObjectiveTrackerParent then
		ObjectiveTrackerFrame:SetParent(self.originalObjectiveTrackerParent or UIParent)
	end
end

function WarpDeplete:HideBlizzardObjectiveTracker()
	-- FIXME(happens): The reparenting method seems to not work for some people.
	-- As an additional fallback, we set the alpha to 0.
	ObjectiveTrackerFrame:SetAlpha(0)

	self.originalObjectiveTrackerParent = ObjectiveTrackerFrame:GetParent()
	ObjectiveTrackerFrame:SetParent(self.frames.hiddenObjectiveTrackerParent)
	ObjectiveTrackerFrame:Hide()
end

function WarpDeplete:ShowExternals()
	if KT then
		KT.frame:Show()
	end
end

function WarpDeplete:HideExternals()
	if KT then
		KT.frame:Hide()
	end
end

function WarpDeplete:Show()
	self.isShown = true
	self.frames.root:Show()
	self:RenderLayout()

	self:HideBlizzardObjectiveTracker()
	self:HideExternals()
end

function WarpDeplete:Hide()
	self.isShown = false
	self.frames.root:Hide()

	self:ShowBlizzardObjectiveTracker()
	self:ShowExternals()
end

function WarpDeplete:ResetState()
	self.state = Util.copy(self.defaultState)
end

function WarpDeplete:CheckForChallengeMode()
	local _, type, difficulty = GetInstanceInfo()
	local inChallenge = difficulty == 8 and type == "party"
	if self.state.inChallenge == inChallenge then
		return
	end

	if inChallenge then
		self:EnableChallengeMode()
	else
		self:DisableChallengeMode()
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
	self:LoadEJBossNames()
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
