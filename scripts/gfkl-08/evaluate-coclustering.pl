#!/usr/bin/perl

use strict;
use warnings;
use Carp;
use Getopt::Long;

my $help        = 0;
my $aggregation = 'k'; # 'it'
my $measure     = 'MAE';
my $r_output    = 0;

GetOptions(
    'help'          => \$help,
    'aggregation=s' => \$aggregation,
    'measure=s'     => \$measure,
    '--r-output=s'  => \$r_output,
) or usage(-1);

if ($help) {
    usage(0);
}

my %sum   = ();
my %count = ();

while (<>) {
    my $line = $_;
    
    chomp $line;
    if ($line =~ m{
                    ^        # start of line
                    '(.*)'   # method
                    \s+;\s+  # ;
                    (.*)     # evaluation results
                    $        # end of line
                  }xms) {
        my $method_string = $1;
        my $result_string = $2;
        
        my ($method, $k, $l, $max_it);
        
        if ($method_string =~ m{
                                (\w+)             # method
                                \s                # whitespace
                                (\d+)-(\d+)-(\d+) # parameters
                               }xms) {
            $method  = $1;
            $k      = $2;
            $l      = $3;
            $max_it = $4;
        }
        else {
            croak "Failed to parse method string '$method_string'";
        }
        
        my %result = ();
        #print STDERR ">>>$result_string<<<";
        while ($result_string =~ s{
                                    \s*          # whitespace
                                    ([^=]+)      # key
                                    =
                                    ([^=\s,]+),?    # value
                                  }{}xms) {
            my $key   = $1;
            my $value = $2;
            #print STDERR "{{$key=$value}} ";
            $result{$key} = $value;
            #print STDERR ">>>$result_string<<<";
        }
        #print STDERR "\n";
        
        my $x = $aggregation eq 'k' ? $k : $max_it;

        if (exists $sum{$x}) {
                foreach my $key (keys %result) {
                    $sum{$x}->{$key} += $result{$key};
                }
                $count{$x}++;
        }
        else {
            $sum{$x} = \%result;
            $count{$x} = 1;
        }
    }
    else {
        croak "Failed to parse line '$line'";
    }
}

foreach my $x (sort { $a <=> $b } keys %sum) {
    print "$x\t";
    MEASURE:
    foreach my $key (sort (keys %{$sum{$x}})) {
        
        if (! $r_output) {
            next MEASURE if ! ($key eq $measure);
        }
        
        my $avg = $sum{$x}->{$key} / $count{$x};
        
        if (! $r_output) {        
            print "\t$key=$avg";
        }
        else {
            print "\t$avg";
        }
#        print " ($count{$x})";
    }
    print "\n";
}
 
sub usage {
    my ($exit_code) = @_;
    
    print << 'END';
    Summarize coclustering results.
    Options: TODO
END
    exit $exit_code;
}
