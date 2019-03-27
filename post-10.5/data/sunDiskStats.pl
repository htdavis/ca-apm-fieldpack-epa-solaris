#!/bin/perl
#############################################################
# Solaris Disk Stats
# =========================
# Copyright (C) 2010
# =========================
# Description: 
# This perl program emulates the functionality seen in
# aixDiskStats.pl. The program will create two nodes: Device, which
# provides metrics by device name; Disk, which provides metrics by mount point.
# N.B.: Inode metrics are currently unavailable for the version of DF
# used in Solaris.
# =========================
# Usage: perl sunDiskStats.pl [/filesystem1 /filesystem2 ...]
#
# Adding a filesystem to the commandline will cause the program to only report
# metrics for the specified device and/or disk.
#############################################################
use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/lib/perl", "$FindBin::Bin/../lib/perl");
use Wily::PrintMetric;

use strict;

# get the mounted disks specified on the command line
my $mountedDisksRegEx = '.'; # default is match all
if (scalar(@ARGV) > 0) {
	$mountedDisksRegEx = join('|', @ARGV);
}

# iostat command for Solaris
my $iostatCommand = 'iostat -rx';
# Get the device stats
my @iostatResults = `$iostatCommand`;
# Get rid of the header lines for each command
@iostatResults = @iostatResults[2..$#iostatResults];
# The -r option for iostat prints out the stats separated by
# commas, so grab all of them
# Output on Solaris:
#extended device statistics
#device,r/s,w/s,kr/s,kw/s,wait,actv,svc_t,%w,%b,
#cmdk0,0.1,0.2,5.5,1.2,0.0,0.0,12.3,0,0
#sd0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0

# parse the iostat results and report the
# relevant data using metrics
foreach my $isline (@iostatResults) {
	chomp $isline; # remove trailing new line
	my @deviceStats = split (',', $isline);
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
                                  name        => 'Transactions/sec',
                                  value       => sprintf("%.0f", $deviceStats[1] + $deviceStats[2]),
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
                                  name        => 'Avg. Service Time Active transactions (ms)',
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
                                  name        => '% Time Disk Is Busy',
                                  value       => sprintf("%.0f", $deviceStats[10]),
                                );
}

# df command for Solaris
my $dfCommand = 'df -k';
# Get the disk stats
my @dfResults = `$dfCommand`;
# Get rid of the header lines for each command
@dfResults = @dfResults[1..$#dfResults];
# Output on Solaris:
#Filesystem           1K-blocks      Used Available Use% Mounted on
#rpool/ROOT/opensolaris
#15320102   3012317  12307785  20% /
#swap                    463260       312    462948   1% /etc/svc/volatile
#/usr/lib/libc/libc_hwcap1.so.1
#15320102   3012317  12307785  20% /lib/libc.so.1
#swap                    462980        32    462948   1% /tmp
#swap                    462992        44    462948   1% /var/run
#rpool/export          12307806        21  12307785   1% /export
#rpool/export/home     12307806        21  12307785   1% /export/home
#rpool/export/home/hikod
#12308504       719  12307785   1% /export/home/hikod
#rpool                 12307863        78  12307785   1% /rpool
#scripts               20572080  16322748   4249332  80% /export/home/hikod/scripts

my $i = 0;
my $h = 0;
my @holdVal;
foreach my $dfLine (@dfResults) {
  chomp $dfLine; # remove trailing new line
  my @dfStats = split (/\s+/, $dfLine);
  my $fsName = $dfStats[0];
  my $diskName = $dfStats[5];

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
