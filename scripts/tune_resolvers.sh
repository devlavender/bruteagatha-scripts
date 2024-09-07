#!/bin/bash
#SPDX-License-Identifier: GPL-3.0

# COPYRIGHT (C) 2024 ÁGATHA ISABELLE CHRIS MOREIRA GUEDES

# File: tune_resolvers.sh

#######################################################################
### Author:                                                         
###    Agatha Isabelle Chris Moreira Guedes <code at agatha dot dev>
###
### Description:
###   Curate a list of DNS resolvers generating an output file with
###   the query time and the resolver address.
### Usage:
###   tune_resolvers.sh input-file [output-file] [failed-output-file]
###   The TEST_TARGET variable shall be defined inside the code for now
#######################################################################


#######################################################################
###                                                                 ###
###                            L I C E N S E                        ###
###                                                                 ###
#######################################################################
### This script is licensed under the GNU General Public License
### version 3 <https://www.gnu.org/licenses/gpl-3.0.html>

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
# along with this program.  If not, see <https://www.gnu.org/licenses/>


# Inform your target domain below:
TEST_TARGET="<your-target-domain-here>"

#for res in $(cat resolvers.txt); do dig @$res +tries=1 sishabi.com.br || ; done

mkdir -p /tmp/digout

__get_file(){
	ext="$1"
	file="/tmp/digout/$(uuid).$ext"
	while test -f $file; do
		file="/tmp/digout/$(uuid).$ext"
	done
	echo $file
}

__try() {
	dig @"$1" +tries=1 +time=1 "$TEST_TARGET" > "$2"
}

__get_time(){
	cat "$1" | grep -E "Query time:" | awk '/Query time:/ {print $4}' 
}

__log_failed(){
	test -f "$1" && cat >> "$1"
}

__main(){
	input_file="$1"
	output_file="$2"
	failed_file="$3"
	std_output="$4"
	for dns in $(cat "$input_file"); do
		echo "Testing $dns" >&2
		status=0
		qry_file=$(__get_file qry)
		__try "$dns" "$qry_file" ||
			(echo $dns |  __log_failed "$failed_file")
		status=$?
		time=$(__get_time "$qry_file")
		if [[ "$time" = "" ]]; then
			time="-1"
		fi
		echo "$time $dns" >> "$output_file"
	done

	if [[ $std_output = 1 ]]; then
		cat "$output_file"
	fi
}

input_file="$1"
output_file="$2"
failed_file="$3"

std_output=0

if [[ "$output_file" = "" ]]; then
	std_output=1
	output_file=$(__get_file out)
fi

if test -f "$input_file"; then
	echo "Testing resolvers from $input_file""..."
	__main "$input_file" "$output_file" "$failed_file" $std_output
else
	echo "No input file specified"
	exit -1
fi
