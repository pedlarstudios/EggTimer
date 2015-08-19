using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Cal;
using Log4MonkeyC as Log;

//! Main timer UI view
class EggTimerView extends Ui.View {
	hidden const MASTER_TIMER_INCREMENT = 250;	// ms

	hidden var manager;
	hidden var masterClockTimer;
	hidden var masterClockTimerStarted = false;
	hidden var separatorLabel;
	hidden var playIcon;
	hidden var pauseIcon;
	hidden var stopIcon;
	hidden var logger;
	hidden var timerDrawable;

	//! Creates an EggTimerView
	//!
	//! @param [TimerManager] manager
	//! @param [Timer] masterClockTimer
	function initialize(manager, masterClockTimer) {
		self.manager = manager;
		self.masterClockTimer = masterClockTimer;
		separatorLabel = new Rez.Drawables.clockSeparator();
		playIcon = Ui.loadResource(Rez.Drawables.PlayIcon);
		pauseIcon = Ui.loadResource(Rez.Drawables.PauseIcon);
		stopIcon = Ui.loadResource(Rez.Drawables.StopIcon);
		logger = Log.getLogger("EggTimerView");
	}
	
    //! Load resources
	//!
	//! @param [Graphics.dc] dc
    function onLayout(dc) {
    	logger.debug("On layout");
        setLayout(Rez.Layouts.MainLayout(dc));
        separatorLabel.draw(dc);        
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    	logger.debug("On show");
    	updateClockTimeUi();
    	if (!masterClockTimerStarted) {
    		masterClockTimer.start(method(:updateOnTimer), MASTER_TIMER_INCREMENT, true);
    		masterClockTimerStarted = true;
    	}
    	return true;    	
    }

    //! Update the view
	//!
	//! @param [Graphics.dc] dc
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        if (manager.getTimerCount() > 0) {
        	hideHelpText();
        }
        else {
        	showHelpText();
        }
        separatorLabel.draw(dc);
        if (timerDrawable != null) {
        	timerDrawable.draw(dc);
        }
        
        updateTimerStatusIcon(dc); 
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
		logger.debug("On hide");
		masterClockTimerStarted = false;
		masterClockTimer.stop();
    }
    
    //! Callback function for view timer
	//!
	//! This function would ideally be hidden but that would prevent it from being used as a timer callback in Monkey C
    function updateOnTimer() {
		updateTimersUi();     	
    	updateClockTimeUi();
   		Ui.requestUpdate();
    }
    
    hidden function updateTimersUi() {
     	if (manager.getTimerCount() > 0) {
        	// TODO - Eventually support multiple timers
        	var timer = manager.getSelectedTimer();
        	var timeRemainingText = getTimeRemainingFormatted(timer.getTimeRemaining() / 1000);
        	
        	if (timerDrawable == null) {
	    		timerDrawable = buildTimerLabel(timeRemainingText);
        	}
        	else {
        		timerDrawable.setText(timeRemainingText);
        	}
    	}
    	else {
    		timerDrawable = null;
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
	}
	
	hidden function getTimeRemainingFormatted(timeRemainingSeconds) {
		var timeRemainingText;
		// Time Remaining in Hours
		if (timeRemainingSeconds >= Cal.SECONDS_PER_HOUR) {
			var hours = (timeRemainingSeconds / Cal.SECONDS_PER_HOUR).toNumber();
			var minutes = (timeRemainingSeconds % Cal.SECONDS_PER_HOUR / Cal.SECONDS_PER_MINUTE).toNumber();
			var seconds = (timeRemainingSeconds - (hours * Cal.SECONDS_PER_HOUR) - (minutes * Cal.SECONDS_PER_MINUTE)).toNumber();
			
			timeRemainingText = hours.format("%01d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
		}
		// Time Remaining in Minutes or Seconds
		else {
			var minutes = (timeRemainingSeconds / Cal.SECONDS_PER_MINUTE).toNumber();
			var seconds = timeRemainingSeconds % Cal.SECONDS_PER_MINUTE;
			
			timeRemainingText = minutes.format("%01d") + ":" + seconds.format("%02d");
		}
		
		return timeRemainingText;
	}
	
	hidden function buildTimerLabel(text) {
		return new Ui.Text({
        	:locX => 102,
        	:locY => 90,
        	:text => text,
        	:color => Gfx.COLOR_WHITE,
        	:font => Gfx.FONT_NUMBER_THAI_HOT,
        	:justification => Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
    	});
	}

	hidden function hideHelpText() {
		findDrawableById("timerHelp").setText("");
	}
	
	hidden function showHelpText() {
		findDrawableById("timerHelp").setText(Ui.loadResource(Rez.Strings.HelpLabelText));
	}
	
	hidden function updateTimerStatusIcon(dc) {
		if (manager.getTimerCount() > 0) {
			var selectedTimer = manager.getSelectedTimer();
			var icon;
			if (selectedTimer.isFinished()) {
				icon = stopIcon;
			}
			else if (selectedTimer.isRunning()) {
				icon = playIcon;
			}
			else {
				icon = pauseIcon;
			}
			
			dc.drawBitmap(185, 9, icon);
		}
		else {
			// No icon
		}
	}
}
