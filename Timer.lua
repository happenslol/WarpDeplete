local UPDATE_INTERVAL = 0.1
local sinceLastUpdate = 0

function WarpDeplete:OnTimerTick(elapsed)
	sinceLastUpdate = sinceLastUpdate + elapsed
	if sinceLastUpdate <= UPDATE_INTERVAL then
		return
	end
	sinceLastUpdate = 0

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
