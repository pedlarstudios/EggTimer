using Log4MonkeyC as Log;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Timer as Timer;

//! Class responsible for creating and starting/stopping [EggTimer]s
class TimerManager {
	static const MAX_MANAGED_TIMER_COUNT = 1;
	
	hidden var timerStartedCallback;
	hidden var timerStoppedCallback;
	hidden var timerFinishedCallback;
	hidden var timerCount = 0;
	hidden var timers = new [ MAX_MANAGED_TIMER_COUNT ];
	hidden var selectedTimer;
	hidden var logger;

	//! Creates a TimerManager instance
	//!
	//! @param [Method] timerStartedCallback Method to call when a timer starts
	//! @param [Method] timerStoppedCallback Method to call when a timer stops
	//! @param [Method] timerFinishedCallback Method to call when a timer finishes
	function initialize(timerStartedCallback, timerStoppedCallback, timerFinishedCallback) {
		self.timerStartedCallback = timerStartedCallback;
		self.timerStoppedCallback = timerStoppedCallback;
		self.timerFinishedCallback = timerFinishedCallback;
		logger = Log.getLogger("TimeManager");
	}
	
	//! @return [Boolean] True if a timer can be added
	function canAddTimer() {
		return timerCount < MAX_MANAGED_TIMER_COUNT;
	}

	//! Add a timer, selecting it in the process. This timer begins in a stopped state
	//!
	//! @param [Duration] duration
	//! @param [Duration] elapsedTime
	function addTimer(duration, elapsedTime) {
		addTimerHidden(duration, elapsedTime, false);
	}
	
	//! Add a new timer, selecting it in the process, and starting it automatically
	//!
	//! @param [Duration] duration
	function addNewTimer(duration) {
		addTimerHidden(duration, new Time.Duration(0), true);
	}
	
	//! @return [Number] The number of timers
	function getTimerCount() {
		return timerCount;
	}
	
	    
    //! @return [Array] of [EggTimer]s, of size MAX_MANAGED_TIMER_COUNT (may have null items)
    function getTimers() {
        return timers;
    }
	
	//! @return Selected [EggTimer], or null if there are no timers
	function getSelectedTimer() {
		return selectedTimer;
	}
	
	//! Clear the selected timer
	function clearSelectedTimer() {
		selectedTimer = null;
		// TODO - Truly handle multiple timers
		timers = new [ MAX_MANAGED_TIMER_COUNT ];
		timerCount = 0;
	}
	
	//! Select the current timer that will have action taken on it
	//! 
	//! @param [EggTimer] timer to select
	function selectTimer(timer) {
		selectedTimer = timer;
	}
	
	//! Start or stop the selected timer, if one is present
	function startOrStopSelectedTimer() {
		if (selectedTimer != null) {
			selectedTimer.startOrStop();
			if (selectedTimer.isRunning()) {
				timerStartedCallback.invoke(selectedTimer);
			}
			else {
				timerStoppedCallback.invoke(selectedTimer);
			}
		}
	}
	
	hidden function addTimerHidden(duration, elapsedTime, startAutomatically) {
		if (timerCount >= MAX_MANAGED_TIMER_COUNT) {
			logger.error("Cannot add timer, max timer count of " + MAX_MANAGED_TIMER_COUNT + " would be exceeded");
			return null;
		}
		
		logger.debug("Adding timer with duration: " + duration.value() + "s, elapsed time: " + elapsedTime.value() + "s");		
		var newTimer = new EggTimer(duration, elapsedTime, timerCount + 1, startAutomatically, timerFinishedCallback);
		timers[timerCount] = newTimer;
		timerCount++;
		selectTimer(newTimer);
		return newTimer;
	}
	
	//! Simple class representing a timer
	class EggTimer {		
		hidden var backingTimer;
		hidden var duration;
		hidden var timeElapsed;
		hidden var label;
		hidden var timeRemaining;
		hidden var logger;
		hidden var timerFinishedCallback;
		hidden var _isRunning = false;	// Monkey C does not presently allow variable names and method names to be the same, hence the underscore
	
		//! Creates an EggTimer instance
		//!
		//! @param [Duration] duration Duration of the timer
		//!	@param [Duration] timeElapsed Time elapsed (if this was an existing timer) 
		//! @param [String] label describing the timer
		//! @param [Boolean] true if the timer should start counting down automatically after initialized
		//! @param [Method] timerFinishedCallback Method to call when the timer finishes (time remaining = 0)
		function initialize(duration, timeElapsed, label, startAutomatically, timerFinishedCallback) {
			self.duration = duration;
			self.timeElapsed = timeElapsed;
			self.label = label;
			self.timerFinishedCallback = timerFinishedCallback;
			
			timeRemaining = duration.subtract(timeElapsed);
			backingTimer = new Timer.Timer();
			logger = Log.getLogger("Timer " + label);
			
			if (startAutomatically) {
				start();
			}
		}
		
		//! @return [Boolean] True if the timer is currently running
		function isRunning() {
			return _isRunning;	
		}		
		
		//! Stop the timer if it's running, start it if it's not
		function startOrStop() {
			if (isRunning()) {
				return stop();
			}
			return start();
		}
		
		//! Start the timer
		hidden function start() {
			if (isRunning()) {
				logger.warn("Start() called when timer is running. No-op");
				return;
			}
			if (timeRemaining.value() <= 0) {
				// No-op
				return;
			}
			logger.info("Starting timer");
			backingTimer.start(method(:updateInternalState), 1000, true); 
			_isRunning = true;
		}
		
		//! Stop the timer
		hidden function stop() {
			if (!isRunning()) {
				logger.warn("Stop() called when timer is stopped. No-op");
				return;
			}
			if (timeRemaining.value() <= 0) {
				// No-op
				return;
			}
			logger.info("Stopping timer");
			backingTimer.stop();
			_isRunning = false;
		}
		
		//! @return [Duration] Time remaining
		function getTimeRemaining() {
			return timeRemaining;
		}
		
		//! @return [Duration] Time elapsed
		function getTimeElapsed() {
			return timeElapsed;
		}
		
		//! @return [Duration] Timer duration
		function getDuration() {
			return duration;
		}
		
		//! Update internal state every second
		//!
		//! This function would ideally be hidden but that would prevent it from being used as a timer callback in Monkey C
		function updateInternalState() {
			timeElapsed = timeElapsed.add(new Time.Duration(1));
			timeRemaining = timeRemaining.subtract(new Time.Duration(1));
			
			logger.info("Time elapsed: " + timeElapsed.value() + "s, Time remaining: " + timeRemaining.value() + "s");
			
			if (timeRemaining.value() <= 0) {
				stop();				
				timerFinishedCallback.invoke(self);
			}
		}
	}
}