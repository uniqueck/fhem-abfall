# $Id: 57_ABFALL.pm 10581 2016-01-21 05:20:49Z uniqueck $
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

sub ABFALL_Initialize($)
{
	my ($hash) = @_;

	$hash->{DefFn}   = "ABFALL_Define";	
	$hash->{UndefFn} = "ABFALL_Undef";	
	$hash->{SetFn}   = "ABFALL_Set";		
	$hash->{AttrFn}   = "ABFALL_Attr";
	$hash->{NotifyFn}   = "ABFALL_Notify";
	
	$hash->{AttrList} = "abfall_clear_reading_name ".
		"disable:0,1 "
		.$readingFnAttributes;
}
sub ABFALL_Define($$){
	my ( $hash, $def ) = @_;
	my @a = split( "[ \t][ \t]*", $def );
	return "\"set ABFALL\" needs at least an argument" if ( @a < 3 );
	my $name = $a[0];   
	
	my $inter = 43200;
	if(int(@a) == 4) { 
		$inter = int($a[3]); 
		if ($inter < 3600 && $inter) {
			return "ABFALL_Define - interval too small, please use something > 3600 (sec), default is 43200 (sec)";
	       }
	}
	 
	my $calendar = $a[2];
	
	return "wrong define syntax: you must specify a device name for using ABFALL" if(!defined($calendar));
	return "wrong define syntax: define <name> ABFALL <name> <interval>" if(@a < 3 || @a > 4);
    
	
	if($init_done)
	{
		return "define error: the selected device $calendar does not exist." unless(defined($defs{$calendar}));

		Log3 $name, 3, "ABFALL ($name) - WARNING - selected device $calendar ist not of type Calendar" unless($defs{$calendar}->{TYPE} eq "Calendar");
	}
	
	$hash->{NAME} 	= $name;
	$hash->{KALENDER} 	= $calendar;
	$hash->{STATE}	= "Initialized";
	$hash->{INTERVAL} = $inter;
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
	delete ($hash->{READINGS});
	# new timer
	InternalTimer(gettimeofday()+$hash->{INTERVAL}, "ABFALL_GetUpdate", $hash, 1);
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
	my @termineNew;
	foreach my $item (@termine ){
		my @tempstart=split(/\s+/,$item->[0]);
		Log3 $name, 3, "ABFALL_GetUpdate ($name) - @tempstart";
		my @tempend=split(/\s+/,$item->[2]);
		my ($D,$M,$Y)=split(/\./,$tempstart[0]);
		my @bts=str2time($M."/".$D."/".$Y." ".$tempstart[1]);
		#replace the "\," with ","
		$item->[1] =~ s/\\,/,/g;
		$item->[4] =~ s/\\,/,/g;
		push @termineNew,{
			bdate => $tempstart[0],
			btime => $tempstart[1],
			summary => $item->[1],
			source => $item->[3],
			location => $item->[4],
			edate => $tempend[0],
			etime => $tempend[1],
			btimestamp => $bts[0],
			mode => $item->[5],
			tage => $item->[7]};
				}
	# sort the array by btimestamp
	my @sdata = map  $_->[0], 
			sort { $a->[1][0] <=> $b->[1][0] }
            map  [$_, [$_->{btimestamp}]], @termineNew;
	
	my %replacement = ("ä" => "ae", "Ä" => "Ae", "ü" => "ue", "Ü" => "Ue", "ö" => "oe", "Ö" => "Oe", "ß" => "ss", " " => "", "," => "", "/" => "" );
	my $replacementKeys= join ("|", keys(%replacement));
	
	my $nextAbfall_tage = -1;
	my $nextAbfall_text;
	my $nextAbfall_datum;
	my $next_readingTermin = "";
	
	my $cleanReadingName = AttrVal($name,"abfall_clear_reading_name","");
	
	for my $termin (@sdata) {
		if ($cleanReadingName){
			$termin->{summary} =~ s/($cleanReadingName)//g; 
		}
		my $readingTermin = $termin->{summary};
		$readingTermin =~ s/($replacementKeys)/$replacement{$1}/g;
		
		if ($nextAbfall_tage == -1 || $nextAbfall_tage > $termin->{tage}) {
			$nextAbfall_text = $termin->{summary};
			$nextAbfall_tage = $termin->{tage};
			$nextAbfall_datum = $termin->{bdate};
			$next_readingTermin = $readingTermin;
		}	
		readingsBulkUpdate($hash, $readingTermin ."_tage", $termin->{tage});
		readingsBulkUpdate($hash, $readingTermin ."_text", $termin->{summary});
		readingsBulkUpdate($hash, $readingTermin ."_datum", $termin->{bdate});
	}
	
	if ($nextAbfall_tage > -1) {
		readingsBulkUpdate($hash, "next", $next_readingTermin."_".$nextAbfall_tage);
		readingsBulkUpdate($hash, "next_tage", $nextAbfall_tage);
		readingsBulkUpdate($hash, "next_text", $nextAbfall_text);
		readingsBulkUpdate($hash, "next_datum", $nextAbfall_datum);

		readingsBulkUpdate($hash, "state", $nextAbfall_tage);
	} else {
		readingsBulkUpdate($hash, "state", "Keine Abholungen");
	 }
		
	readingsEndUpdate($hash,1); #end update
}
sub ABFALL_Attr(@) {
	my ($cmd,$name,$attrName,$attrVal) = @_;
	my $hash = $defs{$name};
	return undef;
}


sub ABFALL_Notify($$)
{
  my ($own_hash, $dev_hash) = @_;
  my $ownName = $own_hash->{NAME}; # own name / hash

  return "" if(IsDisabled($ownName)); # Return without any further action if the module is disabled

  my $devName = $dev_hash->{NAME}; # Device that created the events
  Log3 $ownName, 5,  "ABFALL_Notify($ownName) - Device: " . $devName;
  return "" if($devName ne $own_hash->{KALENDER}); # Return withount any further action if the device of the event isn't the calendar

  my $count = @{$dev_hash->{CHANGED}}; # number of events / changes

  foreach my $event (@{$dev_hash->{CHANGED}}) {
    Log3 $ownName, 3,  "ABFALL_Notify($ownName) - Event: " . $event;
    #
    # Examples:
    # $event = "readingname: value" 
    # or
    # $event = "INITIALIZED" (for device "global")
    #
    # processing $event with further code
  }
}

sub ABFALL_getsummery($){
	my ($hash) = @_;
	my @terminliste ;
	my $name = $hash->{NAME};
	my $calendername  = $hash->{KALENDER};
	my $t  = time;
	my $all = CallFn($calendername, "GetFn", $defs{$calendername},(" ","text", "next"));
	my @termine=split(/\n/,$all);
	
	foreach my $eachTermin (@termine){
		Log3 $name, 5,  "ABFALL_getSummary($name) - " . $eachTermin ;
		
		my @SplitDt = split(/ /,$eachTermin);
		my @SplitDate = split(/\./,$SplitDt[0]);
		my $eventDate = timelocal(0,0,0,$SplitDate[0],$SplitDate[1]-1,$SplitDate[2]);
		my $dayDiff = floor(($eventDate - $t) / 60 / 60 / 24 + 1);
		my $termintext =  $eachTermin;
		$termintext =~ s/($SplitDt[0])//g;
		$termintext =~ s/($SplitDt[1])//g;
			
		# Loggen, welcher Termin gerader gelesen wurde
		Log3 $name, 3,  "ABFALL_getSummary($name) - " . $SplitDt[0] . " - " . $termintext . " - " . $dayDiff . " Tage";
		
		my $foundItem = ();
		foreach my $item (@terminliste ){
			my $tempText= $item->[1];
			if ($tempText eq $termintext) {
				$foundItem = $item;
			}
			last if ($foundItem);		
		}
		if ($foundItem) {
			Log3 $name, 5, "ABFALL_getSummary($name) - exists - " . $foundItem->[0] . " - " .  $foundItem->[1] . " - " . $foundItem->[7] . " Tage" ;
			if ($eventDate < $foundItem->[6] && $eventDate > $t) {
				Log3 $name, 3, "ABFALL_getSummary($name) - change - " . $foundItem->[0] . " - " .  $foundItem->[7] .  " to " . $dayDiff . " Tage"  ;
				$foundItem->[6] = $eventDate;
				$foundItem->[0] = $SplitDt[0];
				$foundItem->[7] = $dayDiff;	
			}				
		} else {
			push(@terminliste, [$SplitDt[0], $termintext, "", $calendername, "", "", $eventDate, $dayDiff]);
		}
	};
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
		<li><b>abfall_clear_reading_name</b></li>
			remove part of the summary text<br>
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
		<li><b>abfall_clear_reading_name</b></li>
			entfernt einen Bestandteil des Terminnamens<br>
	</ul>
=end html_DE
=cut
