using Toybox.Application as App;
using Toybox.Attention as Attn;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;
using Log4MonkeyC as Log;

//! Main application. Creates the initial view and provides some high-level callback methods related to user attention
class EggTimerApp extends App.AppBase {
	hidden const VIBRATE_DUTY_CYCLE = 100; // Max vibration frequency/strength
	// Using global clock timer to get around Connect IQ issue where "too many timers" exception may be raised incorrectly
	hidden var masterClockTimer;

    //! onStart() is called on application start up
    function onStart() {
    	// SET APPROPRIATELY BEFORE DEPLOYMENT/RELEASE
		var config = new Log4MonkeyC.Config();
		config.setLogLevel(Log.WARN);
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
    	var view = new EggTimerView(manager, masterClockTimer);
    	var propertyHandler = new PropertyHandler();
    	propertyHandler.loadPreviousTimers(manager);
        return [ view, new EggTimerDelegate(manager, propertyHandler, masterClockTimer) ];
    }
    
    //! Handle when a timer is started in the application
	//!
	//! @param [EggTimer] timer that started
    function timerStarted(timer) {
   		if (Sys.getDeviceSettings().vibrateOn) {			
			Attn.vibrate([ new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 250) ]);
		}
		
		// Not actually applicable on Vivoactive, just adding in case of additional device support
		if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_START);
		}		
    }
    
    //! Handle when a timer is stopped in the application
	//!
	//! @param [EggTimer] timer that stopped
    function timerStopped(timer) {
    	if (Sys.getDeviceSettings().vibrateOn) {			
			Attn.vibrate([ new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 500) ]);
		}
		
		// Not actually applicable on Vivoactive, just adding in case of additional device support
		if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_STOP);
		}
    }
    
    //! Handle when a timer is finished in the application
	//!
	//! @param [EggTimer] timer that finished
    function timerFinished(timer) {
    	if (Sys.getDeviceSettings().vibrateOn) {			
			Attn.vibrate([ new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 1000), new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 1000), new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 1000), new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 1000), new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 1000) ]);
		}
		
		if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_ALARM);
		}
    }
}

//! Handles user interaction with the timers 
class EggTimerDelegate extends Ui.BehaviorDelegate {
	hidden var manager;
	hidden var propertyHandler;
	hidden var masterClockTimer;
	hidden var logger;

	//! Creates a delegate instance
	//!
	//! @param [TimerManager] manager
	//! @param [PropertyHandler] propertyHandler
	//! @param [Timer] masterClockTimer
	function initialize(manager, propertyHandler, masterClockTimer) {
		self.manager = manager;
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
		}
		else if (Ui.KEY_ESC == evt.getKey()) {
			propertyHandler.storeTimers(manager);
			// Exit application
			Ui.popView(Ui.SLIDE_IMMEDIATE);
		}

		return true;
	}
	
	//! Specifically handles the menu key press
    function onMenu() {
    	if (manager.getTimerCount() > 0) {
			var confirmation = new Ui.Confirmation(Ui.loadResource(Rez.Strings.ClearTimerText));
			Ui.pushView(confirmation, new ConfirmationDelegateWithCallback(method(:clearSelectedTimer)), Ui.SLIDE_IMMEDIATE);
    	}
		else if (manager.canAddTimer()) {			
			showTimerDurationPicker();
    	}
        return true;
	}
	
	//! Clear the selected timer and show the timer duration picker
	function clearSelectedTimer() {
		manager.clearSelectedTimer();
		showTimerDurationPicker();
	}
	
	hidden function showTimerDurationPicker() {
		var defaultDuration = propertyHandler.getLastTimerDuration();
		Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME, defaultDuration), new NewTimerPickerDelegate(manager, propertyHandler), Ui.SLIDE_IMMEDIATE);
	}
}

//! ConfirmationDelegate that invokes a callback method when the response is Yes
class ConfirmationDelegateWithCallback extends Ui.ConfirmationDelegate {
	hidden var callbackMethod;

	//! Creates a ConfirmationDelegateWithCallback
	//!
	//! @param [Method] callbackMethod to invoke if Yes is the response
	function initialize(callbackMethod) {
		self.callbackMethod = callbackMethod;
	}
	
	//! When a response is chosen, onResponse() is called, passing the response of CONFIRM_NO or CONFIRM_YES.
	//!
	//! @param [Object] response
	function onResponse(response) {
		if (response == Ui.CONFIRM_YES) {
			callbackMethod.invoke();
		}
		
		return true;
	}
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
		manager.addNewTimer(value.value() * 1000);
		propertyHandler.setLastTimerDuration(value);
	}
}