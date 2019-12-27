using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Cal;
using Toybox.Lang;

//! Log4MonkeyC, a simple Log4MonkeyC framework for the Monkey C programming language
//
// @author Brandon Hawker
//		   bhawkerATgmailDOTcom
//
module Log4MonkeyC {
	// Config keys if initializing using Dictionary
	const LOG_LEVEL_KEY = "logLevel";
	const DATE_FORMAT_KEY = "dateFormat";

	var config;

	//! Build a new [Logger]
	//!
	//! @param [String] loggerName Name of the logger
	function getLogger(loggerName) {
		return new Logger(loggerName, config);
	}

	//! @return [Config] Log configuration for the module
	function getLogConfig() {
		return config;
	}

	//! Set the logging configuration for the module
	//!
	//! @param [Config] config Logging configuration
	function setLogConfig(config) {
		self.config = config;
	}

	//! Holds logging configuration.
	class Config {
		hidden const AVAILABLE_LOG_LEVELS = { ALL => ALL, DEBUG => DEBUG, INFO => INFO, WARN => WARN, ERROR => ERROR, FATAL => FATAL, NONE => NONE };
		hidden const AVAILABLE_DATE_FORMATS = { Time.FORMAT_SHORT => Time.FORMAT_SHORT, Time.FORMAT_MEDIUM => Time.FORMAT_MEDIUM, Time.FORMAT_LONG => Time.FORMAT_LONG };

		hidden var logLevel;
		hidden var dateFormat;

		//! Creates a new Config with default values
		function initialize() {
			setDefaults();
		}

		//! Initializes the Config with the provided settings Dictionary. Defaults are used for any setting that is not present in the Dictionary
		//!
		//! @param [Dictionary] settings
		function init(settings) {
			setDefaults();

			if (settings == null) {
				return;
			}

			if (settings.hasKey(LOG_LEVEL_KEY)) {
				setLogLevel(settings.get(LOG_LEVEL_KEY));
			}
			if (settings.hasKey(DATE_FORMAT_KEY)) {
				setDateFormat(settings.get(DATE_FORMAT_KEY));
			}
		}

		//! @return Log level
		function getLogLevel() {
			return logLevel;
		}

		//! Sets the log level
		//!
		//! @param logLevel
		function setLogLevel(logLevel) {
			if (!AVAILABLE_LOG_LEVELS.hasKey(logLevel)) {
				Sys.println("Provided logLevel '" + logLevel + "' is invalid. Please use one of the following levels: ALL, DEBUG, INFO, WARN, ERROR, FATAL, or NONE");
				return self;
			}

			self.logLevel = logLevel;
			return self;
		}

		//! @return Date format
		function getDateFormat() {
			return dateFormat;
		}

		//! Sets the date format
		//!
		//! @param dateFormat
		function setDateFormat(dateFormat) {
			if (!AVAILABLE_DATE_FORMATS.hasKey(dateFormat)) {
				Sys.println("Provided dateFormat '" + dateFormat + "' is invalid. Please use one of the following formats: 0 (FORMAT_SHORT), 1 (FORMAT_MEDIUM), or 2 (FORMAT_LONG)");
				return self;
			}

			self.dateFormat = dateFormat;
			return self;
		}

		hidden function setDefaults() {
			logLevel = DEBUG;
			dateFormat = Time.FORMAT_SHORT;
		}
	}

	//! Class used for logging nessages based on provided configuration
	class Logger {
		hidden const DEFAULT_ERROR_EXCEPTION_MESSAGE = "An error occurred";
		hidden const DEFAULT_FATAL_EXCEPTION_MESSAGE = "A fatal error occurred";

		hidden var name;
		hidden var config;
		hidden var logLevel;

		//! Creates a [Logger] instance. Use [Log4MonkeyC] factory methods instead of calling this directly.
		//!
		//! @param [String] name Logger name
		//! @param [Config] config Logger configuration
		function initialize(name, config) {
			self.name = name;
			self.config = config;
			self.logLevel = config.getLogLevel();
		}

		//! @return [Boolean] True indicates that Debug messages are enabled
		function isDebugEnabled() {
			return logLevel >= DEBUG;
		}

		//! @return [Boolean] True indicates that Info messages are enabled
		function isInfoEnabled() {
			return logLevel >= INFO;
		}

		//! @return [Boolean] True indicates that Warn messages are enabled
		function isWarnEnabled() {
			return logLevel >= WARN;
		}

		//! @return [Boolean] True indicates that Error messages are enabled
		function isErrorEnabled() {
			return logLevel >= ERROR;
		}

		//! @return [Boolean] True indicates that Fatal messages are enabled
		function isFatalEnabled() {
			return logLevel >= FATAL;
		}

		//! Writes a Debug message if enabled
		//!
		//! @param message [Object] Message to write
		function debug(message) {
			if (isDebugEnabled()) {
				writeMessage(message, "DEBUG");
			}
		}

		//! Writes an Info message if enabled
		//!
		//! @param message [Object] Message to write
		function info(message) {
			if (isInfoEnabled()) {
				writeMessage(message, "INFO");
			}
		}

		//! Writes a Warn message if enabled
		//!
		//! @param message [Object] Message to write
		function warn(message) {
			if (isWarnEnabled()) {
				writeMessage(message, "WARN");
			}
		}

		//! Writes an Error message if enabled
		//!
		//! @param message [Object] Message to write
		function error(message) {
			if (isErrorEnabled()) {
				writeMessage(message, "ERROR");
			}
		}

		//! Writes an Error exception stack trace preceeded by the default identifying message
		//!
		//! @param exception [Exception] Exception to write
		function errorException(exception) {
			if (isErrorEnabled()) {
				writeMessage(DEFAULT_ERROR_EXCEPTION_MESSAGE, "ERROR");
				exception.printStackTrace();
			}
		}

		//! Writes an Error exception stack trace preceeded by the provided identifying message
		//!
		//! @param message [Object] Message to write
		//! @param exception [Exception] Exception to write
		function errorExceptionAndMsg(message, exception) {
			if (isErrorEnabled()) {
				writeMessage(message, "ERROR");
				exception.printStackTrace();
			}
		}

		//! Writes a Fatal message if enabled
		//!
		//! @param message [Object] Message to write
		function fatal(message) {
			if (isFatalEnabled()) {
				writeMessage(message, "FATAL");
			}
		}

		//! Writes a Fatal exception stack trace preceeded by the default identifying message
		//!
		//! @param exception [Exception] Exception to write
		function fatalException(exception) {
			if (isFatalEnabled()) {
				writeMessage(DEFAULT_FATAL_EXCEPTION_MESSAGE, "FATAL");
				exception.printStackTrace();
			}
		}

		//! Writes a Fatal exception stack trace preceeded by the provided identifying message
		//!
		//! @param message [Object] Message to write
		//! @param exception [Exception] Exception to write
		function fatalExceptionAndMsg(message, exception) {
			if (isFatalEnabled()) {
				writeMessage(message, "FATAL");
				exception.printStackTrace();
			}
		}

		hidden function writeMessage(message, logLevelString) {
			if (message == null || message.toString() == "") {
				return;
			}
			var formattedTime = getCurrentTimeFormatted();
			var formattedMessage = "[" + logLevelString + "] " + formattedTime + " | " + name + " | " + message;
			Sys.println(formattedMessage);
		}

		hidden function getCurrentTimeFormatted() {
    		var is24HourTime = Sys.getDeviceSettings().is24Hour;
    		var dateFormat = config.getDateFormat();

    		var timeInfo = Cal.info(Time.now(), dateFormat);
    		var dateString;
    		if (dateFormat == Time.FORMAT_SHORT) {
	    		// TODO - Handle imperial date (date/month/year)?
				dateString = timeInfo.month.format("%02d") + "-" + timeInfo.day.format("%02d") + "-" + timeInfo.year.format("%04d");

    		} else {
    			dateString = timeInfo.month + "-" + timeInfo.day + "-" + timeInfo.year;
    		}

    		var hour = timeInfo.hour;
    		if (!is24HourTime) {
	    		hour = hour % 12;
	    		hour = (hour == 0) ? 12 : hour;
			}
			var min = timeInfo.min;
    		var sec = timeInfo.sec;
    		var timeString = hour.format("%02d") + ":" + min.format("%02d") + ":" + sec.format("%02d");
    		if (!is24HourTime) {
    			timeString += timeInfo.hour < 12 ? " AM" : " PM";
    		}

    		return dateString + " " + timeString;
		}
	}

	//! Log levels ordered by least likely to log to most likely
	enum {
		NONE,
		FATAL,
		ERROR,
		WARN,
		INFO,
		DEBUG,
		ALL
	}
}