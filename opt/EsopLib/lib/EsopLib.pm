package EsopLib;

use 5.010001;
use strict;
use warnings;
use Smart::Comments;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use EsopLib ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    read_mole_config
    read_plugin_config
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    read_mole_config
    read_plugin_config
);

our $VERSION = '0.01';

our $ESOPDIR = '/usr/local/esop/agent';
our $MOLEDIR = $ESOPDIR . '/mole';
our $MOLECONFDIR = $MOLEDIR . '/conf';
our $MOLECFG = $MOLECONFDIR . '/.mole.ini';

# Preloaded methods go here.

sub read_mole_config {
    return &read_ini($_[0],$_[1],$MOLECFG);
}

sub read_plugin_config {
    return &read_ini($_[0],$_[1],$MOLECONFDIR . '/' . $_[0] . '.ini');
}

sub read_ini {
    my ($section,$key,$file) = @_;

    unless (-f $file && -s $file) {
	return;
    }
	
    unless ($section && $key) {
	return;
    }

    unless (open FH, "<", $file) {
	return;
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
			return $1;
		}
	}
    }
}

1;
__END__
