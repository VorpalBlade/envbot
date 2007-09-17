#!/bin/bash
###########################################################################
#                                                                         #
#   Copyright (c)                                                         #
#     Arvid Norlander <anmaster@kuonet.org>                               #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################
# Allow owners to make to bot say something

module_calc_INIT() {
	echo "on_PRIVMSG"
}

module_calc_UNLOAD() {
	if [ -e "/tmp/calc.temp" ]; then
		rm /tmp/calc.temp
	fi
	unset module_say_on_PRIVMSG
}

module_calc_REHASH() {
	cat /dev/null > /tmp/calc.temp
	return 0
}

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_calc_on_PRIVMSG() {
        # Accept this anywhere, unless someone can give a good reason not to.
        local sender="$1"
        local channel="$2"
        local query="$3"
        local parameters
        if parameters="$(parse_query_is_command "$query" "calc")"; then
                echo -e "$parameters\nquit" > /tmp/calc.temp
		local myresult=`bc -q /tmp/calc.temp`
		send_msg "$channel" "$(parse_hostmask_nick "$sender"): $myresult"
		rm /tmp/calc.temp
                sleep 1
                return 1
        fi
        return 0
}