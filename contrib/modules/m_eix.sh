#!/bin/bash
###########################################################################
#                                                                         #
#  envbot - an irc bot in bash                                            #
#  Copyright (C) 2007  Arvid Norlander                                    #
#                                                                         #
#  This program is free software: you can redistribute it and/or modify   #
#  it under the terms of the GNU General Public License as published by   #
#  the Free Software Foundation, either version 3 of the License, or      #
#  (at your option) any later version.                                    #
#                                                                         #
#  This program is distributed in the hope that it will be useful,        #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of         #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
#  GNU General Public License for more details.                           #
#                                                                         #
#  You should have received a copy of the GNU General Public License      #
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.  #
#                                                                         #
###########################################################################
# Check eix and return output from it.
# eix is a tool to search Gentoo packages
# From eix eix:
#   Description:         Small utility for searching ebuilds with indexing for fast results
# This module therefore depends on:
#   Gentoo
#   eix.

module_eix_INIT() {
	echo "on_PRIVMSG after_load"
}

module_eix_UNLOAD() {
	unset module_eix_format_string module_eix_last_query
	unset module_eix_on_PRIVMSG module_eix_after_load
}

module_eix_REHASH() {
	return 0
}

# Called after module has loaded.
# Check for eix
module_eix_after_load() {
	# Check (silently) for sqlite3
	type -p eix &> /dev/null
	if [[ $? -ne 0 ]]; then
		log_stdout "Couldn't find eix command line tool. The eix module depend on that tool."
		return 1
	fi
	unset module_eix_last_query
	module_eix_last_query='null'
}

# eix format string:
module_eix_format_string=$'<category>/\002<name>\002 \(<availableversionsshort>\) \(\002<homepage>\002\): <description>'

# Called on a PRIVMSG
#
# $1 = from who (n!u@h)
# $2 = to who (channel or botnick)
# $3 = the message
module_eix_on_PRIVMSG() {
	# Accept this anywhere, unless someone can give a good reason not to.
	local sender="$1"
	local channel="$2"
	local query="$3"
	local parameters
	if parameters="$(parse_query_is_command "$query" "eix")"; then
		if [[ "$parameters" =~ ^(.+) ]]; then
			local pattern="${BASH_REMATCH[1]}"
				# Simple flood limiting
				local query_time="$(date +%H%M)$sender"
				if [[ "$module_eix_last_query" != "$query_time" ]] ; then
					module_eix_last_query="$query_time"
					log_to_file eix.log "$sender made the bot run eix on \"$pattern\""
					send_msg "$channel" "$(EIX_PRINT_IUSE='false' eix -pSCxs --format "$module_eix_format_string" "$pattern" | head -n 1)"
				else
					log_stdout "ERROR: FLOOD DETECTED in eix module"
				fi
		else
			feedback_bad_syntax "$(parse_hostmask_nick "$sender")" "eix" "pattern"
		fi
		return 1
	fi
	return 0
}