#!/usr/bin/perl -w
use strict;
use warnings;

#1001	9
#0101 	5
#0011 	3
print 9 ^ 5;

exit;
print 2<<3  | 7;
exit;
print 1<<3 ; print "#= 0b 1000";
print "\n";
print 1<<3 | 1  ; print "#= 0b01001";
print "\n";
print 0<<3 | 7  ; print "#= 0b00111";
print "\n";
print 1<<3 | 7  ; print "#= 0b01111";
print "\n";
print 2<<3 | 7  ; print "#= 0b10111";
print "\n";
print 3<<3 | 7  ; print "#= 0b11111";
print "\n";

print 1<<3 | 1  ; print "#= 0b01001";
print "\n";
print 0<<3 | 7  ; print "#= 0b00111";
print "\n";
print 1<<3 | 7  ; print "#= 0b01111";
print "\n";
print 2<<3 | 7  ; print "#= 0b10111";
print "\n";
print 3<<3 | 7  ; print "#= 0b11111";
print "\n";

exit;
my %files;


my $repoDir = ".legit/object/master/0/";
foreach my $f (glob("$repoDir*")){
	unless (exists $files{$f}) {
		$files{$f} = 0;
	}
	$files{$f} = $files{$f} | 1;
}

foreach my $f (keys %files){
	if($f =~/$repoDir(.+)/g){
		print "$1:$files{$f}\n";
	}
}

sub indexOfList{
	my $flag = shift @_;
	my $list = @_;
	foreach my $item (@_){
		return 1 if $item eq $flag;
	}
	return 0;
}