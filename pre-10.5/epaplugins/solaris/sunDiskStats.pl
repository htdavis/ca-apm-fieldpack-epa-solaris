#!/bin/perl
#############################################################
# Solaris Disk Stats
# =========================
# Copyright (C) 2019
# =========================
# Description: 
# This program will create two nodes: Device, which
# provides metrics by device name; Disk, which provides metrics by mount point.
# N.B.: Inode metrics are currently unavailable for the version of DF
# used in Solaris.
# =========================
# Usage: perl <epa_home>/epaplugins/solaris/sunDiskStats.pl [/filesystem1 /filesystem2 ...]
#
# Adding a filesystem to the commandline will cause the program to only report
# metrics for the specified device and/or disk.
#############################################################
use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/lib/perl", "$FindBin::Bin/../lib/perl");
use Wily::PrintMetric;

use Getopt::Long;

sub usage {
    print "Unknown option: @_\n" if ( @_ );
    print "usage: $0 [/filesystem1 /filesystem2 ...] [--help|-?] [--debug]\n\n";
    print "\tAdding a filesystem to the commandline will cause the program to\n";
    print "\tonly report metrics for the specified device and/or disk.\n";
    exit;
}

my ($help, $debug);
&usage if ( not GetOptions( 'help|?' => \$help,
                            'debug!' => \$debug,
                          )
            or defined $help );

# get the mounted disks specified on the command line
my $mountedDisksRegEx = '.'; # default is match all
if (scalar(@ARGV) > 0) {
	$mountedDisksRegEx = join('|', @ARGV);
}

my ($iostatCommand, @iostatResults);
my ($dfCommand, @dfResults);
print "Running in DEBUG mode\n" if $debug;
if ( $debug ) {
    # use here-docs for command results
    @iostatResults = <<"EOF" =~ m/(^.*\n)/mg;
extended device statistics
device,r/s,w/s,kr/s,kw/s,wait,actv,svc_t,%w,%b,
cmdk0,0.1,0.2,5.5,1.2,0.0,0.0,12.3,0,0
sd0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0
extended device statistics
device,r/s,w/s,kr/s,kw/s,wait,actv,svc_t,%w,%b,
cmdk0,0.1,0.2,5.5,1.2,0.0,0.0,12.3,0,0
sd0,0.9,0.9,4.0,5.6,6.7,8.9,10.11,12,13
EOF

    @dfResults = <<"EOF" =~ m/(^.*\n)/mg;
Filesystem           1K-blocks      Used Available Use% Mounted on
rpool/ROOT/opensolaris
15320102   3012317  12307785  20% /
swap                    463260       312    462948   1% /etc/svc/volatile
/usr/lib/libc/libc_hwcap1.so.1
15320102   3012317  12307785  20% /lib/libc.so.1
swap                    462980        32    462948   1% /tmp
swap                    462992        44    462948   1% /var/run
rpool/export          12307806        21  12307785   1% /export
rpool/export/home     12307806        21  12307785   1% /export/home
rpool/export/home/hikod
12308504       719  12307785   1% /export/home/hikod
rpool                 12307863        78  12307785   1% /rpool
scripts               20572080  16322748   4249332  80% /export/home/hikod/scripts
EOF
} else {
    # iostat command for Solaris
    $iostatCommand = 'iostat -rx 30 2';
    # get device stats
    @iostatResults = `$iostatCommand`;
    # df command for Solaris
    $dfCommand = 'df -k';
    # Get the disk stats
    @dfResults = `$dfCommand`;
}

my $r = 0;
# skip the first 2 rows
# find the start of the next set of results
# parse the iostat results and report the
# relevant data using metrics
for my $l (2..$#iostatResults) {
    chomp $iostatResults[$l]; # remove trailing new line
    #print "$iostatResults[$l]\n" if $debug;
    next if (index($iostatResults[$l], "extended") == -1) && ($r == 0);
    #print "checking full string\n";
    if ( $iostatResults[$l] =~ m/^extended\sdevice\sstatistics$/i && $r == 0) {
        #print "found matching.\n" if $debug;
        $r = 1;
        next;
    }
    next if ($iostatResults[$l] =~ m/^device/i);
    my @deviceStats = split (',', $iostatResults[$l]);
    my $device = $deviceStats[0];

    # now, check to see if the user specified this device on the command
    # line.
    next if $device !~ /$mountedDisksRegEx/i;

    # report iostats
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'Reads/sec',
                                    value       => sprintf("%.0f", $deviceStats[1]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'Writes/sec',
                                    value       => sprintf("%.0f", $deviceStats[2]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'KB Read/sec',
                                    value       => sprintf("%.0f", $deviceStats[3]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'KB Written/sec',
                                    value       => sprintf("%.0f", $deviceStats[4]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'Avg. Transactions Waiting',
                                    value       => sprintf("%.0f", $deviceStats[5]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'Avg. Transactions Active',
                                    value       => sprintf("%.0f", $deviceStats[6]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'Avg. Service Time in Wait Queue (ms)',
                                    value       => sprintf("%.0f", $deviceStats[7]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'Avg. Service Time Active Transactions (ms)',
                                    value       => sprintf("%.0f", $deviceStats[8]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => '% Time Transactions Waiting',
                                    value       => sprintf("%.0f", $deviceStats[9]),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Device',
                                    subresource => $device,
                                    name        => 'Transactions/sec',
                                    value       => sprintf("%.0f", $deviceStats[1] + $deviceStats[2]),
                                  );
}


my $i = 0;
my $h = 0;
my @holdVal;
for my $d (1..$#dfResults) {
  	chomp $dfResults[$d]; # remove trailing new line
	  #print "$dfResults[$d]\n" if $debug;
  	my @dfStats = split (/\s+/, $dfResults[$d]);
  	my $fsName = $dfStats[0];
  	my $diskName = $dfStats[5];

    no warnings 'uninitialized';
    # check if line is just the filesystem; if so, hold temporarily until next loop
    if (length($diskName) == 0 ) {
        $holdVal[$i] = $dfStats[0];
        $h++;
        $i++;
        next;
    }

    # now, check to see if the user specified this disk on the command
    # line.
    next if $diskName !~ /$mountedDisksRegEx/i;

    # report the df stats
    # Just print the Used Disk Space as a Percent and in Megabytes
    # chop gets rid of '%' in the capacity
    chop $dfStats[4];
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Disk',
                                    subresource => $diskName,
                                    name        => 'Used Disk Space (%)',
                                    value       => $dfStats[4],
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Disk',
                                    subresource => $diskName,
                                    name        => 'Free Disk Space (MB)',
                                    value       => sprintf("%.0f", $dfStats[3] / 1024),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Disk',
                                    subresource => $diskName,
                                    name        => 'Used Disk Space (MB)',
                                    value       => sprintf("%.0f", $dfStats[2] / 1024),
                                  );
    Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'Disk',
                                    subresource => $diskName,
                                    name        => 'Total Disk Space (MB)',
                                    value       => sprintf("%.0f", $dfStats[1] / 1024),
                                  );
    if ($h == 1) {
        Wily::PrintMetric::printMetric( type        => 'StringEvent',
                                        resource    => 'Disk',
                                        subresource => $diskName,
                                        name        => 'Filesystem',
                                        value       => $holdVal[$i - 1],
                                        );
    } else {
        Wily::PrintMetric::printMetric( type        => 'StringEvent',
                                        resource    => 'Disk',
                                        subresource => $diskName,
                                        name        => 'Filesystem',
                                        value       => $dfStats[0],
                                        );
    }
    $h=0;
    $i++;
}
