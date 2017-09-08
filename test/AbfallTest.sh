#! /bin/bash

oneTimeSetUp() {

	sudo service fhem restart
	sleep 5
	# FIXME while loop with status check
	calendarName="AbfallCalAutomatedTests"
	abfallName="AbfallAutomatedTests"

	actualDate=(date +"%Y%-m-%d")
	actualWeekday=(date +"%a")

	local fhemDefineCalendarCommand="define $calendarName Calendar ical url https://calendar.google.com/calendar/ical/s2ukvlseibakhirbetjbfi1rf8%40group.calendar.google.com/private-cc4716aa33964214d31040cd87bfffa5/basic.ics"
	executeFHEMCommandAndSave "$fhemDefineCalendarCommand"
	executeFHEMCommandAndSave "define $abfallName ABFALL $calendarName"
	executeFHEMCommand "set $calendarName update"
	sleep 1
}

oneTimeTearDown() {
	executeFHEMCommandAndSave "delete $abfallName;delete $calendarName"
}



testMondayReadings() {
	# sleep 5
	local readingName="TerminMontag"
	assertReading "Termin Montag" "$abfallName" "${readingName}_text"
	assertReading "Ort Termin Montag" "$abfallName" "${readingName}_location"
	assertReading "Beschreibung Termin Montag" "$abfallName" "${readingName}_description"
	assertReading "$(getExpectedReadingDateForWeekday monday)" "$abfallName" "${readingName}_date"
	assertReading "Montag" "$abfallName" "${readingName}_weekday"
	assertReading "5mgb3090qqvisqkoql01jbi1gogooglecom" "$abfallName" "${readingName}_uid"
	unset readingName
}

testTuesdayReadings() {
	# sleep 5
	local readingName="TerminDienstag"
	assertReading "Termin Dienstag" "$abfallName" "${readingName}_text"
	assertReading "Ort Termin Dienstag" "$abfallName" "${readingName}_location"
	assertReading "Beschreibung Termin Dienstag" "$abfallName" "${readingName}_description"
	assertReading "$(getExpectedReadingDateForWeekday tuesday)" "$abfallName" "${readingName}_date"
	assertReading "Dienstag" "$abfallName" "${readingName}_weekday"
	assertReading "7lc4buknh3b81523akl0ublbt3googlecom" "$abfallName" "${readingName}_uid"
	unset readingName
}

testWednesdayReadings() {
	# sleep 5
	local readingName="TerminMittwoch"
	assertReading "Termin Mittwoch" "$abfallName" "${readingName}_text"
	assertReading "Ort Termin Mittwoch" "$abfallName" "${readingName}_location"
	assertReading "Beschreibung Termin Mittwoch" "$abfallName" "${readingName}_description"
	assertReading "$(getExpectedReadingDateForWeekday wednesday)" "$abfallName" "${readingName}_date"
	assertReading "Mittwoch" "$abfallName" "${readingName}_weekday"
	assertReading "3jfje050j1rig65ds543hc75jagooglecom" "$abfallName" "${readingName}_uid"
	unset readingName
}

testThursdayReadings() {
	# sleep 5
	local readingName="TerminDonnerstag"
	assertReading "Termin Donnerstag" "$abfallName" "${readingName}_text"
	assertReading "Ort Termin Donnerstag" "$abfallName" "${readingName}_location"
	assertReading "Beschreibung Termin Donnerstag" "$abfallName" "${readingName}_description"
	assertReading "$(getExpectedReadingDateForWeekday thursday)" "$abfallName" "${readingName}_date"
	assertReading "Donnerstag" "$abfallName" "${readingName}_weekday"
	assertReading "03rmjjoj30s116nbviaqloo8hrgooglecom" "$abfallName" "${readingName}_uid"
	unset readingName
}

testFridayReadings() {
	# sleep 5
	local readingName="TerminFreitag"
	assertReading "Termin Freitag" "$abfallName" "${readingName}_text"
	assertReading "Ort Termin Freitag" "$abfallName" "${readingName}_location"
	assertReading "Beschreibung Termin Freitag" "$abfallName" "${readingName}_description"
	assertReading "$(getExpectedReadingDateForWeekday friday)" "$abfallName" "${readingName}_date"
	assertReading "Freitag" "$abfallName" "${readingName}_weekday"
	assertReading "6c83vdpb6ic458o9t1bt3shc39googlecom" "$abfallName" "${readingName}_uid"
	unset readingName
}

testNextReadings() {
	# sleep 5
	local actualWeekday=$(date +"%u")
	case "$actualWeekday" in
		1)
		assertReading "Termin Dienstag" "$abfallName" "next_text"
		assertReading "Ort Termin Dienstag" "$abfallName" "next_location"
		assertReading "Beschreibung Termin Dienstag" "$abfallName" "next_description"
		assertReading "$(getExpectedReadingDateForWeekday tuesday)" "$abfallName" "next_date"
		assertReading "Dienstag" "$abfallName" "next_weekday"
		assertReading "1" "$abfallName" "next_days"
		assertReading "TerminDienstag_1" "$abfallName" "next"
		;;
		2)
		assertReading "Termin Mittwoch" "$abfallName" "next_text"
		assertReading "Ort Termin Mittwoch" "$abfallName" "next_location"
		assertReading "Beschreibung Termin Mittwoch" "$abfallName" "next_description"
		assertReading "$(getExpectedReadingDateForWeekday wednesday)" "$abfallName" "next_date"
		assertReading "Mittwoch" "$abfallName" "next_weekday"
		assertReading "1" "$abfallName" "next_days"
		assertReading "TerminMittwoch_1" "$abfallName" "next"
		;;
		3)
		assertReading "Termin Donnerstag" "$abfallName" "next_text"
		assertReading "Ort Termin Donnerstag" "$abfallName" "next_location"
		assertReading "Beschreibung Termin Donnerstag" "$abfallName" "next_description"
		assertReading "$(getExpectedReadingDateForWeekday thursday)" "$abfallName" "next_date"
		assertReading "Donnerstag" "$abfallName" "next_weekday"
		assertReading "1" "$abfallName" "next_days"
		assertReading "TerminDonnerstag_1" "$abfallName" "next"
		;;
		4)
		assertReading "Termin Freitag" "$abfallName" "next_text"
		assertReading "Ort Termin Freitag" "$abfallName" "next_location"
		assertReading "Beschreibung Termin Freitag" "$abfallName" "next_description"
		assertReading "$(getExpectedReadingDateForWeekday friday)" "$abfallName" "next_date"
		assertReading "Freitag" "$abfallName" "next_weekday"
		assertReading "1" "$abfallName" "next_days"
		assertReading "TerminFreitag_1" "$abfallName" "next"
		;;
		5)
		assertReading "Termin Montag" "$abfallName" "next_text"
		assertReading "Ort Termin Montag" "$abfallName" "next_location"
		assertReading "Beschreibung Termin Montag" "$abfallName" "next_description"
		assertReading "$(getExpectedReadingDateForWeekday monday)" "$abfallName" "next_date"
		assertReading "Montag" "$abfallName" "next_weekday"
		assertReading "3" "$abfallName" "next_days"
		assertReading "TerminMontag_3" "$abfallName" "next"
		;;
		6)
		assertReading "Termin Montag" "$abfallName" "next_text"
		assertReading "Ort Termin Montag" "$abfallName" "next_location"
		assertReading "Beschreibung Termin Montag" "$abfallName" "next_description"
		assertReading "$(getExpectedReadingDateForWeekday monday)" "$abfallName" "next_date"
		assertReading "Montag" "$abfallName" "next_weekday"
		assertReading "2" "$abfallName" "next_days"
		assertReading "TerminMontag_2" "$abfallName" "next"
		;;
		7)
		assertReading "Termin Montag" "$abfallName" "next_text"
		assertReading "Ort Termin Montag" "$abfallName" "next_location"
		assertReading "Beschreibung Termin Montag" "$abfallName" "next_description"
		assertReading "$(getExpectedReadingDateForWeekday monday)" "$abfallName" "next_date"
		assertReading "Montag" "$abfallName" "next_weekday"
		assertReading "1" "$abfallName" "next_days"
		assertReading "TerminMontag_1" "$abfallName" "next"
		;;
	esac;


	local readingName="TerminFreitag"
	assertReading "Termin Freitag" "$abfallName" "${readingName}_text"
	assertReading "Ort Termin Freitag" "$abfallName" "${readingName}_location"
	assertReading "Beschreibung Termin Freitag" "$abfallName" "${readingName}_description"
	assertReading "$(getExpectedReadingDateForWeekday friday)" "$abfallName" "${readingName}_date"
	assertReading "Freitag" "$abfallName" "${readingName}_weekday"
	assertReading "6c83vdpb6ic458o9t1bt3shc39googlecom" "$abfallName" "${readingName}_uid"
	unset readingName
}


getExpectedReadingDateForWeekday() {
	local weekday=$(getNummericValueForWeekDay "$1")
	local actualWeekday=$(date +"%u")
	if [ "$weekday" -eq "$actualWeekday" ]; then
		echo $(date -d now +"%d.%m.%Y")
	else
		echo $(date -d "next $1" +"%d.%m.%Y")
	fi
}

getNummericValueForWeekDay() {
	case "$1" in
		("monday") echo "1" ;;
		("tuesday") echo "2" ;;
		("wednesday") echo "3" ;;
		("thursday") echo "4" ;;
		("friday") echo "5" ;;
		("saturday") echo "6" ;;
		("sunday") echo "7" ;;
		(*) echo "-1" ;;
	esac;
}


assertReading() {
	local expectedValue=$1
	# local device=$1
	# local reading=$2
	local actualVal=$(executeFHEMCommand "{ReadingsVal('$2','$3','invalid')}")
	assertEquals "$expectedValue" "$actualVal"
}


getNextDate4Weekday() {
	local nextWeekDay=$1
	echo $(date -d "next $nextWeekDay" +"%d.%m.%Y")
}

executeFHEMCommandAndSave() {
	local value
	local save_command="$1;save"
	value=$(executeFHEMCommand "$save_command")
	assertEquals "Wrote configuration to fhem.cfg" "$value"
	unset value
	unset save_command
}

executeFHEMCommand() {
	# echo $1
	local retValue=$(perl /opt/fhem/fhem.pl 7072 "$1")
	echo $retValue
}


# load shunit2
. ../../../shunit2/source/2.1/src/shunit2
