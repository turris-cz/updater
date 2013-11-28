#!/usr/bin/perl

# Copyright (c) 2013, CZ.NIC
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the CZ.NIC nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL CZ.NIC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use common::sense;
use File::Path;
use Cwd 'abs_path';

my $indir;

my $reponame;

my ($generator, $fixer, $list_dir, $key) = map { abs_path $_ } @ARGV[0..3];

my $list;

my @lists;

sub leave() {
	return unless $indir;
	open my $fixer_p, '|-', $fixer, $key or die "Couldn't start fixer: $!";
	print $fixer_p "$_\n" for @lists;
	close $fixer_p or die "Fixer failed: $!";
	@lists = ();
	chdir '..' or die "Couldn't go up: $!";
}

while (<STDIN>) {
	chomp;
	s/#.*//;
	next unless /\S/;
	s/\$HOME/$ENV{HOME}/g;
	if (/^dir\s+(.*?)\s*$/) {
		leave;
		mkdir $1 or die "Can't create $1: $!";
		chdir $1 or die "Can't enter $1: $!";
		$indir = 1;
		mkdir 'lists' or die "Couldn't create lists: $!";
	} elsif (/^repo\s+(\w+)\s+(.*?)\s*$/) {
		$reponame = $1;
		die "No list specified yet" unless $list;
		print "Running generator on $2 for $1\n";
		if (system("'$generator' '$2' <'$list_dir/$list' >'lists/$1'")) {
			die "Failed to run generator";
		}
		push @lists, "lists/$1";
	} elsif (/^alias\s+(.*?)\s*$/) {
		symlink "$reponame", "lists/$1" or die "Couldn't create alias: $!";
		symlink "$reponame.sig", "lists/$1.sig" or die "Couldn't create sig alias: $!";
	} elsif (/^list\s+(.*?)\s*$/) {
		$list = $1;
	} else {
		die "Unknown command: $_";
	}
}
leave;
