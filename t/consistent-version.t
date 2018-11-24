#!/usr/bin/env perl

# Copyright © 2018 Jakub Wilk <jwilk@jwilk.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 dated June, 1991.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

no lib '.';

use strict;
use warnings;

use English qw(-no_match_vars);
use FindBin ();
use Test::More tests => 2;

my $base = "$FindBin::Bin/..";
open(my $fh, '<', "$base/spellcheck.pl") or die $ERRNO;
my $code_version = 0;
while (<$fh>) {
    if (/^\$VERSION\s*=/) {
        my $VERSION;
        $code_version = eval;
    }
}
close($fh) or die $ERRNO;
open($fh, '<', "$base/doc/changelog") or die $ERRNO;
my $changelog = <$fh> // die $ERRNO;
close($fh) or die $ERRNO;
my ($changelog_version, $distribution) = $changelog =~ qr/^irssi-spellcheck [(](\S+)[)] (\S+); urgency=\S+$/;
SKIP: {
    if (-d "$base/.git") {
        skip('git checkout', 1);
    }
    if (-d "$base/.hg") {
        skip('hg checkout', 1);
    }
    cmp_ok(
        $distribution,
        'ne',
        'UNRELEASED',
        'distribution != UNRELEASED',
    );
}
cmp_ok(
    ($code_version // ''),
    'eq',
    ($changelog_version // ''),
    'code version == changelog version'
);

# vim:ts=4 sts=4 sw=4 et
