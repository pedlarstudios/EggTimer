using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Time.Gregorian;

const FACTORY_COUNT_24_HOUR = 3;
const FACTORY_COUNT_12_HOUR = 4;
const MINUTE_FORMAT = "%02d";

class TimePicker extends WatchUi.Picker {

    function initialize(defaultDuration) {

        var title = new WatchUi.Text({:text => "Time", :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        var factories = new [3];
        var hourFactory;
        var numberFactories;
        // hours, minutes, seconds
        factories[0] = new NumberFactory(0, 8, 1, {:unit => "h"});
        factories[1] = new NumberFactory(0, 59, 1, {:unit => "m"});
		factories[2] = new NumberFactory(0, 59, 1, {:unit => "s"});

        /*if(System.getDeviceSettings().is24Hour) {
            factories = new [FACTORY_COUNT_24_HOUR];
            factories[0] = new NumberFactory(0, 23, 1, {});
        }
        else {
            factories = new [FACTORY_COUNT_12_HOUR];
            factories[0] = new NumberFactory(1, 12, 1, {});
            factories[3] = new WordFactory([Rez.Strings.morning,Rez.Strings.afternoon], {});
        }

        factories[1] = new WatchUi.Text({:text=>Rez.Strings.timeSeparator, :font=>Graphics.FONT_MEDIUM, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER, :color=>Graphics.COLOR_WHITE});
        factories[2] = new NumberFactory(0, 59, 1, {:format=>MINUTE_FORMAT});

        var defaults = splitStoredTime(factories.size());
        if(defaults != null) {
            defaults[0] = factories[0].getIndex(defaults[0].toNumber());
            defaults[2] = factories[2].getIndex(defaults[2].toNumber());
            if(defaults.size() == FACTORY_COUNT_12_HOUR) {
                defaults[3] = factories[3].getIndex(defaults[3]);
            }
        }*/

        // TODO split Duration into hours, minutes, seconds
        var defaultDurationValue = defaultDuration.value();
        //if (defaultDurationValue


        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>null});
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    /*function splitStoredTime(arraySize) {
        var storedValue = Application.getApp().getProperty("time");
        var defaults = null;
        var separatorIndex = 0;
        var spaceIndex;

        if(storedValue != null) {
            defaults = new [arraySize];
            // the Drawable does not have a default value
            defaults[1] = null;

            // HH:MIN AM|PM
            separatorIndex = storedValue.find(WatchUi.loadResource(Rez.Strings.timeSeparator));
            if(separatorIndex != null ) {
                defaults[0] = storedValue.substring(0, separatorIndex);
            }
            else {
                defaults = null;
            }
        }

        if(defaults != null) {
            if(arraySize == FACTORY_COUNT_24_HOUR) {
                defaults[2] = storedValue.substring(separatorIndex + 1, storedValue.length());
            }
            else {
                spaceIndex = storedValue.find(" ");
                if(spaceIndex != null) {
                    defaults[2] = storedValue.substring(separatorIndex + 1, spaceIndex);
                    defaults[3] = storedValue.substring(spaceIndex + 1, storedValue.length());
                }
                else {
                    defaults = null;
                }
            }
        }

        return defaults;
    }*/
}

class TimePickerDelegate extends WatchUi.PickerDelegate {
	hidden var manager;
	hidden var propertyHandler;

    function initialize(manager, propertyHandler) {
        PickerDelegate.initialize();
        self.manager = manager;
        self.propertyHandler = propertyHandler;
    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
        /*var time = values[0] + WatchUi.loadResource(Rez.Strings.timeSeparator) + values[2].format(MINUTE_FORMAT);
        if(values.size() == FACTORY_COUNT_12_HOUR) {
            time += " " + WatchUi.loadResource(values[3]);
        }
        Application.getApp().setProperty("time", time);

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);*/

        // TODO convert time to duration
        //manager.addNewTimer(value.value() * 1000);
		//propertyHandler.setLastTimerDuration(value);
    }
}
