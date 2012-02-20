#
# recoverop.pl - WeeChat script to recover channel operator greedily and set channel mode +sn -
#
# Copyright (C) 2012 "AYANOKOUZI, Ryuunosuke" <i38w7i3@yahoo.co.jp>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;

weechat::register(
    "recoverop", "AYANOKOUZI, Ryuunosuke",
    "0.1.0", "GPL3", "recover operator",
    "", ""
);

weechat::hook_signal( "*,irc_raw_in_PART", "my_signal_irc_in_PART_cb", "" );
weechat::hook_signal( "*,irc_raw_in_QUIT", "my_signal_irc_in_QUIT_cb", "" );

sub my_signal_cb {
    foreach (@_) {
        weechat::print( "", $_ );
    }
    return weechat::WEECHAT_RC_OK;
}

sub part_join {
    weechat::print( "", join ",", @_ );
    my $server      = shift;
    my $channel     = shift;
    my $nick        = shift;
    my $nicks_count = get_nicks_count( $server, $channel );
    if ( defined $nicks_count && $nicks_count == 2 ) {
        my $myname = get_myname($server);
        if ( defined $myname && $myname ne '' ) {
            my $prefix = get_prefix( $server, $channel, $myname );
            if ( defined $prefix && $prefix ne '@' ) {
                my $buffer =
                  weechat::buffer_search( "irc", "$server.$channel" );
                weechat::command( $buffer, "/part" );
                weechat::command( $buffer, "/join -server $server $channel" );
                weechat::command( $buffer, "/mode +sn" );
            }
        }
    }
    return weechat::WEECHAT_RC_OK;
}

sub my_signal_irc_in_PART_cb {
    &my_signal_cb(@_);
    my $data        = shift;
    my $signal      = shift;
    my $type_data   = shift;
    my $signal_data = shift;
    my $server      = ( split ',', $signal )[0];
    my ( $user, $channel ) = ( split ' ', $type_data, 4 )[ 0, 2 ];
    my ( $nick, $username, $address ) = ( $user =~ m/:(.*)!(.*)@(.*)/ );
    part_join( $server, $channel, $nick );
    return weechat::WEECHAT_RC_OK;
}

sub my_signal_irc_in_QUIT_cb {
    &my_signal_cb(@_);
    my $data        = shift;
    my $signal      = shift;
    my $type_data   = shift;
    my $signal_data = shift;
    my $server      = ( split ',', $signal )[0];
    my $user        = ( split ' ', $type_data, 3 )[0];
    my ( $nick, $username, $address ) = ( $user =~ m/:(.*)!(.*)@(.*)/ );
    my $infolist = weechat::infolist_get( "irc_channel", "", "$server" );

    while ( weechat::infolist_next($infolist) ) {
        my $name = weechat::infolist_string( $infolist, "name" );
        my $infolist2 =
          weechat::infolist_get( "irc_nick", "", "$server,$name,$nick" );
        if ( defined $infolist2 && $infolist2 eq '' ) {
            weechat::infolist_free($infolist2);
            next;
        }
        weechat::infolist_free($infolist2);

        part_join( $server, $name, $nick );
    }
    weechat::infolist_free($infolist);
    return weechat::WEECHAT_RC_OK;
}

sub get_myname {
    my $server = shift;
    my $infolist = weechat::infolist_get( "irc_server", "", "$server" );
    weechat::infolist_next($infolist);
    my $myname = weechat::infolist_string( $infolist, "nick" );
    weechat::infolist_free($infolist);
    return $myname;
}

sub get_nicks_count {
    my $server  = shift;
    my $channel = shift;
    my $infolist =
      weechat::infolist_get( "irc_channel", "", "$server,$channel" );
    weechat::infolist_next($infolist);
    my $nicks_count = weechat::infolist_integer( $infolist, "nicks_count" );
    weechat::infolist_free($infolist);
    return $nicks_count;
}

sub get_prefix {
    my $server  = shift;
    my $channel = shift;
    my $nick    = shift;
    my $infolist =
      weechat::infolist_get( "irc_nick", "", "$server,$channel,$nick" );
    weechat::infolist_next($infolist);
    my $prefix = weechat::infolist_string( $infolist, "prefix" );
    weechat::infolist_free($infolist);
    return $prefix;
}
