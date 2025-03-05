local UPDATE_INTERVAL = 0.1
local sinceLastUpdate = 0

local newDeathCount = 0

function WarpDeplete:OnTimerTick(elapsed)
	if self.state.timeLimit == 0 then
		local timeLimit = select(3, C_ChallengeMode.GetMapUIInfo(mapId))

		if timeLimit ~= 0 then
			self:SetTimeLimit(timeLimit)
		end
	end

	sinceLastUpdate = sinceLastUpdate + elapsed
	if sinceLastUpdate <= UPDATE_INTERVAL then
		return
	end
	sinceLastUpdate = 0

	newDeathCount = C_ChallengeMode.GetDeathCount()
	if newDeathCount ~= self.state.deathCount then
		self:SetDeathCount(newDeathCount)
	end

	self.state.timer = select(2, GetWorldElapsedTime(1))

	-- These might change after the timer has started, so rerender
	-- them once here
	if self.state.timer > 0 and not self.state.timerStarted then
		self.state.timerStarted = true
		self:RenderForces()
		self:RenderObjectives()
	end

	self:RenderTimer()
end

function WarpDeplete:StartTimerLoop()
	if self.state.timerLoopRunning then
		return
	end

	self.state.timerLoopRunning = true

	sinceLastUpdate = 0
	self.frames.root:SetScript("OnUpdate", function(_, elapsed)
		WarpDeplete:OnTimerTick(elapsed)
	end)
end

function WarpDeplete:StopTimerLoop()
	sinceLastUpdate = 0
	self.state.timerLoopRunning = false
	self.frames.root:SetScript("OnUpdate", nil)
end
