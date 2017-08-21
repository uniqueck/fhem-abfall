# $Id: 57_ABFALL.pm 11019 2017-07-26 23:07:00Z uniqueck $
###########################
#	ABFALL
#
#	needs a defined Device 57_Calendar
###########################
package main;

use strict;
use warnings;
use POSIX;
use Time::Local;
use Time::Piece;

sub ABFALL_Initialize($)
{
	my ($hash) = @_;

	$hash->{DefFn}   = "ABFALL_Define";
	$hash->{UndefFn} = "ABFALL_Undef";
	$hash->{SetFn}   = "ABFALL_Set";
	$hash->{AttrFn}   = "ABFALL_Attr";
	$hash->{NotifyFn}   = "ABFALL_Notify";

	$hash->{AttrList} = "abfall_clear_reading_regex "
		."disable:0,1 "
		."weekday_mapping calendarname_praefix:1,0 "
		."delimiter_text_reading "
		."delimiter_reading "
		."filter "
		."enable_counting_pickups:0,1 "
		."enable_old_readingnames:0,1 "
		."date_style:date,dateTime "
		.$readingFnAttributes;
}

sub ABFALL_Define($$){
	my ( $hash, $def ) = @_;
	my @a = split( "[ \t][ \t]*", $def );
	return "\"set ABFALL\" needs at least an argument" if ( @a < 3 );
	my $name = $a[0];

	my @calendars = split( ",", $a[2] );

	foreach my $calender (@calendars)
	{
		return "invalid Calendername \"$calender\", define it first" if((devspec2array("NAME=$calender")) != 1 );
	}
	$hash->{KALENDER} 	= $a[2];
  $hash->{NOTIFYDEV}	= $a[2];
	$hash->{NAME} 	= $name;
	$hash->{STATE}	= "Initialized";

	# prüfen, ob eine neue Definition angelegt wird
	if($init_done && !defined($hash->{OLDDEF}))
	{
		# set default stateFormat
		$attr{$name}{"stateFormat"} = "next_text in next_days Tag(en)";
		# set calendarname_praefix
		$attr{$name}{"calendarname_praefix"} = "0" if(@calendars == 1);
		# set default weekday_mapping
		$attr{$name}{"weekday_mapping"} = "Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag";
		# set default delimiter_text_reading
		$attr{$name}{"delimiter_text_reading"} = " und ";
		# set default delimiter_reading
		$attr{$name}{"delimiter_reading"} = "|";
		# set default date_style
		$attr{$name}{"date_style"} = "date";
	}
	InternalTimer(gettimeofday()+2, "ABFALL_GetUpdate", $hash, 0);
	return undef;
}

sub ABFALL_Undef($$){
	my ( $hash, $arg ) = @_;
	RemoveInternalTimer($hash);
	return undef;
}

sub ABFALL_Set($@){

	my ($hash, $name, $cmd, @val) = @_;
	my $arg = join("", @val);
	my $list = "";
	my $result = undef;
	$list .= "update:noArg" if($hash->{STATE} ne 'disabled');
	$list .= " clear:noArg count" if(AttrVal($name, "enable_counting_pickups","0"));

	if ($cmd eq "update") {
		ABFALL_GetUpdate($hash);
	} elsif ($cmd eq "count") {
		$result = ABFALL_Count($hash, $arg);
	} elsif ($cmd eq "clear") {
		ABFALL_Clear($hash);
	} else {
		$result = "ABFALL_Set ($name) - Unknown argument $cmd or wrong parameter(s), choose one of $list";
	}
	return $result;
}

sub ABFALL_Clear($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	fhem("deletereading $name .*_pickups", 1);
	fhem("deletereading $name .*_pickups_used", 1);
}


sub ABFALL_Count($$){
	my ($hash, $abfallArt) = @_;
	my $name = $hash->{NAME};
	my $result = undef;
	my $waste_pickup_used = ReadingsVal($name, $abfallArt . "_pickups_used", "-1");
	Log3 $name, 5, "ABFALL_Count $abfallArt: looking for reading \"$abfallArt"."_pickups_used\" = $waste_pickup_used";
	if ($waste_pickup_used eq "-1") {
		$result = "\"set $name count $abfallArt\" : unknown waste type $abfallArt";
	} else {
		$waste_pickup_used = $waste_pickup_used + 1;
		readingsSingleUpdate($hash, $abfallArt ."_pickups_used", $waste_pickup_used, "0");
	}
	return $result;
}

sub ABFALL_GetUpdate($){
	my ($hash) = @_;
	my $name = $hash->{NAME};
	Log3 $name, 3, "ABFALL_UPDATE";

	my $enable_counting_pickups = AttrVal($name, "enable_counting_pickups", "0");
	my $enable_old_readingnames = AttrVal($name, "enable_old_readingnames", "0");

	my $lastNow = ReadingsVal($name, "now", "");
	Log3 $name, 5, "ABFALL_GetUpdate ($name) - reading lastNow $lastNow";

	Log3 $name, 5, "ABFALL_GetUpdate ($name) - delete readings";
	fhem("deletereading $name next", 1);
	fhem("deletereading $name now", 1);
	fhem("deletereading $name .*_tage", 1);
	fhem("deletereading $name .*_days", 1);
	fhem("deletereading $name .*_wochentag", 1);
	fhem("deletereading $name .*_weekday", 1);
	fhem("deletereading $name .*_text", 1);
	fhem("deletereading $name .*_datum", 1);
	fhem("deletereading $name .*_date", 1);
	fhem("deletereading $name .*_location", 1);
	fhem("deletereading $name .*_description", 1);
	fhem("deletereading $name state", 1);


	fhem("deletereading $name .*_pickups", 1) if (!$enable_counting_pickups);
	fhem("deletereading $name .*_pickups_used", 1) if (!$enable_counting_pickups);
	fhem("deletereading $name .*_abholungen", 1) if (!$enable_counting_pickups);
	fhem("deletereading $name .*_abholungen_genutzt", 1) if (!$enable_counting_pickups);

	Log3 $name, 5, "ABFALL_GetUpdate ($name) - readings deleted";


	my $counter = 1;
	my $samedatecounter = 2;
	my $lastterm;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900; $mon += 1;
	my $date = sprintf('%02d.%02d.%04d', $mday, $mon, $year);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + 86400);
	$year += 1900; $mon += 1;
	my $datenext = sprintf('%02d.%02d.%04d', $mday, $mon, $year);

	my $delimiter_text_reading = " " . AttrVal($name,"delimiter_text_reading","und") . " ";
	my $delimiter_reading = AttrVal($name,"delimiter_reading","|");

	my $nowAbfall_tage = -1;
	my $nowAbfall_text = "";
	my $nowAbfall_location = "";
	my $nowAbfall_description = "";
	my $nowAbfall_datum;
	my $nowAbfall_weekday;
	my $now_readingTermin = "";


	my $nextAbfall_tage = -1;
	my $nextAbfall_text = "";
	my $nextAbfall_location = "";
	my $nextAbfall_description = "";
	my $nextAbfall_datum;
	my $nextAbfall_weekday;
	my $next_readingTermin = "";


	readingsBeginUpdate($hash); #start update
	my @events =  getEvents($hash);

	foreach my $event (@events) {
		my $readingTermin = $event->{readingName};
		Log3 $name, 5, "ABFALL_GetUpdate ($name) - $readingTermin";

		if ($event->{days} == 0) {
			if($nowAbfall_text eq "") {
				$nowAbfall_text = $event->{summary};
			} else {
				$nowAbfall_text .= $delimiter_text_reading . $event->{summary};
			}
			# check if location reading is the same
			if($nowAbfall_location eq "") {
				$nowAbfall_location = $event->{location};
			} elsif ($nowAbfall_location ne $event->{location}) {
				# TODO change check to regex expression contains
				$nowAbfall_location .= $delimiter_text_reading . $event->{location};
			}
			# check if description reading is the same
			if($nowAbfall_description eq "") {
				$nowAbfall_description = $event->{description};
			} elsif ($nowAbfall_description ne $event->{description}) {
				# TODO change check to regex expression contains
				$nowAbfall_description .= $delimiter_text_reading . $event->{description};
			}
			$nowAbfall_tage = $event->{days};
			$nowAbfall_datum = $event->{dateFormatted};
			$nowAbfall_weekday = $event->{weekday};
			$now_readingTermin = $readingTermin;
		} elsif	($nextAbfall_tage == -1 || $nextAbfall_tage > $event->{days} || $nextAbfall_tage == $event->{days} ) {
			if ($nextAbfall_text eq "") {
				$nextAbfall_text = $event->{summary};
			} else {
				$nextAbfall_text .= $delimiter_text_reading . $event->{summary};
			}
			# check if location reading is the same
			if ($nextAbfall_location eq "") {
				$nextAbfall_location = $event->{location};
			} else {
				# TODO check if nextAbfall_location contains $event->{location}
				$nextAbfall_location .= $delimiter_text_reading . $event->{location};
			}
			# check if description reading is the same
			if ($nextAbfall_description eq "") {
				$nextAbfall_description = $event->{description};
			} else {
				# TODO check if nextAbfall_location contains $event->{location}
				$nextAbfall_description .= $delimiter_text_reading . $event->{description};
			}
			$nextAbfall_tage = $event->{days};
			$nextAbfall_datum = $event->{dateFormatted};
			$nextAbfall_weekday = $event->{weekday};
			if ($next_readingTermin eq "") {
				$next_readingTermin = $readingTermin;
			} else {
				$next_readingTermin .= $delimiter_reading . $readingTermin;
			}
		}

		if ($enable_counting_pickups) {
			my $readingTermin_pickup_count = ReadingsVal($name, $readingTermin . "_pickups", "-1");
			my $readingTermin_pickup_used = ReadingsVal($name, $readingTermin . "_pickups_used", "-1");

			readingsBulkUpdate($hash, $readingTermin ."_pickups", "0") if ($readingTermin_pickup_count == -1);
			readingsBulkUpdate($hash, $readingTermin ."_pickups_used", "0") if ($readingTermin_pickup_used == -1);
		}


		readingsBulkUpdate($hash, $readingTermin ."_tage", $event->{days}) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, $readingTermin ."_days", $event->{days});
		readingsBulkUpdate($hash, $readingTermin ."_text", $event->{summary});
		readingsBulkUpdate($hash, $readingTermin ."_datum", $event->{dateFormatted}) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, $readingTermin ."_date", $event->{dateFormatted});
		readingsBulkUpdate($hash, $readingTermin ."_wochentag", $event->{weekday}) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, $readingTermin ."_weekday", $event->{weekday});
		readingsBulkUpdate($hash, $readingTermin ."_location", $event->{location});
		readingsBulkUpdate($hash, $readingTermin ."_description", $event->{description});

	} # end for events

	if ($nowAbfall_tage == 0) {
		readingsBulkUpdate($hash, "now", $now_readingTermin);
		readingsBulkUpdate($hash, "now_text", $nowAbfall_text);
		readingsBulkUpdate($hash, "now_datum", $nowAbfall_datum) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, "now_date", $nowAbfall_datum);
		readingsBulkUpdate($hash, "now_wochentag", $nowAbfall_weekday) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, "now_weekday", $nowAbfall_weekday);
		readingsBulkUpdate($hash, "now_location", $nowAbfall_location);
		readingsBulkUpdate($hash, "now_description", $nowAbfall_description);

		if ($lastNow ne $now_readingTermin && $enable_counting_pickups) {
			# FIXME if more than one pickup today, split readingTermin with delimiter_text_reading
			Log3 $name, 4, "ABFALL_Update ($name) - inc count for pickups for $now_readingTermin";
			my $now_readingTermin_count =  ReadingsVal($hash, $now_readingTermin . "_pickups", "0");
			$now_readingTermin_count = $now_readingTermin_count + 1;
			readingsBulkUpdate($hash, $now_readingTermin . "_pickups", $now_readingTermin_count);
		}
	}

	if ($nextAbfall_tage > -1) {
		if ($next_readingTermin ne "") {
			 $next_readingTermin .= "_" .  $nextAbfall_tage
		}
		readingsBulkUpdate($hash, "next", $next_readingTermin);
		readingsBulkUpdate($hash, "next_tage", $nextAbfall_tage) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, "next_days", $nextAbfall_tage);
		readingsBulkUpdate($hash, "next_text", $nextAbfall_text);
		readingsBulkUpdate($hash, "next_datum", $nextAbfall_datum) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, "next_date", $nextAbfall_datum);
		readingsBulkUpdate($hash, "next_wochentag", $nextAbfall_weekday) if ($enable_old_readingnames);
		readingsBulkUpdate($hash, "next_weekday", $nextAbfall_weekday);
		readingsBulkUpdate($hash, "next_location", $nextAbfall_location);
		readingsBulkUpdate($hash, "next_description", $nextAbfall_description);

		readingsBulkUpdate($hash, "state", $nextAbfall_tage);
	} else {
		readingsBulkUpdate($hash, "state", "Keine Abholungen");
	}

	readingsEndUpdate($hash,1); #end update
}
sub ABFALL_Attr(@) {
	my ($cmd,$name,$attrName,$attrVal) = @_;
	my $hash = $defs{$name};

	if ($cmd eq "set") {
		if ($attrName eq "weekday_mapping") {
			my @weekdayMappingSplitted = split( "\ ", $attrVal );
			if (int(@weekdayMappingSplitted) != 7) {
				Log3 $name, 4, "ABFALL_Attr ($name) - $attrVal is a wrong weekday_mapping format";
				return ("ABFALL_Attr: $attrVal is a wrong mapping format. Format is a array like this So Mo Di Mi Do Fr Sa");
			}
		} elsif ($attrName eq "abfall_clear_reading_regex") {
			eval { qr/$attrVal/ };
			if ($@) {
				Log3 $name, 4, "ABFALL_Attr ($name) - $attrVal invalid regex: $@";
				return "ABFALL_Attr ($name) - $attrVal invalid regex";
			}
		}

	}


	return undef;
}


sub ABFALL_Notify($$)
{
  my ($own_hash, $dev_hash) = @_;
  my $ownName = $own_hash->{NAME}; # own name / hash

  return "" if(IsDisabled($ownName)); # Return without any further action if the module is disabled

  my $devName = $dev_hash->{NAME}; # Device that created the events
  Log3 $ownName, 5,  "ABFALL_Notify($ownName) - Device: " . $devName;

  my @calendernamen = split( ",", $own_hash->{KALENDER});

  foreach my $calendar (@calendernamen){
		if ($devName eq $calendar) {
			foreach my $event (@{$dev_hash->{CHANGED}}) {
				if ($event eq "triggered") {
					Log3 $ownName , 3,  "ABFALL $ownName - CALENDAR:$devName triggered, updating ABFALL $ownName ...";
					ABFALL_GetUpdate($own_hash);
				}
			}
		}
  }
  return undef;
}



# lese alle Termine von allen Kalendern und gebe sie in einer Liste zurück
sub getEvents($){
	my ($hash) = @_;
	my @terminliste ;
	my $name = $hash->{NAME};
	my @calendernamen = split( ",", $hash->{KALENDER});

	my $cleanReadingRegex = AttrVal($name,"abfall_clear_reading_regex","");
	my $calendarNamePraefix = AttrVal($name,"calendarname_praefix","1");

	my %replacement = ("ä" => "ae", "Ä" => "Ae", "ü" => "ue", "Ü" => "Ue", "ö" => "oe", "Ö" => "Oe", "ß" => "ss" );
	my $replacementKeys= join ("|", keys(%replacement));

	my $wdMapping = AttrVal($name,"weekday_mapping","Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag");
	my $date_style = AttrVal($name, "date_style","date");
	my @days = split("\ ", $wdMapping);
	Log3 $name, 5,  "getEvents($name) - weekDayMapping ($wdMapping)" ;

	foreach my $calendername (@calendernamen){

		my $all = CallFn($calendername, "GetFn", $defs{$calendername},(" ","uid", "next"));
		my @termine=split(/\n/,$all);
		my $now_time = localtime();

		foreach my $uid (@termine){
			# get all information for one uid
			my @starts = split(/\n/,CallFn($calendername, "GetFn", $defs{$calendername},(" ","start", $uid)));

			my @summarys = split(/\n/,CallFn($calendername, "GetFn", $defs{$calendername},(" ","summary", $uid)));

			my @locations = split(/\n/, CallFn($calendername, "GetFn", $defs{$calendername},(" ","location", $uid)));

			my @descriptions = split(/\n/, CallFn($calendername, "GetFn", $defs{$calendername},(" ","description", $uid)));

			# next if (not (scalar(@starts) eq scalar(@summarys) eq scalar(@locations) eq scalar(@descriptions)));

			for(my $i = 0; $i <= scalar(@starts); $i++) {
				next if (not defined($starts[$i]));
				next if ($starts[$i] eq '');
				Log3 $name, 5, "getEvents($name) -  calendar($calendername) - uid($uid) - start($starts[$i])";

				# skip events in the past
				my @SplitDt = split(/ /,$starts[$i]);
				my @SplitDate = split(/\./,$SplitDt[0]);
				my @SplitTime = split(/\:/,$SplitDt[1]);
				my $eventDate = timelocal($SplitTime[2],$SplitTime[1],$SplitTime[0],$SplitDate[0],$SplitDate[1]-1,$SplitDate[2]);
				my $eventDateFormatted = $SplitDt[0];
				if ($date_style eq "dateTime") {
					$eventDateFormatted = $SplitDt[0] . " " . $SplitDt[1];
				}

				my $dayDiff = floor(($eventDate - time) / 60 / 60 / 24 + 1);
				next if ($dayDiff < 0);

				my $eventText = $summarys[$i];
				# skip events of filter conditions
				next if (skipEvent($hash, $eventText));

				# cleanup summary of event
				if ($cleanReadingRegex){
					$eventText =~ s/$cleanReadingRegex//g;
				}
				my $cleanReadingName = $eventText;
				# should add praefix from calendar
				if ($calendarNamePraefix) {
					$cleanReadingName = $calendername . "_" . $cleanReadingName;
				}

				# prepare reading name from summary of event
				$cleanReadingName =~ s/($replacementKeys)/$replacement{$1}/eg;
				$cleanReadingName =~ tr/a-zA-Z0-9\-_//dc;

				Log3 $name, 5, "$SplitDt[0]";
				my $weekday = (localtime($eventDate))[6];
				my $wdayname = $days[$weekday];


				my $eventLocation = $locations[$i];
				my $eventDescription = $descriptions[$i];

				if (not defined($eventLocation)) {
					$eventLocation = "";
				}
				if (not defined($eventDescription)) {
					$eventDescription = "";
				}

				Log3 $name, 5,  "getEvents($name) - calendar($calendername) - uid($uid) -start($starts[$i]) - text($eventText) - location($eventLocation) - description($eventDescription)";


				my $foundItem = ();
				foreach my $item (@terminliste ){
					my $tempText= $item->{summary};
					my $tempCalName= $item->{calendar};
					if ($tempText eq $eventText && $tempCalName eq $calendername) {
						$foundItem = $item;
					}
					last if ($foundItem);
				}

				if ($foundItem) {
					Log3 $name, 5, "getEvents($name) - calendar($calendername) - " . $foundItem->{summary} . " - allready exists!";
					if ($eventDate < $foundItem->{date} && $eventDate > time) {
						Log3 $name, 5, "getEvents($name) - calendar($calendername) - change - " . $foundItem->{start} ." to " . $starts[$i];
						$foundItem->{uid} = $uid;
						$foundItem->{start} = $starts[$i];
						$foundItem->{weekday} = $wdayname;
						$foundItem->{location} = $eventLocation;
						$foundItem->{description} = $eventDescription;
						$foundItem->{date} = $eventDate;
						$foundItem->{dateFormatted} = $eventDateFormatted;
						$foundItem->{days} = $dayDiff;
					}
				} else {
					$eventText =~ s/\\,/,/g;
					$cleanReadingName =~ s/\\,/,/g;
					push @terminliste, {
						uid => $uid,
						start => $starts[$i],
						weekday => $wdayname,
						summary => $eventText,
						location => $eventLocation,
						description => $eventDescription,
						readingName => $cleanReadingName,
						date => $eventDate,
						days => $dayDiff,
						calendar => $calendername,
						dateFormatted => $eventDateFormatted};
				}
			}
		} # end for each uid
	} # end for each calendar
	return @terminliste;
} # end sub getEvents


sub skipEvent($@) {
	my ($hash, @val) = @_;
	my $event = join(' ', @val);
	my $name = $hash->{NAME};
	my $skip = 0;
	my $filter = AttrVal($name,"filter","");

	if ($filter ne "") {
		# skip event of filter conditions - start
		my @filterArray=split( ',' ,$filter);
		foreach my $eachFilter (@filterArray) {
			# fix from fhem forum user justme1968 to support regex for filter
			if ($eachFilter =~ m'^/(.*)/$' && $event =~ m/$1/ ) {
				$skip = 1;
			} elsif (index($event, $eachFilter) != -1) {
				$skip = 1;
			}
		} # end foreach
	} # end if filter
	# skip event of filter conditions - end
	Log3 $name, 5, "skipEvent($name) - $event" if ($skip);
	return $skip;
} # end skipEvent




1;
=pod

=begin html

<a name="ABFALL"></a>
<h3>ABFALL</h3>
<ul>This module creates a device with deadlines based on a calendar-device of the 57_Calendar.pm module. You need to install the  perl-modul Date::Parse!</ul>
<b>Define</b>
<ul><code>define &lt;Name&gt; ABFALL &lt;calendarname&gt; &lt;updateintervall in sec (default 43200)&gt;</code></ul><br>
<ul><code>define myAbfall ABFALL Googlecalendar 3600</code></ul><br>
<a name="ABFALL set"></a>
<b>Set</b>
<ul>update readings:</ul>
<ul><code>set &lt;Name&gt; update</code></ul>
<ul><code>set myAbfall update</code></ul><br>
<a name="ABFALLattr"></a>
	<b>Attributes</b><br><br>
	<ul>
		<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
		<br>
		<li><b>abfall_clear_reading_regex</b></li>
			regex to remove part of the summary text<br>
		<li><b>weekday_mapping</b></li>
			mapping for the days of week<br>
		<li><b>calendarname_praefix </b></li>
			add calendar name as praefix for reading<br>
		<li><b>delimiter_text_reading </b></li>
			delimiter for join events on same day for readings now_text and next_text<br>
		<li><b>delimiter_reading </b></li>
			delimiter for join reading name on readings now and next<br>
		<li><b>filter </b></li>
			filter to keep events, possible values regex or string with event name parts<br>
	</ul>
=end html

=begin html_DE

<a name="ABFALL"></a>
<h3>ABFALL</h3>
<ul>Dieses Modul erstellt ein Device welches als Readings Termine eines Kalender, basierend auf dem 57_Calendar.pm Modul, besitzt. Ihr müsst das Perl-Modul Date::Parse installieren!</ul>
<b>Define</b>
<ul><code>define &lt;Name&gt; ABFALL &lt;Kalendername&gt; &lt;updateintervall in sek (default 43200)&gt;</code></ul><br>
<ul><code>define myAbfall ABFALL Googlekalender 3600</code></ul><br>
<a name="ABFALL set"></a>
<b>Set</b>
<ul>update readings:</ul>
<ul><code>set &lt;Name&gt; update</code></ul>
<ul><code>set myAbfall update</code></ul><br>
<a name="ABFALLattr"></a>
	<b>Attributes</b><br><br>
	<ul>
		<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
		<br>
		<li><b>abfall_clear_reading_regex</b></li>
			regulärer Ausdruck zum Entfernt eines Bestandteils des Terminnamens<br>
		<li><b>weekday_mapping</b></li>
			Mapping der Wochentag<br>
		<li><b>calendarname_praefix </b></li>
			soll der calendar name als Präfix im reading geführt werden<br
		<li><b>delimiter_text_reading </b></li>
			Trennzeichen(kette) zum Verbinden von Terminen, wenn sie auf den gleichen Tag fallen<br>
			gilt nur für die Readings next_text und now_text
		<li><b>delimiter_reading </b></li>
			Trennzeichen(kette) zum Verbinden von Terminen, wenn sie auf den gleichen Tag fallen<br>
			gilt nur für die readings next und now
		<li><b>filter </b></li>
			Zeichenkette zum Filter der Events aus den Kalendern, es sind auch regex möglich<br>
	</ul>
=end html_DE
=cut
