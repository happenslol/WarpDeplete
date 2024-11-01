---@meta

---@class MDT
---@field zoneIdToDungeonIdx table<integer, integer>
---@field dungeonTotalCount table<integer, table<string, integer>>
MDT = {}

---@param npcID integer?
function MDT:GetEnemyForces(npcID) end

---@class ObjectiveTrackerFrame : Frame
ObjectiveTrackerFrame = {}

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
