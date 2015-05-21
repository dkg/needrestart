# needrestart - Restart daemons after library updates.
#
# Authors:
#   Thomas Liske <thomas@fiasko-nw.net>
#
# Copyright Holder:
#   2013 - 2015 (C) Thomas Liske [http://fiasko-nw.net/~thomas/]
#
# License:
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this package; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#

package NeedRestart::CONT::LXC;

use strict;
use warnings;

use parent qw(NeedRestart::CONT);
use NeedRestart qw(:cont);
use NeedRestart::Utils;

my $LOGPREF = '[LXC]';

needrestart_cont_register(__PACKAGE__);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    die "Could not get NS PID of #1!\n" unless(defined($self->{nspid}));

    $self->{lxc} = {};
    return bless $self, $class;
}

sub check {
    my $self = shift;
    my $pid = shift;
    my $bin = shift;
    my $ns = $self->get_nspid($pid);

    # stop here if no dedicated PID namespace is used
    return 0 if(!$ns || $ns == $self->{nspid});

    unless(open(FCG, qq(/proc/$pid/cgroup))) {
	print STDERR "$LOGPREF #$pid: unable to open cgroup ($!)\n" if($self->{debug});
	return 0;
    }
    my $cg;
    {
	local $/;
	$cg = <FCG>;
	close(FCG);
    }

    # look for LXC cgroups
    return 0 unless($cg =~ /^\d+:[^:]+:\/lxc\/(.+)$/m);

    my $name = $1;
    print STDERR "$LOGPREF #$pid is part of LXC container '$name' and should be restarted\n" if($self->{debug});

    $self->{lxc}->{$name}++;

    return 1;
}

sub get {
    my $self = shift;

    return map {
	($_ => [qw(lxc-stop --reboot --name), $_]);
    } keys %{ $self->{lxc} };
}

1;
