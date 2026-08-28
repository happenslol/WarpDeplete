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

WarpDeplete.Midnight = select(4, GetBuildInfo()) >= 120000

local ruRU, western = WarpDeplete.LSM.LOCALE_BIT_ruRU, WarpDeplete.LSM.LOCALE_BIT_western

-- Register media
WarpDeplete.LSM:Register("border", "WarpDeplete Blank", [[Interface\AddOns\WarpDeplete\Media\Textures\white.tga]])
WarpDeplete.LSM:Register("statusbar", "WarpDeplete Blank", [[Interface\AddOns\WarpDeplete\Media\Textures\white.tga]])
WarpDeplete.LSM:Register("font", "Expressway", [[Interface\AddOns\WarpDeplete\Media\Fonts\Expressway.ttf]], ruRU + western)

function WarpDeplete:OnInitialize()
	local frames = {}

	frames.root = CreateFrame("Frame", "WarpDepleteFrame", UIParent)
	frames.bars = CreateFrame("Frame", "WarpDepleteBars", frames.root)
	frames.deathsTooltip = CreateFrame("Frame", "WarpDepleteDeathsTooltip", frames.root)

	self.frames = frames

	if ObjectiveTrackerFrame then
		self.objectiveTrackerHandler = CreateFrame("Frame", nil, ObjectiveTrackerFrame, "SecureHandlerBaseTemplate")
		self.objectiveTrackerHandler:SetFrameRef("tracker", ObjectiveTrackerFrame)
		self.objectiveTrackerHandler:SetAttribute("hideTracker", false)
		self.objectiveTrackerHandler:SetAttribute("restoreTracker", false)
		self:HookObjectiveTracker()
	end
end

function WarpDeplete:OnEnable()
	self.state = Util.copy(self.defaultState)

	self:InitDb()
	self:InitOptions()
	self:InitChatCommands()
	self:InitRender()

	self:RegisterGlobalEvents()
	self:Hide()

	if not self.Midnight and not self.db.global.mdtAlertShown and ((PlayerGetTimerunningSeasonID() and not C_AddOns.IsAddOnLoaded("MDT Legacy")) or not MDT) then
		self.db.global.mdtAlertShown = true
		self:ShowMDTAlert()
	end
end

function WarpDeplete:ShowMDTAlert()
	if PlayerGetTimerunningSeasonID() then
		Util.showAlert(
			"MDT_LEGACY_NOT_FOUND",
			L["Mythic Dungeon Tools (MDT) Legacy is not installed."]
				.. "\n\n"
				.. L["WarpDeplete will not display the count for your current pull."]
				.. " \n\n"
				.. L["Install MDT Legacy to enable this functionality."]
		)
		return
	end

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

	self:SetTimeLimit(35 * 60)
	self:SetKeyDetails(30, true, { L["Ascendance"], L["Tyrannical"], L["Fortified"], L["Peril"] }, { 9, 7, 123, 152 }, 1)

	self:SetTimer(20 * 60)
	self:SetDeathCount(3, 45)

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

function WarpDeplete:HookObjectiveTracker()
	local handler = self.objectiveTrackerHandler
	if not handler then return end

	handler:WrapScript(ObjectiveTrackerFrame, "OnShow", [[
		if control:GetAttribute("hideTracker") then
			control:SetAttribute("restoreTracker", true)
			self:Hide()
			return false
		end
	]])
end

function WarpDeplete:ShowObjectiveTracker()
	if KalielsTracker and KalielsTracker.Toggle then
		KalielsTracker:Toggle(true)
		return
	end

	local handler = self.objectiveTrackerHandler
	if not handler or InCombatLockdown() then return end

	local restoreTracker = handler:GetAttribute("restoreTracker")
	handler:SetAttribute("hideTracker", false)
	handler:SetAttribute("restoreTracker", false)

	-- SylingTracker restores its own tracker state.
	if C_AddOns.IsAddOnLoaded("SylingTracker") then return end

	if restoreTracker then
		handler:Execute([[self:GetFrameRef("tracker"):Show()]])
	end
end

function WarpDeplete:HideObjectiveTracker()
	if KalielsTracker and KalielsTracker.Toggle then
		KalielsTracker:Toggle(false)
		return
	end

	local handler = self.objectiveTrackerHandler
	if not handler or InCombatLockdown() then return end

	if not handler:GetAttribute("hideTracker") then
		handler:SetAttribute("restoreTracker", ObjectiveTrackerFrame:IsShown())
		handler:SetAttribute("hideTracker", true)
	end

	handler:Execute([[self:GetFrameRef("tracker"):Hide()]])
end

function WarpDeplete:Show()
	self.isShown = true
	self.frames.root:Show()
	self:RenderLayout()

	self:HideObjectiveTracker()
end

function WarpDeplete:Hide()
	self.isShown = false
	self.frames.root:Hide()

	self:ShowObjectiveTracker()
end

function WarpDeplete:ResetState()
	self.state = Util.copy(self.defaultState)
end

function WarpDeplete:CheckForChallengeMode()
	-- C_ChallengeMode.IsChallengeModeActive returns false after
	-- the key has been completed, so this is more reliable
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
