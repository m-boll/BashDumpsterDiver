#!/bin/bash


#
# Config parameters
#
TARGET_DIR="/"
OUTPUT_DIR="/tmp"
OUTFILE="dumpster_out_";
EXCLUDED_FILES="jpg jpeg png gif svg mp4 mp3 webm ttf woff eot css DS_Store pdf"
MIN_KEY_SIZE=12;
MAX_KEY_SIZE=80;
HIGH_ENTROPY_THRES="4.00";
VERBOSE="0";
EXT_VERBOSE="0";
IGNORE_BINARIES="1";
THREADS=2;



#
# Recursivly collects all files in a given directory and ignores all excluded types
# Arguments: file path
#
function collect_all_files () {
	local retval=$(find "$1" -type f $(printf "! -name *.%s " $(echo "$EXCLUDED_FILES")) 2>/dev/null);
	echo "$retval";
}


function start_analysis() {

	local files=$(collect_all_files "$TARGET_DIR");

	for ((i=1; i<=$THREADS; i++)) do
		echo "Spawning thread $i";
		filtered_files=$(echo "$files" | awk -v threads=$i 'NR == 1 || NR % threads == 0');
		
		echo "$filtered_files" | ./dumpster_diver.sh -l $MIN_KEY_SIZE -m $MAX_KEY_SIZE -t HIGH_ENTROPY_THRES -n $i \
			 $( if [ "$IGNORE_BINARIES" == "0" ]; then echo "-b"; fi ) \
			 $( if [ "$VERBOSE" == "1" ]; then echo "-v"; fi ) \
			 $( if [ "$EXT_VERBOSE" == "1" ]; then echo "-e"; fi ) > $(realpath "$OUTPUT_DIR/$OUTFILE$i") &

		filtered_files=$(echo "$filtered_files" | awk 'NR>1');

	done

}

#
# Prints the usage message.
#
function usage () {
	readonly PROGNAME=`basename $0`

	echo """usage: ./$PROGNAME [-h] [-e] [-v] [-b] [-c <threads>] [-d <path>] [-l <number>] [-m <number>] [-t <number>] 

Switches:
	
-h 
	Prints the help message
-b
	By specifying this switch, binaries are also scanned when searching for secrets. (Default: disabled)
-e
	Enables extensive verbosity. (Default: disabled)
-v 
	Enables basic verbosity. (Default: disabled)
-d <path>
	Specifies the starting path at which the recursive search is started. (Default: \"/\")
-l <integer>
	Minimum length of the strings to be considered for the entropy calculation. (Default: 12)
-m <integer>
	Maximum length of the strings to be considered for the entropy calculation. (Default: 80)
-t <float>
	Specifies the entropy threshold above which strings are recognized as secrets. (Default: 4.0)
-c <threads>
	Specifies the number of threads used for analysis. (Default: 2)
-o <output dir>
	Specifies the output directory where all results are written to. (Default: /tmp)
	
	"""
}


#
# Argument Parsing and startpoint of the analysis
#
while getopts vehbd:l:m:t:c: option
do 
    case "${option}"
        in
        d)TARGET_DIR_TEMP=${OPTARG};;
        l)MIN_KEY_SIZE_TEMP=${OPTARG};;
		m)MAX_KEY_SIZE_TEMP=${OPTARG};;
		t)ENTROPY_THRES_TEMP=${OPTARG};;
		c)THREADS_TEMP=${OPTARG};;
		o)OUTPUT_DIR_TEMP=${OPTARG};;
		e)EXT_VERBOSE_TEMP="1";;
		v)VERBOSE_TEMP="1";;
		b)BINARIES_TEMP="0";;
		h) usage; exit;;
    esac
done


if [[ ! -z "$TARGET_DIR_TEMP" ]]; then
	TARGET_DIR=$TARGET_DIR_TEMP;
fi;

if [[ ! -z "$MIN_KEY_SIZE_TEMP" ]]; then
	MIN_KEY_SIZE=$MIN_KEY_SIZE_TEMP;
fi;

if [[ ! -z "$MAX_KEY_SIZE_TEMP" ]]; then
	MAX_KEY_SIZE=$MAX_KEY_SIZE_TEMP;
fi

if [[ ! -z "$THREADS_TEMP" ]]; then
	THREADS=$THREADS_TEMP;
fi 

if [[ ! -z "$OUTPUT_DIR_TEMP" ]]; then
	THREADS=$OUTPUT_DIR_TEMP;
fi 

if [[ ! -z "$ENTROPY_THRES_TEMP" ]]; then
	HIGH_ENTROPY_THRES=$ENTROPY_THRES_TEMP;
fi

if [[ ! -z "$EXT_VERBOSE_TEMP" ]]; then
	EXT_VERBOSE=$EXT_VERBOSE_TEMP;
fi 

if [[ ! -z "$VERBOSE_TEMP" ]]; then
	VERBOSE=$VERBOSE_TEMP;
fi 

if [[ ! -z "$BINARIES_TEMP" ]]; then
	IGNORE_BINARIES=$BINARIES_TEMP;
fi

start_analysis;
