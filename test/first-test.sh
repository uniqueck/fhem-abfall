#! /bin/bash

oneTimeSetUp() {
	# sudo service fhem restart
	sleep 5
	# FIXME while loop with status check
	# perl /opt/fhem/fhem.pl 7072 "list CalTrinitywhm"
}


testEquality() {
	executeFHEMCommand "set CalTrinitywhm update"
	# sleep 5
	# executeFHEMCommand "list AbfallTrinitywhm"
	assertEquals 1 1
	assertReading "Mülleimer rausbringen und Boden saugen und Staub wischen" "AbfallTrinitywhm" "next_text"
}

assertReading() {
	local expectedValue=$1
	# local device=$1
	# local reading=$2
	local actualVal=$(executeFHEMCommand "{ReadingsVal('$2','$3','invalid')}")
	assertEquals "$expectedValue" "$actualVal"
}

executeFHEMCommand() {
	# echo $1
	local retValue=$(perl /opt/fhem/fhem.pl 7072 "$1")
	echo $retValue
}


# load shunit2
. ../../../shunit2/source/2.1/src/shunit2
