-- TimerClass moduleScript
local TimerClass = {}
TimerClass.__index = TimerClass

type TimerMode = "Countdown" | "Timer"
type TimerCallback = (timer: number) -> ()
type Callback = () -> ()

export type Timer = {
	timer: number,
	duration: number,
	isRunning: boolean,
	lastReportTime: number,
	reportInterval: number,
	mode: TimerMode,
	onTimerStart: Callback,
	onTimerEnd: Callback,
	onTimerChange: TimerCallback,
	callbacks: { [number]: Callback },
	runningTask: thread?,
	AddCallback: (self: Timer, time: number, callback: Callback) -> (),
	StartTimer: (self: Timer, duration: number) -> (),
	ShouldContinue: (self: Timer) -> boolean,
	AddTimer: (self: Timer, duration: number) -> (),
	PauseTimer: (self: Timer) -> (),
	IsRunning: (self: Timer) -> boolean,
	EndTimer: (self: Timer) -> (),
	CancelTimer: (self: Timer) -> (),
	SetTime: (self: Timer, newTime: number) -> (),
}

function TimerClass.new(
	onTimerStart: Callback?,
	onTimerEnd: Callback?,
	onTimerChange: TimerCallback?,
	mode: TimerMode,
	shouldRound: boolean
): Timer
	local self = setmetatable({}, TimerClass)
	self.onTimerStart = onTimerStart
	self.onTimerEnd = onTimerEnd
	self.onTimerChange = onTimerChange
	self.mode = mode
	self.timer = 0
	self.duration = 0
	self.shouldRound = shouldRound or false
	self.isRunning = false
	self.lastReportTime = 0
	self.reportInterval = 1
	return self
end

function TimerClass:AddCallback(time: number, callback: Callback)
	if not self.callbacks then
		self.callbacks = {}
	end
	self.callbacks[time] = callback
end

local function round(number: number, decimalPlaces: number): number
	local multiplier = 10 ^ (decimalPlaces or 0)
	return math.floor(number * multiplier + 0.5) / multiplier
end

function TimerClass:StartTimer(duration: number)
	if self:IsRunning() then
		warn("Timer is already running.")
		return
	end
	self.duration = duration
	self.timer = (self.mode == "Countdown") and duration or 0
	self.isRunning = true
	self.lastReportTime = self.timer
	if self.onTimerStart then
		self.onTimerStart()
	end
	self.runningTask = task.spawn(function()
		local startTime = tick()
		local previousTime = startTime
		while self.isRunning and self:ShouldContinue() do
			local currentTime = tick()
			local elapsedTime = currentTime - previousTime
			previousTime = currentTime

			if self.mode == "Countdown" then
				self.timer = self.timer - elapsedTime
				if self.timer < 0 then
					self.timer = 0
				end
			else
				self.timer = self.timer + elapsedTime
			end

			if self.shouldRound then
				self.timer = round(self.timer, 0)
				if math.abs(self.timer - self.lastReportTime) >= self.reportInterval and self.onTimerChange then
					self.onTimerChange(self.timer)
					self.lastReportTime = self.timer
				end
			else
				self.onTimerChange(self.timer)
			end

			local callbackTime = math.floor(self.timer)
			if self.callbacks and self.callbacks[callbackTime] then
				self.callbacks[callbackTime]()
				self.callbacks[callbackTime] = nil
			end

			task.wait()
		end
		if
			(self.mode == "Countdown" and self.timer <= 0 and self.isRunning)
			or (self.mode == "Timer" and self.isRunning)
		then
			if self.onTimerChange then
				self.onTimerChange(0) -- Final callback with zero indicating end
			end
			self:EndTimer()
		end
	end)
end

function TimerClass:SetTime(newTime: number)
	if not self:IsRunning() then
		warn("Timer is not running.")
		return
	end

	-- Ensure time doesn't go below 0 for countdown
	if self.mode == "Countdown" then
		self.timer = math.max(0, newTime)
	else
		self.timer = newTime
	end

	-- Trigger change callback immediately
	if self.shouldRound then
		self.timer = round(self.timer, 0)
	end
	if self.onTimerChange then
		self.onTimerChange(self.timer)
	end
	self.lastReportTime = self.timer
end

function TimerClass:ShouldContinue(): boolean
	return self.mode == "Countdown" and self.timer > 0 or self.mode == "Timer"
end

function TimerClass:AddTimer(duration: number)
	if self.isRunning then
		if self.mode == "Countdown" then
			self.timer = self.timer + duration
		else
			self.timer = self.timer - duration
		end
	end
end

function TimerClass:PauseTimer()
	self.isRunning = false
end

function TimerClass:IsRunning()
	return self.isRunning
end

function TimerClass:EndTimer()
	self:StopTimer()

	if self.onTimerEnd then
		self.onTimerEnd()
	end
end

function TimerClass:StopTimer()
	if not self:IsRunning() then
		warn("Timer is not running.")
		return
	end

	self.isRunning = false
	if self.mode == "Countdown" then
		self.timer = 0
	end
end

function TimerClass:CancelTimer()
	if self.runningTask then
		task.cancel(self.runningTask)
		if self.callbacks then
			self.callbacks = nil
		end
	end
end

function TimerClass:Destroy()
	self:CancelTimer()

	self.onTimerStart = nil
	self.onTimerEnd = nil
	self.onTimerChange = nil
	if self.callbacks then
		table.clear(self.callbacks)
		self.callbacks = nil
	end

	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return TimerClass
