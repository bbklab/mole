package EsopLib;

use strict;
use warnings;
use POSIX;
# use Smart::Comments;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use EsopLib ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    read_ini 
    hrtime
    is_sub
    log
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    read_ini
    hrtime
    is_sub
    log
);

our $VERSION = '0.01';

# Preloaded methods go here.

sub read_ini {
	my ($section,$key,$file) = @_;

	unless (defined $file) {
		return (undef, "config file not defined");
	}

    	unless ($section && $key) {
		return (undef, "section or key not defined");
    	}

    	unless (-f $file && -s $file) {
		return (undef, "config file $file not exist or empty");
    	}
	
    	unless (open FH, "<", $file) {
		return (undef, "config file $file open failed");
    	}

    	my $flag = 0;
    	while (<FH>) {
		if (m/\A\s*\[\s*($section)\s*\]\s*\Z/) {
			$flag = 1;
			next;
		}
		if (m/\A\s*\[\s*(\w+)\s*\]\s*\Z/) {
			last if $flag;
		}
		if (m/\A\s*$key\s*=\s*(.+)\s*\Z/) {
			if ($flag) {
				my $value = $1;
				$value =~ s/\A\s*//g;
				$value =~ s/\s*\Z//g;
				close FH;
				if ($value eq '') {
					return (undef, "config [$section]-[$key] empty");
				} else {
					return $value;
				}
			}
		}
    	}
    	close FH;
    	return (undef, "config [$section]-[$key] not defined");
}

sub hrtime {
	my $time = time;
	my $localtime = strftime("%Y-%m-%d_%H:%M:%S", localtime time);
	return $localtime;
}

sub log {
	my ($logfile, $message) = @_;
	if (defined $logfile && defined $message) {
		if (open my $fh, ">>", $logfile) {
			print $fh time . ' ' . &hrtime . ' ' . "$message\n";
			close $fh if ($fh);
		}
	}
}

sub split_head {
	if (m/\A(\w+?),(\S+?),(\S+?)\Z/) {
		return ($1,$2,$3);
	} else {
		return ('NULL','NULL','NULL');
	}
}

sub is_sub {
        my ($item, @array) = (shift, @_); 
        for (@array) {
                ( $item eq $_ ) && return 1;
                0;  
        }   
}

1;
__END__
