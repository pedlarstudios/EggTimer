using Toybox.Graphics;
using Toybox.WatchUi;

// Copied from Garmin example
class NumberFactory extends WatchUi.PickerFactory {
    hidden var mStart;
    hidden var mStop;
    hidden var mIncrement;
    hidden var mFormatString;
    hidden var mFont;
    hidden var mUnit;

    function getIndex(value) {
        var index = (value / mIncrement) - mStart;
        return index;
    }

    function initialize(start, stop, increment, options) {
        PickerFactory.initialize();

        mStart = start;
        mStop = stop;
        mIncrement = increment;

        if (options != null) {
            mFormatString = options.get(:format);
            mFont = options.get(:font);
            mUnit = options.get(:unit);
            Toybox.System.println("mUnit " + mUnit);
        }

        if (mFont == null) {
            mFont = Graphics.FONT_NUMBER_HOT;
        }

        if (mFormatString == null) {
            mFormatString = "%d";
        }
    }

    function getDrawable(index, selected) {
    	Toybox.System.println("value " + getValue(index));
    	var text = getValue(index).format(mFormatString);
    	if (mUnit != null) {
    		text += " " + mUnit;
    	}
        return new WatchUi.Text( { :text => text, :color=>Graphics.COLOR_WHITE, :font => mFont, :locX => WatchUi.LAYOUT_HALIGN_CENTER, :locY => WatchUi.LAYOUT_VALIGN_CENTER } );
    }

    function getValue(index) {
        return mStart + (index * mIncrement);
    }

    function getSize() {
        return ( mStop - mStart ) / mIncrement + 1;
    }

}
