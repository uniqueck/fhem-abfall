# ABFALL for FHEM
ABFALL is a fhem modul, which creates readings based on one or more calendar devices, based on the fhem modul 57_Calendar

## How to install
The Perl module can be loaded directly into your FHEM installation. For this please copy the below command into the FHEM command line.

	update all https://raw.githubusercontent.com/uniqueck/fhem-abfall/master/controls_fhemabfall.txt
	
### Create a device
	
	define myABFALL ABFALL <name of a calendar device>
	
### Attributes #
	
- abfall\_clear\_reading_regex

	regex to delete a part of the summary of an event 
- disable	
	
	valid values 0 and 1, set to 1 to disable device
	
- weekday_mapping

	set a map of names for the weekdays, for example Su Mo Tue Wed Thu Fr Sa
 
	start with Sunday
 
	default value is Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag
- calendarname_praefix

	only useful for multiple calendars, add calendar name as preafix on readingname
- delimiter\_text_reading
	
	if events exists on the same day, this is the delimiter to join these events
 	
	only for the readings next_text and now_text 
- delimiter_reading
	
	same as delimiter_text_reading, but only for the reading next and now 

## How to Update
The Perl module can be update directly with standard fhem update process. For this please copy the below command into the FHEM command line.

	update add https://raw.githubusercontent.com/uniqueck/fhem-abfall/master/controls_fhemabfall.txt

To check if a new version is available execute follow command

	update check fhemabfall

To update to a new version if available execute follow command

	update all

or

	update all fhemabfall