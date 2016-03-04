# ABFALL for FHEM
ABFALL is a fhem modul, which creates readings based on one or more calendar devices, based on the fhem modul 57_Calendar

## How to install
The Perl module can be loaded directly into your FHEM installation. For this please copy the below command into the FHEM command line.

	update all https://raw.githubusercontent.com/uniqueck/fhem-abfall/master/controls_fhemabfall.txt 

## How to Update
The Perl module can be update directly with standard fhem update process. For this please copy the below command into the FHEM command line.

	update add https://raw.githubusercontent.com/uniqueck/fhem-abfall/master/controls_fhemabfall.txt

To check if a new version is available execute follow command

	update check fhemabfall

To update to a new version if available execute follow command

	update all

or

	update all fhemabfall