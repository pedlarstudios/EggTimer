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
	hidden var config;
	
	//! Get a new [Logger]
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
	
	//! Holds logging configuration
	class Config {
		hidden var logLevel = DEBUG;		
		hidden const AVAILABLE_LOG_LEVELS = { ALL => ALL, DEBUG => DEBUG, INFO => INFO, WARN => WARN, ERROR => ERROR, FATAL => FATAL, NONE => NONE };
		
		function initialize() {
			// Nothing
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
				Sys.println("Provided logLevel '" + logLevel + "' is invalid. Please use one of the following logLevels: ALL, DEBUG, INFO, WARN, ERROR, FATAL, or NONE");
				return; 
			}
			
			self.logLevel = logLevel;
		}
	}
	
	//! Class used for logging nessages based on provided configuration
	class Logger {
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
		
		//! Writes a Fatal message if enabled
		//!
		//! @param message [Object] Message to write
		function fatal(message) {
			if (isFatalEnabled()) {
				writeMessage(message, "FATAL");
			}
		}
		
		hidden function writeMessage(message, logLevelString) {			
			if (message == null || message.toString() == "") {
				return;
			}
			var formattedTime = getCurrentTimeFormatted();
			// TODO Handle splitting multiline messages onto new log lines
			var formattedMessage = "[" + logLevelString + "] " + formattedTime + " | " + name + " | " + message;
			Sys.println(formattedMessage);
		}
		
		hidden function getCurrentTimeFormatted() {
    		var is24HourTime = Sys.getDeviceSettings().is24Hour;
    		
    		// TODO - Make time format configurable
    		var timeInfo = Cal.info(Time.now(), Time.FORMAT_SHORT);
    		
    		var hour = timeInfo.hour;
    		if (!is24HourTime) {
	    		hour = hour % 12;
	    		hour = (hour == 0) ? 12 : hour;
			}
    		
    		// TODO - Handle imperial date (date/month/year), display AM/PM for 12 hour time, use format methods
			var dateString = timeInfo.month.format("%02d") + "-" + timeInfo.day.format("%02d") + "-" + timeInfo.year.format("%04d");
			
			var min = timeInfo.min;
    		var sec = timeInfo.sec;	
    		var timeString = hour.format("%02d") + ":" + min.format("%02d") + ":" + sec.format("%02d");
    		if (!is24HourTime) {
    			timeString += timeInfo.hour < 12 ? " AM" : " PM"; 
    		}
			return dateString + " - " + timeString;
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