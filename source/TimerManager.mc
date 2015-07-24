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
		logger = Log.getLogger("TimerManager");
	}
	
	//! @return [Boolean] True if a timer can be added
	function canAddTimer() {
		return timerCount < MAX_MANAGED_TIMER_COUNT;
	}

	//! Add a timer, selecting it in the process. This timer begins in a stopped state
	//!
	//! @param [Number] duration, in ms
	//! @param [Number] elapsedTime, in ms
	function addTimer(duration, elapsedTime) {
		addTimerHidden(duration, elapsedTime, false);
	}
	
	//! Add a new timer, selecting it in the process, and starting it automatically
	//!
	//! @param [Number] duration, in ms
	function addNewTimer(duration) {
		addTimerHidden(duration, 0, true);
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
		if (selectedTimer != null) {
			selectedTimer.stop();
		}

		// TODO - handle multiple timers
		clearTimers();
	}
	
	//! Clear managed timers
	function clearTimers() {
		// TODO - handle multiple timers
		selectedTimer = null;
		timers = new [ MAX_MANAGED_TIMER_COUNT ];
		timerCount = 0;
	}
	
	//! Select the current timer that will have action taken on it
	//! 
	//! @param [EggTimer] timer to select
	function selectTimer(timer) {
		selectedTimer = timer;
	}
	
	//! Start or stop the selected timer, if one is present, and not finished
	function startOrStopSelectedTimer() {
		if (selectedTimer != null) {
			if (selectedTimer.isFinished()) {
				return;
			}
			
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
		
		logger.debug("Adding timer with duration: " + duration + "ms, elapsed time: " + elapsedTime + "ms");		
		var newTimer = new EggTimer(duration, elapsedTime, timerCount + 1, startAutomatically, timerFinishedCallback);
		timers[timerCount] = newTimer;
		timerCount++;
		selectTimer(newTimer);
		return newTimer;
	}
	
	//! Simple class representing a timer
	class EggTimer {		
		hidden const TIMER_INCREMENT = 100;	// ms
	
		hidden var backingTimer;
		hidden var duration;
		hidden var timeElapsed;
		hidden var label;
		hidden var timeRemaining;
		hidden var logger;
		hidden var timerFinishedCallback;
		hidden var _isRunning = false;	// Monkey C does not presently allow variable names and method names to be the same, hence the underscore
		hidden var _isFinished;
	
		//! Creates an EggTimer instance
		//!
		//! @param [Number] duration Duration of the timer, in ms
		//!	@param [Number] timeElapsed Time elapsed, in ms 
		//! @param [String] label describing the timer
		//! @param [Boolean] true if the timer should start counting down automatically after initialized
		//! @param [Method] timerFinishedCallback Method to call when the timer finishes (time remaining = 0)
		function initialize(duration, timeElapsed, label, startAutomatically, timerFinishedCallback) {
			self.duration = duration;
			self.timeElapsed = timeElapsed;
			self.label = label;
			self.timerFinishedCallback = timerFinishedCallback;
			
			timeRemaining = duration - timeElapsed;
			_isFinished = timeRemaining <= 0;
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
		
		//! @return [Boolean] True if the timer is currently finished (time remaining = 0)
		function isFinished() {
			return _isFinished;
		}		
		
		//! Stop the timer if it's running, start it if it's not
		function startOrStop() {
			if (isRunning()) {
				return stop();
			}
			return start();
		}
		
		//! Start the timer
		function start() {
			if (isRunning()) {
				logger.info("Start() called when timer is running. No-op");
				return;
			}
			
			logger.info("Starting timer");
			backingTimer.start(method(:updateInternalState), TIMER_INCREMENT, true); 
			_isRunning = true;
		}
		
		//! Stop the timer
		function stop() {
			if (!isRunning()) {
				logger.info("Stop() called when timer is stopped. No-op");
				return;
			}

			logger.info("Stopping timer");
			backingTimer.stop();
			_isRunning = false;
		}
		
		//! @return [Number] Time remaining, in ms
		function getTimeRemaining() {
			return timeRemaining;
		}
		
		//! @return [Number] Time elapsed, in ms
		function getTimeElapsed() {
			return timeElapsed;
		}
		
		//! @return [Number] Timer duration, in ms
		function getDuration() {
			return duration;
		}
		
		//! Update internal state every second
		//!
		//! This function would ideally be hidden but that would prevent it from being used as a timer callback in Monkey C
		function updateInternalState() {
			if (finishIfNecessary()) {
				return;
			}
			timeElapsed += TIMER_INCREMENT;
			timeRemaining -= TIMER_INCREMENT; 
			
			logger.info("Time elapsed: " + timeElapsed + "ms, Time remaining: " + timeRemaining + "ms");
			finishIfNecessary();
		}
		
		hidden function finishIfNecessary() {
			if (timeRemaining <= 0 && !_isFinished) {
				stop();				
				_isFinished = true;
				timerFinishedCallback.invoke(self);
				return true;
			}
			return false;
		}
	}
}