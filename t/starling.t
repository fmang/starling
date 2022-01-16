#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use Cwd 'abs_path';
use File::Basename;
use Symbol 'gensym';

# Ajoute t/ aux PATH pour usurper gammu-smsd-inject et avoir accès facilement à
# l’exécutable starling, qui est linké sous t/ pour avoir des modules différents.
my $root = dirname(dirname(abs_path(__FILE__)));
$ENV{PATH} = "$root/t/bin:$ENV{PATH}";

# Descend dans le dossier data/ où se trouvent les données de travail Starling.
chdir "$root/t/data";

sub starling {
	my %opt;
	%opt = %{pop @_} if ref $_[-1];
	my ($text) = @_;
	$ENV{'DECODED_PARTS'} = '0';
	$ENV{'SMS_1_TEXT'} = $text;
	$ENV{'SMS_1_NUMBER'} = $opt{sender} // '000';
	open(my $out, 'starling 2>&1 |');
	binmode($out, ':utf8');
	local $/;
	my $response = <$out>;
	close($out);
	$response
}

is(starling('ping'), <<EOF, 'responds to ping');
# gammu-smsd-inject -- TEXT 000 -len 700
Pong !
EOF

is(starling('PING'), <<EOF, 'is case insensitive');
# gammu-smsd-inject -- TEXT 000 -len 700
Pong !
EOF

is(starling('long') . "\n", <<EOF, 'truncates long messages');
# gammu-smsd-inject -- TEXT 000 -len 700
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 123456789
123456789 123456789 123456789 123456789 1234567...
EOF

is(starling('ping', { sender => '007' }), <<EOF, 'rejects unknown numbers')
Numéro inconnu : 007
EOF
