#!/bin/env perl

use strict;
use warnings;
use Data::Dumper;
#use Getopt::Long;
use Getopt::Std;
use File::Copy qw(copy);
use Env;
#use lib $ENV{MODULESHOME}."/init";
use lib "/usr/share/Modules/init/";
use perl;

###Start Doing Stuff###
my $Res_output = "RES-MIC_".$ARGV[1];
open(my $fh,'>',$Res_output) or die "Could not open file '$Res_output' $!";
#print Dumper \@ARGV;
print "Output file name is: $Res_output\n";

my %Res_hash;
my $RES_full_name = $ARGV[0];
open(MYINPUTFILE, "$RES_full_name");
while(<MYINPUTFILE>) {
    #next if $. < 2;
    my $line = $_;
    chomp($line);
    #print "$line\n";
    my @res_arr;
    @res_arr = split('\t',$line);
    $Res_hash{$res_arr[0]} = $res_arr[1];
}
close MYINPUTFILE;

my $PBP_full_name = $ARGV[2];
my $pbp2X = "NA";
open (MYINPUTFILE, "$PBP_full_name");
while (<MYINPUTFILE>) {
    next if $. < 2;
    my $line = $_;
    chomp($line);
    #print "$line\n";
    my @pbp_arr;
    @pbp_arr = split('\t',$line);
    my $pbp_ID = $pbp_arr[1];
    my @pbp_types = split(':',$pbp_ID);
    $pbp2X = $pbp_types[2];
    print "PBP Type 2X: $pbp2X\n";
}
close MYINPUTFILE;

#while (my ($key, $val) = each %Res_hash) {
#    my @val_arr = split(':',$val);
#    my @val_sort = sort(@val_arr);
#    my $val_out = join(':',@val_sort);
#    print "$key\t$val_out\n";
#}
#print "\n";
print Dumper \%Res_hash;

my %drug;
my %Out_hash;
###PBP Category###
$drug{ZOX} = "Flag,Flag,Flag";
$drug{FOX} = "Flag,Flag,Flag";
$drug{TAX} = "Flag,Flag,Flag";
$drug{CZL} = "NA,NA,NA";
$drug{CFT} = "Flag,Flag,Flag";
$drug{CPT} = "Flag,Flag,Flag";
$drug{AMP} = "Flag,Flag,Flag";
$drug{PEN} = "Flag,Flag,Flag";
$drug{MER} = "Flag,Flag,Flag";
if ($pbp2X <= 5 && $pbp2X !~ /[A-Za-z]/) {
    $drug{ZOX} = "<=,0.5,U";
    $drug{FOX} = "<=,8.0,U";
    $drug{TAX} = "<=,0.12,S";
    $drug{CFT} = "<=,0.12,S";
    $drug{CPT} = "<=,0.12,S";
    $drug{CZL} = "NA,NA,NA";
    $drug{AMP} = "<=,0.25,S";
    $drug{PEN} = "<=,0.12,S";
    $drug{MER} = "<=,0.12,S";
}
print "PBP,$drug{ZOX},$drug{FOX},$drug{TAX},$drug{CFT},$drug{CPT},$drug{CZL},$drug{AMP},$drug{PEN},$drug{MER}\n";
$Out_hash{PBP} = "$drug{ZOX},$drug{FOX},$drug{TAX},$drug{CFT},$drug{CPT},$drug{CZL},$drug{AMP},$drug{PEN},$drug{MER}";

###ER_CL Category###
$drug{ERY} = "<=,0.25,S";
$drug{CLI} = "<=,0.25,S";
$drug{SYN} = "<=,1.0,S";
$drug{LZO} = "<=,2.0,S";
$drug{ERY_CLI} = "neg";
my @Res_targs = split(':',$Res_hash{EC});
if ($Res_hash{"EC"} eq "neg") {
    #print "ER_CL,$Res_hash{EC},".$drug{ERY}.",".$drug{CLI}.",".$drug{SYN}.",".$drug{LZO}.",".$drug{ERY_CLI}."\n";
    $Out_hash{EC} = "$Res_hash{EC},$drug{ERY},$drug{CLI},$drug{LZO},$drug{SYN},$drug{ERY_CLI}";
} else {
    if (grep (/(R23S1|RPLD1|RPLV)/i,@Res_targs)) {
	#flag everything
	$drug{ERY} = "Flag,Flag,Flag";
	$drug{CLI} = "Flag,Flag,Flag";
	$drug{SYN} = "Flag,Flag,Flag";
	$drug{LZO} = "Flag,Flag,Flag";
	$drug{ERY_CLI} = "Flag";
    }
    #Check for MEF
    my $isMef = "no";
    if (grep(/MEF/i,@Res_targs)) {
	print "Found MEF\n";
	$drug{ERY} = ">=,1,R";
	$isMef = "yes";
    }
    #Check for LSA/LNU
    my $isLSA = "no";
    if (grep(/LSA/i,@Res_targs)) {
	print "Found LSA\n";
	$drug{CLI} = ">=,1,R";
	$isLSA = "yes";
    }
    my $isLNU = "no";
    if (grep(/LNU/i,@Res_targs)) {
	print "Found LNU\n";
	$drug{CLI} = "Flag,Flag,Flag";
	$isLNU = "yes";
    }
    #Check for ERM
    my $isErm = "no";
    if (grep (/ERM/i,@Res_targs)) {
	$drug{ERY} = ">=,1,R";
	$drug{CLI} = ">=,1,R";
	$drug{ERY_CLI} = "pos";
	$isErm = "yes";
    }
    #Check for ERY/CLI
    if ($isMef eq "yes" && ($isLSA eq "yes" || $isLNU eq "yes")) {
	print "Found both Mef and LSA/LNU\n";
	$drug{ERY_CLI} = "pos";
    }
    #Check for SYN
    if ($isErm eq "yes" && $isLSA eq "yes") {
	print "Found both Erm and LSA\n";
	$drug{SYN} = "Flag,Flag,Flag";
    } elsif ($isErm eq "yes" && $isLNU eq "yes") {
	print "Found both Erm and LNU\n";
	$drug{SYN} = "<=,1.0,S";
    }
    $Out_hash{EC} = "$Res_hash{EC},$drug{ERY},$drug{CLI},$drug{LZO},$drug{SYN},$drug{ERY_CLI}";
}

###GYRA_PARC Category###
$drug{LFX} = "<=,2,S";
$drug{CIP} = "NA,NA,NA";
if ($Res_hash{"FQ"} eq "neg") {
    print "FQ,$Res_hash{GYRA_PARC},".$drug{LFX}."\n";
    $Out_hash{FQ} = "$Res_hash{FQ},$drug{CIP},$drug{LFX}";
} else {
    my @Res_targs = split(':',$Res_hash{"FQ"});
    if ((grep/GYRA-S11L/i,@Res_targs) && (grep/PARC-S6[F|Y]/i,@Res_targs)) {
        print "Found GYRA-S11L:PARC-S6[F|Y]\n";
        $drug{LFX} = ">=,8,R";
    } elsif (grep(/PARC-D10[G|Y]/i,@Res_targs) || grep(/PARC-S6Y/i,@Res_targs)) {
	print "Found PARC-D10[G|Y] or PARC-S6Y\n";
	$drug{LFX} = "=,4,I";
    } elsif (grep(/PARC-D10[A|N]/i,@Res_targs) || grep(/PARC-[D5N|S6F|S7P]/i,@Res_targs)) {
	print "Found PARC-D10[A|N] or PARC-[D5N|S6F|S7P]\n";
	$drug{LFX} = "<=,2,S";
    } else {
        $drug{LFX} = "Flag,Flag,Flag";
    }
    print "FQ,$Res_hash{FQ},".$drug{LFX}."\n";
    $Out_hash{FQ} = "$Res_hash{FQ},$drug{CIP},$drug{LFX}";
}

###TET Category###
$drug{TET} = "<=,2.0,S";
if ($Res_hash{"TET"} eq "neg") {
    $Out_hash{"TET"} = "$Res_hash{TET},$drug{TET}";
} else {
    my @Res_targs = split(':',$Res_hash{TET});
    if ( grep( /TET/i, @Res_targs ) ) {
        $drug{TET} = ">=,8,R";
        $Out_hash{"TET"} = "$Res_hash{TET},$drug{TET}";
    }
}

###OTHER Category###
$drug{DAP} = "<=,1,S";
$drug{VAN} = "<=,1,S";
$drug{RIF} = "<=,1,U";
$drug{CHL} = "<=,4,S";
$drug{COT} = "<=,0.5,U";
if ($Res_hash{"OTHER"} eq "neg") {
    print "OTHER,$Res_hash{OTHER},".$drug{DAP}.",".$drug{VAN}.",".$drug{RIF}.",".$drug{CHL}.",".$drug{COT}."\n";
    $Out_hash{"OTHER"} = "$Res_hash{OTHER},$drug{DAP},$drug{VAN},$drug{RIF},$drug{CHL},$drug{COT}";
} else {
    my @Res_targs = split(':',$Res_hash{OTHER});
    my $isNew = "no";
    if ($Res_hash{OTHER} ne "ant(6)-Ia:Ant6-Ia_AGly:aph(3')-III:Aph3-III_AGly:Sat4A_Agly" && $Res_hash{OTHER} ne "aph(3')-III:Aph3-III_AGly:Sat4A_AGly" && $Res_hash{OTHER} ne "msr(D):MsrD_MLS") {
	foreach my $target (@Res_targs) {
	    if ($target !~ m/CAT|FOLA|FOLP|RPOB|VAN/i) {
		print "Found an ARGANNOT/RESFINDER target. Flag everything\n";
		$drug{DAP} = "Flag,Flag,Flag";
		$drug{VAN} = "Flag,Flag,Flag";
		$drug{RIF} = "Flag,Flag,Flag";
		$drug{CHL} = "Flag,Flag,Flag";
		$drug{SXT} = "Flag,Flag,Flag";
		$isNew = "yes";
		last;
	    } 
	}
    }
    if ($isNew eq "no") {
	foreach my $target (@Res_targs) {
	    if ($target =~ m/CAT/i) {
		print "Found CAT\n";
		$drug{CHL} = ">=,16,R";
	    } elsif ($target =~ m/FOLA/i || $target =~ m/FOLP/i) {
		print "Found FOLA and/or FOLP\n";
		$drug{COT} = "Flag,Flag,Flag";
	    } elsif ($target =~ m/VAN/i) {
		print "Found VAN\n";
		$drug{VAN} = ">=,2,U";
	    } elsif ($target =~ m/RPOB/i) {
		print "Found RPOB\n";
		$drug{RIF} = "Flag,Flag,Flag";
	    }
	}
    }
    $Out_hash{"OTHER"} = "$Res_hash{OTHER},$drug{DAP},$drug{VAN},$drug{RIF},$drug{CHL},$drug{COT}";
}

print $fh $Out_hash{PBP}.",".$Out_hash{TET}.",". $Out_hash{EC}.",".$Out_hash{FQ}.",".$Out_hash{OTHER}."\n";
print "$Out_hash{PBP}||$Out_hash{TET}||$Out_hash{EC}||$Out_hash{FQ}||$Out_hash{OTHER}\n";
