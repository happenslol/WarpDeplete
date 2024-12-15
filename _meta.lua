---@meta

---@class MDT
MDT = {}

---@param npcID integer?
function MDT:GetEnemyForces(npcID) end

---@class KalielsTracker
KalielsTracker = {}

---@param show boolean
function KalielsTracker:Toggle(show) end

---@class ObjectiveTrackerFrame : Frame
ObjectiveTrackerFrame = {}

function ObjectiveTrackerFrame:Update() end

---@class TooltipDataProcessor
TooltipDataProcessor = {}

---@param type integer
---@param func function
function TooltipDataProcessor.AddTooltipPostCall(type, func) end

---@class Settings
Settings = {}

---@param category string
function Settings.OpenToCategory(category) end

---@param difficultyID integer
---@param instanceID integer
function EncounterJournal_OpenJournal(difficultyID, instanceID) end
function GameTooltip_Hide() end

---@class EncounterJournal : Frame
EncounterJournal = {}

---@class StaticPopupDialogs
StaticPopupDialogs = {}

---@param key string
function StaticPopup_Show(key) end
