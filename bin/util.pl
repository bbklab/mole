#!/usr/bin/env perl
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
# use Smart::Comments;

my $action = shift;
&help if (!$action || $action =~ m/\A\s*\Z/ || $action eq 'help');
&unique_digest(@ARGV)		   if $action eq 'unique_digest';
&parted_output(@ARGV)		   if $action eq 'parted_output';
&format_toterm(@ARGV)		   if $action eq 'format_toterm';


# Sub Def

sub help {
print <<EOF
Example:
  unique_digest 
  parted_output  {1-6}  {allof-plugin-output}
  format_toterm  {output-contain-htmlcode-htmlcolor}
EOF
;
exit(1);
}

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
