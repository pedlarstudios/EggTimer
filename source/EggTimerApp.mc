using Toybox.Application as App;
using Toybox.Attention as Attn;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;
using Log4MonkeyC as Log;

//! Main application. Creates the initial view and provides some high-level callback methods
class EggTimerApp extends App.AppBase {
	// Using global clock timer to get around Connect IQ issue where "too many timers" exception may be raised incorrectly
	hidden var masterClockTimer;

    //! onStart() is called on application start up
    function onStart() {
    	// SET APPROPRIATELY BEFORE DEPLOYMENT/RELEASE
		var config = new Log4MonkeyC.Config();
		config.setLogLevel(Log.DEBUG);
		Log4MonkeyC.setLogConfig(config);
		masterClockTimer = new Timer.Timer();
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    	// Nothing
    }

    //! Return the initial view of your application here
    function getInitialView() {
    	var manager = new TimerManager(method(:timerStarted), method(:timerStopped), method(:timerFinished));
    	var propertyHandler = new PropertyHandler();
    	var view = new EggTimerView(manager, propertyHandler, masterClockTimer);
        return [ view, new EggTimerDelegate(manager, view, propertyHandler, masterClockTimer) ];
    }
    
    //! Handle when a timer is started in the application
	//!
	//! @param [EggTimer] timer that started
    function timerStarted(timer) {
   		if (Sys.getDeviceSettings().vibrateOn) {			
			Attn.vibrate([ new Attn.VibeProfile(5, 250) ]);
		}
		
		if (Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_START);
		}		
    }
    
    //! Handle when a timer is stopped in the application
	//!
	//! @param [EggTimer] timer that stopped
    function timerStopped(timer) {
    	if (Sys.getDeviceSettings().vibrateOn) {			
			Attn.vibrate([ new Attn.VibeProfile(5, 500) ]);
		}
		
		if (Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_STOP);
		}
    }
    
    //! Handle when a timer is finished in the application
	//!
	//! @param [EggTimer] timer that finished
    function timerFinished(timer) {
    	if (Sys.getDeviceSettings().vibrateOn) {			
			Attn.vibrate([ new Attn.VibeProfile(5, 1000), new Attn.VibeProfile(5, 1000), new Attn.VibeProfile(5, 1000), new Attn.VibeProfile(5, 1000), new Attn.VibeProfile(5, 1000) ]);
		}
		
		if (Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_ALARM);
		}
    }
}

//! Handles user interaction with the timers 
class EggTimerDelegate extends Ui.BehaviorDelegate {
	hidden var manager;
	hidden var view;
	hidden var propertyHandler;
	hidden var masterClockTimer;
	hidden var logger;

	//! Creates a delegate instance
	//!
	//! @param [TimerManager] manager
	//! @param [View] view Main view
	//! @param [PropertyHandler] propertyHandler
	//! @param [Timer] masterClockTimer
	function initialize(manager, view, propertyHandler, masterClockTimer) {
		self.manager = manager;
		self.view = view;
		self.propertyHandler = propertyHandler;
		self.masterClockTimer = masterClockTimer;
		logger = Log.getLogger("EggTimerDelegate");
	}

    //! Handle general hardware key presses
	//!
	//! @param evt
	function onKey(evt) {
		if (Ui.KEY_ENTER == evt.getKey()) {			
			manager.startOrStopSelectedTimer();
			view.requestUpdate();	
		}
		else if (Ui.KEY_ESC == evt.getKey()) {
			// Save current timer preferences
			propertyHandler.storeTimers(manager);
			// Exit application
			Ui.popView(Ui.SLIDE_IMMEDIATE);
		}

		return true;
	}
	
	//! Handle user screen holds
	//!
	//! @param evt
    function onHold(evt) {
    	if (manager.getTimerCount() > 0) {
    		// TODO - Confirmation
    		manager.clearSelectedTimer();
    		showTimerDurationPicker();
    		Ui.requestUpdate();
    	}
		else if (manager.canAddTimer()) {
			showTimerDurationPicker();
    		Ui.requestUpdate();
    	}
        return true;
	}
	
	hidden function showTimerDurationPicker() {
		var defaultDuration = propertyHandler.getLastTimerDuration();
		Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME, defaultDuration), new NewTimerPickerDelegate(manager, propertyHandler), Ui.SLIDE_UP);
		Ui.requestUpdate();
	}
}

class ResetTimerConfirmationDelegate extends Ui.ConfirmationDelegate {
	// TODO - Use to force confirmation when resetting timer
}

//! NumberPickerDelegate used when adding a timer
class NewTimerPickerDelegate extends Ui.NumberPickerDelegate {
	hidden var manager;
	hidden var propertyHandler;

	//! Construct a NewTimerPickerDelegate
	//!
	//! @param [TimerManager] manager
	//! @param [PropertyHandler] propertyHandler
	function initialize(manager, propertyHandler) {
		self.manager = manager;
		self.propertyHandler = propertyHandler;
	}

	//! Handle when the number is picked
	//! 
	//! @param [Duration] value picked
	function onNumberPicked(value) {
		manager.addNewTimer(value);
		propertyHandler.setLastTimerDuration(value);
	}
}