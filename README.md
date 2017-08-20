# ABFALL for FHEM
ABFALL is a fhem modul, which creates readings based on one or more calendar devices, based on the fhem modul 57_Calendar

## How to install
The Perl module can be loaded directly into your FHEM installation. For this please copy the below command into the FHEM command line.

	update all https://raw.githubusercontent.com/uniqueck/fhem-abfall/master/controls_fhemabfall.txt

### Create a device

	define myABFALL ABFALL <name of a calendar device>

### Attributes

- abfall\_clear\_reading_regex

	regex to delete a part of the summary of an event
- disable

	valid values 0 and 1, set to 1 to disable device

- weekday_mapping

	set a map of names for the weekdays, for example Su Mo Tue Wed Thu Fr Sa
	start with Sunday
	default value is Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag
- calendarname_praefix

	only useful for multiple calendars, add calendar name as preafix on readingname, if you define a new abfall device with only one calendar device,
	it is set to 0
- delimiter\_text_reading

	if more than one event exist on the same day, this is the delimiter to join these events
	only for the readings next_text, next_location, next_description, now_text, now_location and now_description
- delimiter_reading

	same as delimiter_text_reading, but only for the reading next and now
- filter
	include only events, which match these filter condition, the filter condition can be a normale text or regex expression
- enable_counting_pickups

	activate support for counting pickups
- enable_old_readingnames

	add old deprecated german readings, in the future, all readings are english

- date_style

	valid values are date and dateTime, date is the default value
	control the style of all date reading


## How to Update
The Perl module can be update directly with standard fhem update process. For this please copy the below command into the FHEM command line.

	update add https://raw.githubusercontent.com/uniqueck/fhem-abfall/master/controls_fhemabfall.txt

To check if a new version is available execute follow command

	update check fhemabfall

To update to a new version if available execute follow command

	update all

or

	update all fhemabfall
