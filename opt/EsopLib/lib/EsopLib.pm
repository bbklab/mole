package EsopLib;

use strict;
use warnings;
use POSIX;
use Crypt::CBC;
use Crypt::OpenSSL::AES;
use Gzip::Faster qw(gzip gunzip);
use MIME::Base64 qw(encode_base64);
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
    read_mole_config
    read_plugin_config
    read_file_recvlst
    encode_mole_data
    c2kb
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    read_mole_config
    read_plugin_config
    read_file_recvlst
    encode_mole_data
    c2kb
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
	return undef;
    }
	
    unless ($section && $key) {
	return undef;
    }

    unless (open FH, "<", $file) {
	return undef;
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
			return $value;
		}
	}
    }
    close FH;
    return undef;	# this is important, otherwise return 1
}

sub read_file_recvlst {
    my ($config,$comment) = @_;
	
    unless ($config) {
	return undef;
    }
	
    $config =~ s/\A\s*file://gi;
    unless ($config =~ m/\A\//) {
	my $basedir = '/usr/local/esop/agent/mole/';
	$config = $basedir . $config;
    }

    unless (open FH, "<", $config) {
	return undef;
    }

    unless($comment) {
	$comment = '#';
    }

    my $result = undef;
    while (<FH>) {
	next if (m/\A\s*\Q$comment\E/);
	next if (m/\A\s*\Z/);
	chomp;
	$result .= $_ . ' ';
    }

    unless ($result) {
    	return undef;
    } else {
	return $result;
    }
}

sub encrypt {
	my ($data, $key, $iv) = @_;
	my $result = undef;
	
	unless (defined $data) {
		return (undef, "encrypt failed: data not defined");
	}

	unless (defined $key) {
		return (undef, "encrypt failed: key not defined");
	}

	unless (defined $iv) {
		return (undef, "encrypt failed: iv not defined");
	}
	
	my $cipher = Crypt::CBC->new(
		{
			'key'		=>  $key,
			'cipher' 	=>  'Crypt::OpenSSL::AES',
			'iv'		=>  $iv,
			'literal_key' 	=>  1,
			'header'	=>  'none',
			'keysize'	=>  128 / 8
		}
	) or return (undef, "encrypt failed: $!");
	unless ( $result = $cipher->encrypt($data) ) {
		return (undef, "encrypt failed: aes-cbc encrypt failed");
	}

	return $result;
}

sub compress {
	my $data  = shift;
	my $result = undef;

	unless (defined $data) {
		return (undef, "compress failed: data not defined");
	}

	unless ($result = gzip($data)) {
		return (undef, "compress failed: gzip error");
	}

	return $result;
}

sub uncompress {
	my $data  = shift;
	my $result = undef;

	unless (defined $data) {
		return (undef, "uncompress failed: data not defined");
	}

	unless ($result = gunzip($data)) {
		return (undef, "uncompress failed: gunzip error");
	}

	return $result;
}

sub encode_mole_data {
	my ($data, $key, $iv, $minlen) = @_;
	my $flag = 0;

	unless (defined $data) {
		return (undef, "encode failed: data not defined");
	}

	unless (defined $minlen && $minlen =~ m/\A\d+\Z/) {
		return (undef, "encode failed: minlen not defined or not int");
	}
	
	### get_args: @_

	# my $len;
	# $len = length $data;
	### init_len: $len
	my ($zipdata, $ziperror);
	if (length $data > $minlen) {
		($zipdata, $ziperror) = &compress($data);
		if ($zipdata) {
			$flag = 1;
		} else {
			return (undef, $ziperror);
		}
	} else {
		$zipdata = $data;
	}
	# $len = length $zipdata;
	### after_zip_len: $len

	my ($encdata, $encerror) = &encrypt($zipdata, $key, $iv);
	if ($encdata) {
		# $len = length $encdata;
		### after_enc_len: $len
		unless ( $encdata = encode_base64($flag.$encdata,"") ) {
			return (undef, "encode failed, base64 encode failed");
		}
	} else {
		return (undef, $encerror);
	}

	# $len = length $encdata;
	### at_last: $len
	return $encdata;
}

sub c2kb {
	my $size = shift;
	
	unless (defined $size) {
		return undef;
	}
	
	unless ($size =~ m/\A\s*(\d.+)\s*(K|KB|M|MB|G|GB|T|TB|P|PB|E|EB|Z|ZB|Y|YB)\Z/i) {
		return $size;
	}
	
	my ($number, $unit) = ($1, $2); 
	if ($unit =~ /\AK/i) {
		return $number;
	} elsif ($unit =~ /\AM/i) {
		return $number * 1024;
	} elsif ($unit =~ /\AG/i) {
		return $number * 1024 * 1024;
	} elsif ($unit =~ /\AT/i) {
		return $number * 1024 * 1024 * 1024;
	} elsif ($unit =~ /\AP/i ) {
		return $number * 1024 * 1024 * 1024 * 1024;
	} elsif ($unit =~ /\AE/i ) {
		return $number * 1024 * 1024 * 1024 * 1024 * 1024;
	} elsif ($unit =~ /\AZ/i ) {
		return $number * 1024 * 1024 * 1024 * 1024 * 1024 * 1024;
	} elsif ($unit =~ /\AY/i ) {
		return $number * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024;
	} else {
		return $size;
	}
}

1;
__END__
