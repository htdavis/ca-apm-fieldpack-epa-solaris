#!/bin/perl
#############################################################
# Solaris Multi-Processor Stats
# =========================
# Copyright (C) 2015
# =========================
# Description: 
# This perl program uses statistics from the 'mpstat' command.
# 
# "mpstat reports per-processor statistics in tabular form.
#  Each row of the table represents the activity of one proces-
#  sor."
# "All values are rates (events per second) unless otherwise noted."
# =========================
# Usage: perl mpstat.pl
#
#############################################################
use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/lib/perl", "$FindBin::Bin/../lib/perl");
use Wily::PrintMetric;

use strict;


# mpstat command for Solaris
my $mpstatCommand = 'mpstat';
# Get the cpu stats
my @mpstatResults = `$mpstatCommand`;
# Output on Solaris:
#CPU minf mjf xcal  intr ithr  csw icsw migr smtx  srw syscl  usr sys  wt idl
#  0    0   0   14   428  140 1476   39  101   67    1  5438    5   8   0  87
#  1    0   0   19   202   18 2011   48  104   66    1  6403    6   5   0  89

# Get rid of the header lines for each command
@mpstatResults = @mpstatResults[1..$#mpstatResults];


# parse the mpstat results and report the
# relevant data using metrics
foreach my $isline (@mpstatResults) {
	chomp $isline; # remove trailing new line
	# remove leading spaces
    $isline =~ s/^\s+//;
	my @cpuStats = split(/\s+/, $isline);
	my $cpu = $cpuStats[0];
	# prepend a zero to CPUs 1-9
	if ( int($cpu) >= 1 && int($cpu) <= 9 ) {
	    $cpu = "0". $cpu;
	}
	
	# report mpstats
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'minor faults',
                                    value       => int ($cpuStats[1]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'major faults',
                                    value       => int ($cpuStats[2]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'inter-proc x-calls',
                                    value       => int ($cpuStats[3]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'interrupts',
                                    value       => int ($cpuStats[4]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'interrupts as threads',
                                    value       => int ($cpuStats[5]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'context switches',
                                    value       => int ($cpuStats[6]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'inv context switches',
                                    value       => int ($cpuStats[7]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'thread migrations',
                                    value       => int ($cpuStats[8]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'spins on mutexes',
                                    value       => int ($cpuStats[9]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'spins on readers',
                                    value       => int ($cpuStats[10]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'system calls',
                                    value       => int ($cpuStats[11]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'minor faults',
                                    value       => int ($cpuStats[12]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'user time (%)',
                                    value       => int ($cpuStats[13]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'system time (%)',
                                    value       => int ($cpuStats[14]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu" . $cpu,
                                    name        => 'wait time (%)',
                                    value       => int ($cpuStats[15]),
                                  );
}
