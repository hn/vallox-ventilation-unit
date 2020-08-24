#!/usr/bin/perl
#
# unpack-vallox-firmware.pl -- Unpack Vallox HSWUPD.BIN firmware files
#
# (C) 2020 Hajo Noerenberg
#
# http://www.noerenberg.de/
# https://github.com/hn/vallox-ventilation-unit
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3.0 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
#

use strict;
use Digest::CRC qw(crc);

my $write = 0;

sub crc16modbus {
    # width=16 poly=0x8005 init=0xffff refin=true refout=true xorout=0x0000 check=0x4b37 residue=0x0000 name="CRC-16/MODBUS"
    my $crc = crc( shift(), 16, 0xffff, 0, 1, 0x8005, 1);
    return pack( "n*", $crc );
}

sub runpack {
    my ( $level, $off, $ssize ) = @_;

    my $spos = 0;
    while ( $spos < $ssize ) {

        my $header;
        my $payload;
        seek( IF, $off + $spos, 0 );
        read( IF, $header, 36 ) == 36 || die("Invalid input file - unable to read header");
        printf( "%7X %*v2.2X\n", $off + $spos, " ", $header );
        print "(" . $level . ")==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC\n";

        my $subtype  = unpack( "n", substr( $header, 22, 2 ) );
        my $size  = unpack( "V", substr( $header, 24, 4 ) );
        read( IF, $payload, $size ) == $size || die("Invalid input file - unable to read payload");

        my $datastart  = unpack( "V", substr( $header, 30, 4 ) );
        my $pcrc = crc16modbus( $payload );
        my $hcrc = crc16modbus( substr($header, 0, 34) );
        printf("%7d %83d %*v2.2X %11d %*v2.2X\n", $off + $spos, $size, " ", $pcrc, $datastart, " ", $hcrc );

        if ( $write ) {
            my $outfile = sprintf("section-%d-%07d-%07d.bin", $level, $off + $spos, $size);
            print "Writing output file '" . $outfile . "'\n";
            open( OF, ">$outfile" ) || die( "Unable to open output file '$outfile': " . $! );
            binmode(OF);
            print OF $payload;
            close(OF);
        }

        $spos += 36;

        # Unknown #1: Subtype 1 has 16 trailing bytes with unknown meaning (something, len, len) - not CRC-checked
        if ( $subtype == 1 ) {
            read( IF, my $buf, 16 ) == 16 || die("Invalid input file - unable to read");
            printf( "Unknown trailing bytes: %*v2.2X\n", " ", $buf );

            $spos += 16;
        }
        print "\n";

        # Subtype 0 is a container-like section
        if ( $subtype == 0 ) {
            runpack( $level + 1, $off + $spos, $size );
        }

        $spos += $size;
    }
}

if ( $ARGV[0] eq "-w" ) {
    $write++;
    shift();
}

my $f = $ARGV[0];

die("Usage: $0 [-w] HSWUPD.BIN") if ( !$f );
open( IF, "<$f" ) || die( "Unable to open input file '$f': " . $! );
binmode(IF);

print "\nWarning: Alpha Status, various things are unknown and/or wrong!\n\n";

my $fsize = -s $f;
runpack( 0, 0, $fsize );

