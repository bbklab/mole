#!/usr/bin/env perl

our $basedir = '/usr/local/esop/agent/mole';
our $mole = "$basedir/sbin/mole";

BEGIN {
  my $basedir = '/usr/local/esop/agent/mole';
  my $pllib_dir = "$basedir/opt/plmods";
  my @incs = (    # set additional path
        # rhel5 32bit
        $pllib_dir.'/lib/perl5/',
        $pllib_dir.'/lib/perl5/5.8.8/',
        $pllib_dir.'/lib/perl5/site_perl/',
        $pllib_dir.'/lib/perl5/site_perl/5.8.8/',
        # rhel5 64bit
        $pllib_dir.'/lib64/perl5/',
        $pllib_dir.'/lib64/perl5/5.8.8/',
        $pllib_dir.'/lib64/perl5/site_perl/',
        $pllib_dir.'/lib64/perl5/site_perl/5.8.8/',
        # rhel6 32bit
        $pllib_dir.'/lib/perl5/',
        $pllib_dir.'/share/perl5/',
        # rhel6 64bit
        $pllib_dir.'/lib64/perl5/',
        $pllib_dir.'/share/perl5/',
  );

  push @INC, @incs;
};


use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw(encode_base64);
use Locale::Messages qw (textdomain bindtextdomain gettext nl_putenv);
use POSIX qw (setlocale LC_ALL);
# use Smart::Comments;
binmode(STDIN, ":encoding(utf8)");
binmode(STDOUT, ":encoding(utf8)");
binmode(STDERR, ":encoding(utf8)");
binmode STDOUT, ':raw';


# set locale, bind textdomain
our $localdir = "$basedir/share/locale/";
our $locale = 'zh_CN.UTF-8';
our $domain = "mole";
setlocale(LC_ALL,$locale);
nl_putenv("LANGUAGE=$locale");
nl_putenv("LANG=$locale");
textdomain "$domain";
bindtextdomain "$domain", "$localdir";


# process args
my $action = shift;
&help if (!$action || $action =~ m/\A\s*\Z/ || $action eq 'help');
&unique_digest(@ARGV)		   if $action eq 'unique_digest';
&parted_output(@ARGV)		   if $action eq 'parted_output';
&format_toterm(@ARGV)		   if $action eq 'format_toterm';
&base64_encode(@ARGV)		   if $action eq 'base64_encode';
&create_mailct(@ARGV)		   if $action eq 'create_mailct';
&filter_html(@ARGV)		   if $action eq 'filter_html';
&read_config(@ARGV)		   if $action eq 'read_config';

#
# Sub Def
#

# _ 
#
sub _ ($) { &gettext; }

# Show Help
#
sub help {
print <<EOF
Example:
  unique_digest 
  parted_output  {1-6}  {allof-plugin-output}
  format_toterm  {output-contain-htmlcode-htmlcolor}
  base64_encode  {strings-to-be-encode}
  create_mailct	 {tpl_path} {plugin_name} {eventid} {plugin_output} {handler_output}
  filter_html    {plugin_output}
  read_config	 {section} {key} {config_file}
EOF
;
exit(1);
}

# Create Unique MD5 Digest
#
sub unique_digest {
	my @chars = (0..9,'a'..'z','A'..'Z','#','(',')','=','-','+','_','@');
	my $rand = join "", map{ $chars[int rand @chars] } 0..14;
	my $unique_str = $rand.time();
	my $result = Digest::MD5::md5_hex($unique_str);
	printf $result;
}

# Read each part of plugin output
# Usage:        parted_output part_num "${content}"  {mode}
# Note:         part_num ~ [1-6]
# Note:		mode ~ perl | print    default: print
# Example:      parted_output 2  "{level}:{type}:{title | summary | details: item1. ### item2. ### item3. ### }"
# Example:      parted_output 6  "{level}:{type}:{title | summary | details: item1. ### item2. ### item3. ### }"
# 
sub parted_output {
	my $part = shift;
	my $content = shift;
	my $mode = shift || 'print';
	exit(1) if (!$part || $part =~ /\D/);
	exit(1) if ($part > 6 || $part < 1);
	exit(1) if (!$content);
	$content =~ m/{\s*(\w+)\s*}\s*:\s*{\s*(\w+)\s*}\s*:\s*{\s*(([^\|]+)(\|([^\|]+))?(\|([^\|]+))?)\s*}/i;
	# print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n6: $6\n7: $7\n8: $8\n\n";   # for debug
	my $result = '';
	if($1 && $part eq '1') { $result = $1; };
	if($2 && $part eq '2') { $result = $2; };
	if($3 && $part eq '3') { $result = $3; };
	if($4 && $part eq '4') { $result = $4; };
	if($6 && $part eq '5') { $result = $6; };
	if($8 && $part eq '6') { $result = $8; };
	$result =~ s/\A\s+//g if ($result);   # trim head \s
	if ($mode eq 'perl'){
		return ($result);
	} elsif ($mode eq 'print'){
		print $result;
	}
}

# Convert HTML-Color to TERM-Color in plugin output (last filed)
# Note:		remove <>/&nbsp; convert ###/<br> into newline
# Note:		output maybe multi-line.
# Usage:	format_toterm {content-last-filed}
#
sub format_toterm {
	my $content = shift;
	exit(1) if !defined $content;
	exit(1) if $content =~ m/\A\s*\Z/;
	$content =~ s/((<\s*font\s+color=(\w+)\s*>)\s*(.+?)\s*(<\s*\/font\s*>))/\n$3 ::: $4\n/ig;
	open my $fh, "<", \$content;
	  while(<$fh>){
		### process_line: $_
		if (/\A(\w+)\s+:::\s+(.+)\Z/){
			my ($color,$body) = ($1,$2);
			### color: $color
			### color_line: $body
			if ($color eq 'green'){
				$body = "\033[1;32m$body\033[0m";
			} elsif ($color eq 'red'){
				$body = "\033[1;31m$body\033[0m";
			} elsif ($color eq 'yellow'){
				$body = "\033[1;33m$body\033[0m";
			}
			$body =~ s/&nbsp;/ /g;
			print $body;
		} else {
			s/[\r\n]//g;
			s/&nbsp;/ /g;
			s/<br>/\n/g;
			s/\s*###\s*/\n/g;
			print;
		}
	  }
	close $fh;
}

# Base64 Encode Strings
#
sub base64_encode {
	my $content = shift;
	exit(1) if !defined $content;
	exit(1) if $content =~ m/\A\s*\Z/;
	my $output = encode_base64($content,'');	# trim '\n', empty eof
	if ($output) {
		chomp $output;
		printf $output;
	}
}


# Filter HTML Code
# Usage: 	filter_html  {output} {mode}
# Note:		mode ~ perl,print
# Example:	filter_html
#
sub filter_html {
	my $content = shift || return;
	my $mode = shift || 'print';
	### before_filter: $content
	$content =~ s/href\s*=\s*.+?script\s*://gi;
	$content =~ s/src\s*=\s*.+?script\s*://gi;
	$content =~ s/src\s*=\s*.+?\.(js|vbs|asp|aspx|php|php4|php5|jsp)//gi;
	$content =~ s/<script.+<\/script([^>])*>//gi;
	$content =~ s/<iframe.+<\/iframe([^>])*>//gi;
	$content =~ s/<frameset.+<\/frameset([^>])*>//gi;
	$content =~ s/on(blur|c(hange|lick)|dblclick|focus|keypress)//gi;
	$content =~ s/on((key|mouse)(down|up)|(un)?load|mouse(move|o(ut|ver))|reset|s(elect|ubmit))//gi;
	### after_filter: $content
        if ($mode eq 'perl'){
                return $content;
        } elsif ($mode eq 'print'){
                print $content;
        }
}


# Read INI Config File
# Usage:	read_config {section} {key} {config_file} {mode}
# Note:		mode ~ perl,print
# Example:	read_config global id /usr/local/esop/agent/mole/conf/.mole.ini print
#
sub read_config {
	my ($section, $key, $file, $mode) = @_;
	return undef if (!$section || !$key || !$file);
	$mode = 'print' unless ($mode);
  	### section: $section
  	### key: $key
  	### file: $file

  	unless (open FH, "<$file") {
		return undef;
  	}

  	my ($result,$flag) = ('',0);
  	while (<FH>) {
		if (m/\A\s*\[\s*($section)\s*\]\s*\Z/) {
			$flag = 1;
			next;
		}
 		if (m/\A\s*\[\s*(\w+)\s*\]\s*\Z/) {
			last if $flag == 1;
		}
		if (m/\A\s*$key\s*=\s*(.+)\s*\Z/) {
			if ($flag == 1) {
				$result = $1;
				last;
			}
		}
  	}
	close FH;

  	### result: $result
        if ($mode eq 'perl'){
                return $result;
        } elsif ($mode eq 'print'){
                print $result;
        }
}

# Create Mail Content by Template
# Usage:   create_mailct {tpl_path} {plugin} {eventid} {plugin_output} {handler_output}
# Example: create_mailct "notify_mail.tpl" "disk_fs" "abcdefghi012345" "{level}:{type}:{title | summary | details: item1. ### item2.}" "123 ### 321"
#
sub create_mailct {
	### @ARGV
	my ($tpl_path,$plugin,$eventid,$content,$hd_content) = @ARGV;
	exit(1) unless (defined $tpl_path && defined $plugin && defined $eventid && defined $content && defined $hd_content);
	exit(1) unless (-f $tpl_path && -r $tpl_path);
	exit(1) if ( $plugin =~ m/\A\s*\Z/ || $eventid =~ m/\A\s*\Z/ || $content =~ m/\A\s*\Z/ || $hd_content =~ m/\A\s*\Z/ );
	### $tpl_path
	### $plugin
	### $eventid
	### $content
	### $hd_content

	$content = &filter_html($content,'perl');
	$hd_content = &filter_html($hd_content,'perl');
	### after_filter_html: $content
	### after_filter_html: $hd_content

	my $level = &parted_output(1,$content,'perl') || '-';
	$level = uc $level;
	$level = sprintf(_"$level");
	### $level

	my $type  = &parted_output(2,$content,'perl') || '-';
	### $type

	my $title = &parted_output(4,$content,'perl') || '-';
	### $title

	my $summary = &parted_output(5,$content,'perl') || '-';
	### $summary

	my $details = &parted_output(6,$content,'perl') || '-';
	$details =~ s/###/<br>\n/g;
	### $details

	my ($sec,$min,$hour,$day,$mon,$year) = localtime(time);
	my $time = sprintf("%d-%d-%d_%d:%d:%d",$year+1900,$mon+1,$day,$hour,$min,$sec);
	### $time

	$hd_content =~ s/###/<br>\n/g;
	### $hd_content

	if (open my $fh, "<", $tpl_path) {
		while(<$fh>){
			if (m/\${MOLE-NOTIFY-MAIL_LEVEL}/){
				s/\${MOLE-NOTIFY-MAIL_LEVEL}/$level/;
			}
			if (m/\${MOLE-NOTIFY-MAIL_PLUGIN}/){
				s/\${MOLE-NOTIFY-MAIL_PLUGIN}/$plugin/;
			}
			if (m/\${MOLE-NOTIFY-MAIL_TIME}/){
				s/\${MOLE-NOTIFY-MAIL_TIME}/$time/;
			}
			if (m/\${MOLE-NOTIFY-MAIL_TITLE}/){
				s/\${MOLE-NOTIFY-MAIL_TITLE}/$title/;
			}
			if (m/\${MOLE-NOTIFY-MAIL_SUMMARY}/){
				s/\${MOLE-NOTIFY-MAIL_SUMMARY}/$summary/;
			}
			if (m/\${MOLE-NOTIFY-MAIL_EVENTID}/){
				s/\${MOLE-NOTIFY-MAIL_EVENTID}/$eventid/;
			}
			if (m/\${MOLE-NOTIFY-MAIL_DETAILS}/){
				s/\${MOLE-NOTIFY-MAIL_DETAILS}/$details/;
			}
			if (m/\${MOLE-NOTIFY-MAIL_AUTOHANDLE}/){
				s/\${MOLE-NOTIFY-MAIL_AUTOHANDLE}/$hd_content/;
			}
			print "$_";
		}
		close $fh if $fh;
	}
}
