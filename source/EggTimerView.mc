using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Cal;
using Log4MonkeyC as Log;

//! Main timer UI view
class EggTimerView extends Ui.View {
	hidden var manager;
	hidden var masterClockTimer;
	hidden var propertyHandler;
	hidden var masterClockTimerStarted = false;
	hidden var separatorLabel;
	hidden var timerHelpLabel;
	hidden var logger;
	hidden var timerDrawables = new [3];

	//! Creates an EggTimerView
	//!
	//! @param [TimerManager] manager
	//! @param [PropertyHandler] propertyHandler
	//! @param [Timer] masterClockTimer
	function initialize(manager, propertyHandler, masterClockTimer) {
		self.manager = manager;
		self.propertyHandler = propertyHandler;
		self.masterClockTimer = masterClockTimer;
		separatorLabel = new Rez.Drawables.clockSeparator();
		logger = Log.getLogger("EggTimerView");
	}
	
    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        self.timerHelpLabel = findDrawableById("timerHelp");
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    	logger.debug("On show");
    	updateClockTimeUi();
    	if (!masterClockTimerStarted) {
    		propertyHandler.loadPreviousTimers(manager);
    		masterClockTimer.start(method(:updateOnTimer), 1000, true);
    		masterClockTimerStarted = true;
    	}
    	return true;    	
    }

    //! Update the view
    function onUpdate(dc) {
    	dc.clear();
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        separatorLabel.draw(dc);
        for (var i = 0; i < timerDrawables.size(); i++) {
        	var timer = timerDrawables[i];
        	if (timer != null) {
        		timer.draw(dc);
        	}
        }
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
		logger.debug("On hide");
    }
    
    function updateOnTimer() {
		updateTimersUi();     	
    	updateClockTimeUi();
    }
    
    hidden function updateTimersUi() {
     	if (manager.getTimerCount() > 0) {
        	hideDrawable(timerHelpLabel);
        	
        	// TODO - Eventually support multiple timers
        	var timer = manager.getSelectedTimer();
        	var timeRemainingText = getTimeRemainingFormatted(timer.getTimeRemaining().value());
        		
    		var timerLabel = new Ui.Text({
            	:locX => 102,
            	:locY => 90,
            	:text => timeRemainingText,
            	:color => Gfx.COLOR_WHITE,
            	:font => Gfx.FONT_NUMBER_THAI_HOT,
            	:justification => Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        	});
        	
    		timerDrawables[0] = timerLabel;
    	}
    }
    
    hidden function updateClockTimeUi() {
    	var currentTimeLabel = findDrawableById("currentTimeLabel");
		var clockTime = Sys.getClockTime();
    	var is24HourTime = Sys.getDeviceSettings().is24Hour;
    	
    	var hour = clockTime.hour;
    	if (!is24HourTime) {
    		hour = hour % 12;
    		hour = (hour == 0) ? 12 : hour;
		}
		    	
    	var min = clockTime.min;
    	var sec = clockTime.sec;	
    	var timeText = hour.format("%01d") + ":" + min.format("%02d") + ":" + sec.format("%02d");
    	if (!is24HourTime) {
    		timeText += clockTime.hour < 12 ? " AM" : " PM"; 
    	}
    	currentTimeLabel.setText(timeText);
    	
    	Ui.requestUpdate();
	}
	
	hidden function getTimeRemainingFormatted(timeRemainingSeconds) {
		var timeRemainingText;
		// Hours
		if (timeRemainingSeconds >= Cal.SECONDS_PER_HOUR) {
			var hours = (timeRemainingSeconds / Cal.SECONDS_PER_HOUR).toNumber();
			var minutes = (timeRemainingSeconds % Cal.SECONDS_PER_HOUR / Cal.SECONDS_PER_MINUTE).toNumber();
			var seconds = (timeRemainingSeconds - (hours * Cal.SECONDS_PER_HOUR) - (minutes * Cal.SECONDS_PER_MINUTE)).toNumber();
			
			timeRemainingText = hours.format("%01d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
		}
		// Minutes
		else {
			var minutes = (timeRemainingSeconds / Cal.SECONDS_PER_MINUTE).toNumber();
			var seconds = timeRemainingSeconds % Cal.SECONDS_PER_MINUTE;
			
			timeRemainingText = minutes.format("%01d") + ":" + seconds.format("%02d");
		}
		
		return timeRemainingText;
	}
	
	//! Temporary hack
	hidden function hideDrawable(drawable) {
		drawable.setLocation(-1000, -1000);
	}

}
