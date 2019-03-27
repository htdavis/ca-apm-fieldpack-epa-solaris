=head1 NAME

 sunVmStat.pl

=head1 SYNOPSIS

 IntroscopeEPAgent.properties configuration

 introscope.epagent.plugins.stateless.names=VMSTAT
 introscope.epagent.stateless.VMSTAT.command=perl <epa_home>/epaplugins/solaris/sunVmStat.pl
 introscope.epagent.stateless.VMSTAT.delayInSeconds=60 (15s minimum, 30s for shorter intervals, 60s default)

=head1 DESCRIPTION

 Pulls network IO statistics

 To see help information:

 perl <epa_home>/epaplugins/solaris/sunVmStat.pl --help

 or run with no commandline arguments.

 To test against sample output, use the DEBUG flag:

 perl <epa_home>/epaplugins/solaris/sunVmStat.pl --debug

=head1 CAVEATS

 NONE

=head1 ISSUE TRACKING

 Submit any bugs/enhancements to: https://github.com/htdavis/ca-apm-fieldpack-epa-solaris/issues

=head1 AUTHOR

 Hiko Davis, Client Services Architect, Broadcom

=head1 COPYRIGHT

 Copyright (c) 2018

 This plug-in is provided AS-IS, with no warranties, so please test thoroughly!

=cut


use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/lib/perl", "$FindBin::Bin/../lib/perl");
use Wily::PrintMetric;

use Getopt::Long;
use strict;

=head2 SUBROUTINES

=cut

=head3 USAGE

 Prints help information for this program

=cut
sub usage {
    print "Unknown option: @_\n" if ( @_ );
    print "usage: $0 <epa_home>/epaplugins/solaris/sunVmStat.pl[--help|-?] [--debug]\n\n";
    exit;
}

my ($help, $debug);
&usage if ( not GetOptions( 'help|?' => \$help,
                            'debug!' => \$debug,
                          )
            or defined $help );
            
my ($vmstatCommand, @vmstatResults);

if ($debug) {
    @vmstatResults = <<END_VMSTAT =~ m/(^.*\n)/mg;
 kthr      memory            page            disk          faults      cpu
 r b w   swap  free  re  mf pi po fr de sr s4 s5 s6 s7   in   sy   cs us sy id
 0 0 0 92753096 122824160 550 4119 14 40 29 0 0 -0 6 6 -2260 6135 13642 6777 2 1 97
 0 0 0 88826504 117550576 1422 1319 0 0 0 0 0 0 0 0  0 5595 5710 5364  1  1 98
END_VMSTAT
} else {
    $vmstatCommand = "vmstat 1 2";
    @vmstatResults = `$vmstatCommand`;
}

@vmstatResults = @vmstatResults[3..$#vmstatResults];
for my $line (@vmstatResults) {
    # remove EOL char
    chomp $line;
    # remove leading & trailing space
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    # split on spaces; place values to array
    my @values = split( /\s+/, $line);
    # report zero if value is blank/null
    if (!defined($values[17])) { $values[17] = 0; }
    if (!defined($values[18])) { $values[18] = 0; }
    # return results
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Threads',
                                    name            => 'Run Queue',
                                    value           => $values[0],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Threads',
                                    name            => 'Blocked Threads',
                                    value           => $values[1],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Threads',
                                    name            => 'Swapped LWP',
                                    value           => $values[2],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Memory',
                                    name            => 'Available Swap (KB)',
                                    value           => $values[3],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Memory',
                                    name            => 'Free List (KB)',
                                    value           => $values[4],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Page Fault/s',
                                    value           => $values[5],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Page Reclaims',
                                    value           => $values[6],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Minor Faults',
                                    value           => $values[7],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Paged In (KB)',
                                    value           => $values[8],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Paged Out (KB)',
                                    value           => $values[9],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Freed (KB)',
                                    value           => $values[10],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Memory Shortfall (KB)',
                                    value           => $values[11],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Page',
                                    name            => 'Pages Scanned',
                                    value           => $values[12],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'System',
                                    name            => 'Context Switches/s',
                                    value           => $values[13],
                                 );
   #  Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
   #                                  resource        => 'VMSTAT',
   #                                  subresource     => 'Disk',
   #                                  name            => 'IOPS-S4',
   #                                  value           => $values[14],
   #                               );
   #  Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
   #                                  resource        => 'VMSTAT',
   #                                  subresource     => 'Disk',
   #                                  name            => 'IOPS - S5',
   #                                  value           => $values[15],
   #                               );
   #  Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
   #                                  resource        => 'VMSTAT',
   #                                  subresource     => 'Disk',
   #                                  name            => 'IOPS - S6',
   #                                  value           => $values[16],
   #                               );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Faults',
                                    name            => 'Interrupts/s',
                                    value           => $values[17],
                                 );
    Wily::PrintMetric::printMetric( type            => 'PerIntervalCounter',
                                    resource        => 'VMSTAT',
                                    subresource     => 'Faults',
                                    name            => 'System Calls/s',
                                    value           => $values[18],
                                 );
}

