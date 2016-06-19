# $Id: 57_ABFALL.pm 11019 2016-02-16 01:55:00Z uniqueck $
###########################
#	ABFALL
#	
#	needs a defined Device 57_Calendar
###########################
package main;

use strict;
use warnings;
use POSIX;
use Date::Parse;
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
    
	$hash->{NAME} 	= $name;
	$hash->{STATE}	= "Initialized";
	InternalTimer(gettimeofday()+2, "ABFALL_GetUpdate", $hash, 0);
	return undef;
}
sub ABFALL_Undef($$){
	my ( $hash, $arg ) = @_;
	#DevIo_CloseDev($hash);			         
	RemoveInternalTimer($hash);    
	return undef;                  
}

sub ABFALL_Set($@){
	my ( $hash, @a ) = @_;
	return "\"set ABFALL\" needs at least an argument" if ( @a < 2 );
	return "\"set ABFALL\" Unknown argument $a[1], choose one of update" if($a[1] eq '?'); 
	my $name = shift @a;
	my $opt = shift @a;
	my $arg = join("", @a);
	if($opt eq "update"){ABFALL_GetUpdate($hash);}
}

sub ABFALL_GetUpdate($){	
	my ($hash) = @_;
	my $name = $hash->{NAME};
	Log3 $name, 3, "ABFALL_UPDATE";	
	#cleanup readings
	
	fhem("deletereading $name next", 1);
	fhem("deletereading $name now", 1);
	fhem("deletereading $name .*_tage", 1);
	fhem("deletereading $name .*_wochentag", 1);
	fhem("deletereading $name .*_text", 1);
	fhem("deletereading $name .*_datum", 1);
	fhem("deletereading $name state", 1);

	Log3 $name, 5, "ABFALL_GetUpdate ($name) - readings deleted";		
	

	readingsBeginUpdate($hash); #start update
	my @termine =  ABFALL_getsummery($hash);
	
	my $counter = 1;
	my $samedatecounter = 2;
	my $lastterm;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900; $mon += 1; 	
	my $date = sprintf('%02d.%02d.%04d', $mday, $mon, $year);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + 86400);
	$year += 1900; $mon += 1; 		
	my $datenext = sprintf('%02d.%02d.%04d', $mday, $mon, $year);
	
	my $delimiter_text_reading = AttrVal($name,"delimiter_text_reading"," und ");
	my $delimiter_reading = AttrVal($name,"delimiter_reading","|");	
	
	my @termineNew;
	foreach my $item (@termine ){
		Log3 $name, 5, "ABFALL_GetUpdate ($name) - $item->[6] - $item->[4]";
		my @tempstart=split(/\s+/,$item->[0]);
		$item->[1] =~ s/\\,/,/g;
		$item->[4] =~ s/\\,/,/g;
		push @termineNew,{
			bdate => $tempstart[0],
			summary => $item->[1],
			weekday => $item->[2],
			source => $item->[3],
			mode => $item->[5],
			readingName => $item->[4],
			calendar => $item->[6],
			tage => $item->[7]};
		}
	
	my $nowAbfall_tage = -1;
	my $nowAbfall_text = "";
	my $nowAbfall_datum;
	my $nowAbfall_weekday;
	my $now_readingTermin = "";
	
	
	my $nextAbfall_tage = -1;
	my $nextAbfall_text = "";
	my $nextAbfall_datum;
	my $nextAbfall_weekday;
	my $next_readingTermin = "";
	
	for my $termin (@termineNew) {
		my $readingTermin = $termin->{readingName};
		Log3 $name, 5, "ABFALL_GetUpdate ($name) - $readingTermin";
		
		if ($termin->{tage} == 0) {
			if($nowAbfall_text eq "") {
				$nowAbfall_text = $termin->{summary};	
			} else {
				$nowAbfall_text .= $delimiter_text_reading . "_" . $termin->{summary};
			}
			$nowAbfall_tage = $termin->{tage};
			$nowAbfall_datum = $termin->{bdate};
			$nowAbfall_weekday = $termin->{weekday};
			$now_readingTermin = $readingTermin;
		} elsif	($nextAbfall_tage == -1 || $nextAbfall_tage > $termin->{tage} || $nextAbfall_tage == $termin->{tage} ) {
			if ($nextAbfall_text eq "") {
				$nextAbfall_text = $termin->{summary};
			} else {
				$nextAbfall_text .= $delimiter_text_reading . $termin->{summary};
			}
			$nextAbfall_tage = $termin->{tage};
			$nextAbfall_datum = $termin->{bdate};
			$nextAbfall_weekday = $termin->{weekday};
			if ($next_readingTermin eq "") {
				$next_readingTermin = $readingTermin;
			} else {
				$next_readingTermin .= $delimiter_reading . $readingTermin;
			}			
		}	
		readingsBulkUpdate($hash, $readingTermin ."_tage", $termin->{tage});
		readingsBulkUpdate($hash, $readingTermin ."_text", $termin->{summary});
		readingsBulkUpdate($hash, $readingTermin ."_datum", $termin->{bdate});
		readingsBulkUpdate($hash, $readingTermin ."_wochentag", $termin->{weekday});
	}
	
	if ($nowAbfall_tage == 0) {
		readingsBulkUpdate($hash, "now", $now_readingTermin);
		readingsBulkUpdate($hash, "now_text", $nowAbfall_text);
		readingsBulkUpdate($hash, "now_datum", $nowAbfall_datum);
		readingsBulkUpdate($hash, "now_wochentag", $nowAbfall_weekday);
	}	
	
	if ($nextAbfall_tage > -1) {
		if ($next_readingTermin ne "") {
			 $next_readingTermin .= "_" .  $nextAbfall_tage
		}
		readingsBulkUpdate($hash, "next", $next_readingTermin);
		readingsBulkUpdate($hash, "next_tage", $nextAbfall_tage);
		readingsBulkUpdate($hash, "next_text", $nextAbfall_text);
		readingsBulkUpdate($hash, "next_datum", $nextAbfall_datum);
		readingsBulkUpdate($hash, "next_wochentag", $nextAbfall_weekday);

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

sub ABFALL_getsummery($){
	my ($hash) = @_;
	my @terminliste ;
	my $name = $hash->{NAME};
	my @calendernamen = split( ",", $hash->{KALENDER}); 
	my $t  = time;
	my $cleanReadingRegex = AttrVal($name,"abfall_clear_reading_regex","");
	my $calendarNamePraefix = AttrVal($name,"calendarname_praefix","1");
	my $filter = AttrVal($name,"filter","");
	my @filterArray=split( ',' ,$filter);
	
	my %replacement = ("ä" => "ae", "Ä" => "Ae", "ü" => "ue", "Ü" => "Ue", "ö" => "oe", "Ö" => "Oe", "ß" => "ss" );
	my $replacementKeys= join ("|", keys(%replacement));
	
	
	foreach my $calendername (@calendernamen){
		my $all = CallFn($calendername, "GetFn", $defs{$calendername},(" ","text", "next"));
	
		my @termine=split(/\n/,$all);
	
		my $wdMapping = AttrVal($name,"weekday_mapping","Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag");
		my @days = split("\ ", $wdMapping);
		Log3 $name, 5,  "ABFALL_getSummary($name) - calendar($calendername) - weekDayMapping (@days)" ;
		
	
		foreach my $eachTermin (@termine){
			Log3 $name, 5,  "ABFALL_getSummary($name) - calendar($calendername) - " . $eachTermin ;
			
			my @SplitDt = split(/ /,$eachTermin);
			my @SplitDate = split(/\./,$SplitDt[0]);
			my $eventDate = timelocal(0,0,0,$SplitDate[0],$SplitDate[1]-1,$SplitDate[2]);
			my $dayDiff = floor(($eventDate - $t) / 60 / 60 / 24 + 1);
			# skip events in the past
			next if ($dayDiff < 0);
			
			
			
			# skip termin of filter conditions - Start
			if ($filter ne "") {
				my $keepTermin = 'false';
				foreach my $eachFilter (@filterArray) {
				# fix from fhem forum user justme1968 to support regex for filter
				if ($eachFilter =~ m'^/(.*)/$' && $eachTermin =~ m/$1/ ) {
					$keepTermin = 'true';
					last;			
				} elsif (index($eachTermin, $eachFilter) != -1) {
					$keepTermin = 'true';
					last;
				}
				}
				Log3 $name, 5, "ABFALL_getSummay($name) - filter($eachTermin) - $keepTermin";
				if ($keepTermin eq 'false') {
					Log3 $name, 5, "ABFALL_getSummay($name) - filter($eachTermin) - next event";
					next;
				}
			}
			
			
			
			my $termintext =  $eachTermin;
			$termintext =~ s/($SplitDt[0])//g;
			$termintext =~ s/($SplitDt[1])//g;
			
			if ($cleanReadingRegex){
				$termintext =~ s/$cleanReadingRegex//g; 
			}		
			my $cleanReadingName = $termintext;
			
			if ($calendarNamePraefix eq "1") {
				$cleanReadingName = $calendername . "_" . $cleanReadingName;
			}
			$cleanReadingName =~ s/($replacementKeys)/$replacement{$1}/eg;
			# remove not valid chars for a reading name
			$cleanReadingName =~ tr/a-zA-Z0-9\-_//dc;
			
			my $tpDate    = Time::Piece->strptime($SplitDt[0], '%d.%m.%y');
			my $wdayname = $tpDate->day(@days);
				
			# Loggen, welcher Termin gerader gelesen wurde
			Log3 $name, 5,  "ABFALL_getSummary($name) - calendar($calendername) - " . $SplitDt[0] . " - " . $wdayname ." - ". $termintext . " - " . $dayDiff . " Tage";
			
			
			my $foundItem = ();
			foreach my $item (@terminliste ){
				my $tempText= $item->[1];
				my $tempCalName= $item->[3];
				if ($tempText eq $termintext && $tempCalName eq $calendername) {
					$foundItem = $item;
				}
				last if ($foundItem);		
			}
			if ($foundItem) {
				Log3 $name, 5, "ABFALL_getSummary($name) - calendar($calendername) - exists - " . $foundItem->[0] . " - " . $foundItem->[2] . " - " .  $foundItem->[1] . " - " . $foundItem->[7] . " Tage" ;
				if ($eventDate < $foundItem->[6] && $eventDate > $t) {
					Log3 $name, 5, "ABFALL_getSummary($name) - calendar($calendername) - change - " . $foundItem->[0] ." - " . $foundItem->[2] . " - " .  $foundItem->[7] .  " to " . $dayDiff . " Tage"  ;
					$foundItem->[6] = $eventDate;
					$foundItem->[2] = $wdayname;
					$foundItem->[0] = $SplitDt[0];
					$foundItem->[7] = $dayDiff;	
				}				
			} else {
				push(@terminliste, [$SplitDt[0], $termintext, $wdayname, $calendername, $cleanReadingName, "", $eventDate, $dayDiff]);
			}
		};
	}
	
	return @terminliste;
}
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
