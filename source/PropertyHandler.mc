using Toybox.Application as App;
using Toybox.Time as Time;
using Log4MonkeyC as Log;

//! Retrieves and stores application properties
class PropertyHandler {
	hidden const LAST_DURATION_KEY = "LastTimerDuration";
	hidden const TIMER_COUNT_KEY = "TimerCount";
	hidden const TIMER_ELAPSED_TIME_KEY = "Timer_ElapsedTime";
	hidden const TIMER_DURATION_KEY = "Timer_Duration";
	hidden const TIMER_RUNNING_KEY = "Timer_Running";
	hidden const SYSTEM_TIME_KEY = "System_Time";

	hidden const CONTINUE_ON_APP_EXIT_KEY = "timerContinuesOnAppClose";

	hidden var logger;

	//! Create a PropertyHandler
	function initialize() {
		logger = Log.getLogger("PropertyHandler");
	}

	//! @return [Duration] The previously used timer duration, or a 0 second Duration if no previous duration found
	function getLastTimerDuration() {
		var duration = App.getApp().getProperty(LAST_DURATION_KEY);
		logger.debug("Last time duration property: " + duration);
		if (duration != null) {
			return new Time.Duration(duration);
		}
		return new Time.Duration(0);
	}

	//! Set the previously used timer duration
	//!
	//! @param [Duration] duration
	function setLastTimerDuration(duration) {
		logger.debug("Setting last time duration property to: " + duration.value());
		App.getApp().setProperty(LAST_DURATION_KEY, duration.value());
	}

	//! Load previously stored timers into the TimerManager
	//!
	//! @param [TimerManager] timerManager
	function loadPreviousTimers(timerManager) {
		var app = App.getApp();
		var timerCount = app.getProperty(TIMER_COUNT_KEY);
		var continueTimer = app.getProperty(CONTINUE_ON_APP_EXIT_KEY);

		timerManager.clearTimers();
		var now = Time.now().value();
		if (timerCount != null) {
			for (var i = 0; i < timerCount; i++) {
				var duration = app.getProperty(TIMER_DURATION_KEY + i.toString());
				if (duration == null) {
					duration = 0;
				}
				var timeElapsed = app.getProperty(TIMER_ELAPSED_TIME_KEY + i.toString());
				var timerWasRunning = app.getProperty(TIMER_RUNNING_KEY + i.toString());
				var systemTime = app.getProperty(SYSTEM_TIME_KEY + i.toString());

				if (continueTimer && timerWasRunning) {
					// If timer continued outside of the app, update timeElapsed appropriately based on system clock time
					if (systemTime != null) {
						var systemTimeDiff = now - systemTime;
						timeElapsed += systemTimeDiff * 1000;
						if (timeElapsed >= duration) {
							timeElapsed = duration;
						}
						logger.debug("Continuing timer, time elapsed: " + timeElapsed);
					}
				} else {
					// If timer was finished, reset it so it can be easily started again
					if (timeElapsed == null || timeElapsed >= duration) {
						timeElapsed = 0;
					}
				}
				logger.debug("Loading previous timer");
				timerManager.addExistingTimer(duration, timeElapsed, continueTimer && timerWasRunning);
			}
		}
		else {
			logger.debug("No previous timers found in properties");
		}
	}

	//! Store timers from the TimerManager
	//!
	//! @param [TimerManager] timerManager
	function storeTimers(timerManager) {
		var app = App.getApp();
		var timerCount = timerManager.getTimerCount();
		var now = Time.now().value();

		logger.debug("Saving " + timerCount + " timer(s)");
		app.setProperty(TIMER_COUNT_KEY, timerCount);

		for (var i = 0; i < timerCount; i++) {
			var timer = timerManager.getTimers()[i];
			logger.debug("--Saving timer " + i);
			logger.debug("----Elapsed: " + timer.getTimeElapsed() + "ms");
			logger.debug("----Duration: " + timer.getDuration() + "ms");
			logger.debug("----Was Running: " + timer.isRunning());
			logger.debug("----Current time (seconds from epoch): " + now);
			app.setProperty(TIMER_ELAPSED_TIME_KEY + i.toString(), timer.getTimeElapsed());
			app.setProperty(TIMER_DURATION_KEY + i.toString(), timer.getDuration());
			app.setProperty(TIMER_RUNNING_KEY + i.toString(), timer.isRunning());
			app.setProperty(SYSTEM_TIME_KEY + i.toString(), now);
		}
	}
}