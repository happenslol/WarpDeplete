local UPDATE_INTERVAL = 0.1
local sinceLastUpdate = 0

local newDeathCount = 0

function WarpDeplete:OnTimerTick(elapsed)
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
	self:RenderTimer()
end

function WarpDeplete:StartTimerLoop()
	if self.state.timerRunning then
		return
	end

	self.state.timerRunning = true

	sinceLastUpdate = 0
	self.frames.root:SetScript("OnUpdate", function(_, elapsed)
		WarpDeplete:OnTimerTick(elapsed)
	end)
end

function WarpDeplete:StopTimerLoop()
	sinceLastUpdate = 0
	self.state.timerRunning = false
	self.frames.root:SetScript("OnUpdate", nil)
end
