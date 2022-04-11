#!/bin/bash


PRINTABLE_CHARS="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzäöüß0123456789+/=[]{}()?§$&%_-<>|!#':;"

#
# helper function for dividing integers
# Arguments: dividend and divisor
#
function float_div () {
	local result=$(awk -v d1=$1 -v d2=$2 'BEGIN { print (d1 / d2) }');
	local ret_val=$(echo "$result" | sed 's/,/\./');
	echo "$ret_val";
}  


#
# helper function to compare floats (lower or equal than)
# Arguments: two floats (with dot as floating point)
#
function float_le () {
	if awk "BEGIN {exit !($1 <= $2)}"; then
    		return 0;
		else
    		return 1;
	fi

}


#
# helper function to compare floats (lower than)
# Arguments: two floats (with dot as floating point)
#
function float_lt () {
	if awk "BEGIN {exit !($1 < $2)}"; then
    		return 0;
		else
    		return 1;
	fi

}


#
# helper function to compare floats (greater or equal than)
# Arguments: two floats (with dot as floating point)
#
function float_ge () {
	if awk "BEGIN {exit !($1 >= $2)}"; then
    		return 0;
		else
    		return 1;
	fi

}


#
# helper function to compare floats (greater than)
# Arguments: two floats (with dot as floating point)
#
function float_gt () {
	if awk "BEGIN {exit !($1 > $2)}"; then
    		return 0;
		else
    		return 1;
	fi

}


#
# helper function to compute the shannon entropy
# Arguments: String from which the Shannon entropy is to be calculated
#
function shannon_entropy () {

	local entropy=0;
	local data=$1
	local px;

    for (( i=0; i<${#PRINTABLE_CHARS}; i++ )); do 

		count=$(grep -o -F "${PRINTABLE_CHARS:$i:1}" <<< "$1" | wc -l);
		px=$(float_div "$count" "${#data}") 

		if float_gt "$px" "0.0"; then
			entropy=$(awk -v vpx=$px -v entr=$entropy 'BEGIN{print entr + (-1.0 * vpx * log(vpx)/log(2))}');
		fi	
	done

	ret_val=$(echo "$entropy" | sed 's/,/\./');
	echo "$ret_val" 
}


#
# Returns the file extension of a given file
# Arguments: filename
#
function get_file_extension () {
	local filename=$1;
	echo "${filename##*.}"
}


#
# Checks if file contains textual data
# Arguments: path to file
#
function is_text_file() { 
	grep -qIF '' "$1"; 
}


#
# Extracts all strings that match the search criteria from the ZIP archive
# Argument: path of zipfile
#
function get_strings_from_zipfile () {

	local file_list=$(unzip -Z1 "$1");
	local search_string=$(printf ".%s|" $(echo "$EXCLUDED_FILES"))
	search_string=${search_string%?}

	local filtered_files=$(echo "$file_list" | grep -v ".*/$" | grep -E -v "$search_string")	
	local -a words=()

	for file in $filtered_files; do
		
		local file_content="$(unzip -p "$1" "$file")";
		words=$(get_printable_strings_from_string "$file_content");

	done

	echo "${words[*]}"
}


#
# Extracts all strings that match the search criteria from another string.
# Argument: String
#
function get_printable_strings_from_string () {
	local -a words=();

	while read -r -n 1024 bytes; do
    	
    	local word="";
    	
    	for (( i=0; i<${#bytes}; i++ )); do
  			
  			if [[  "$PRINTABLE_CHARS" == *"${bytes:$i:1}"* ]]; then
  				word="$word${bytes:$i:1}";
  			elif [[ MAX_KEY_SIZE -ge "${#word}" && MIN_KEY_SIZE -le "${#word}" ]]; then
  				words+=("$word");
  				word="";
  			else
  				word="";
  			fi

		done

		if [[ MAX_KEY_SIZE -ge "${#word}" && MIN_KEY_SIZE -le "${#word}" ]]; then 
			words+=("$word")
			word="";
		fi
		

	done <<< "$1"

	echo "${words[*]}";

}


#
# Extracts all strings that match the search criteria from a textual file.
#
function get_printable_strings_from_file () {
	local -a words=();
	
	while read -r -n 1024 bytes; do
    	
    	local word="";
    	
    	for (( i=0; i<${#bytes}; i++ )); do
  			
  			if [[  "$PRINTABLE_CHARS" == *"${bytes:$i:1}"* ]]; then
  				word="$word${bytes:$i:1}";
  			elif [[ MAX_KEY_SIZE -ge "${#word}" && MIN_KEY_SIZE -le "${#word}" ]]; then
  				words+=("$word");
  				word="";
  			else
  				word="";
  			fi

		done

		if [[ MAX_KEY_SIZE -ge "${#word}" && MIN_KEY_SIZE -le "${#word}" ]]; then 
			words+=("$word")
			word="";
		fi

	done < $1

	echo "${words[*]}";

}


#
# Decides whether a discovered string is a secret with an entropy above the threshold. 
#
function found_high_entropy () {
	local b64_entropy=$(shannon_entropy "$2");

	if float_gt "$b64_entropy" "$3"; then
		echo "[DETECTION] Found the following high entropy string in file $1: $2 (Entropy: $b64_entropy)";
	fi
}


#
# Analyzes a given file for secrets.
#
function analyze_file () {

	local file_ext=$(get_file_extension "$1");
	local -a b64_strs=();
	local found=0;

	if [[ $file_ext == "zip" ]]; then
		b64_strs=($(get_strings_from_zipfile "$1"));
		found=1;
	elif [[ $file_ext == "tar" ]]; then
		local file_content=$(tar -xOf "$1");
		b64_strs=($(get_printable_strings_from_string "$file_content"));
		found=1;
	elif [[ $file_ext == "gz" ]]; then
		local file_content=$(tar -xOzf "$1");
		b64_strs=($(get_printable_strings_from_string "$file_content"));
		found=1;
	elif ! is_text_file "$1" && [[ "$IGNORE_BINARIES" == "0" ]]; then
		local file_content=$(strings -n "$MIN_KEY_SIZE" "$1");
		b64_strs=($(get_printable_strings_from_string "$file_content"));
		found=1;
	elif is_text_file "$1"; then
		b64_strs=($(get_printable_strings_from_file "$1"));
		found=1;
	fi

	local total=${#b64_strs[*]};

	if [[ "$EXT_VERBOSE" == "1" && "$found" == "1" ]]; then
		echo "[INFO THREAD $THREAD_NUMBER] Current File: $1" >&2
	fi

	local c=0;

	for word in ${b64_strs[*]}; do
		
		if [[ "$EXT_VERBOSE" == "1" ]]; then
			let c++;
			echo "[INFO THREAD $THREAD_NUMBER] $c of $total detected strings checked for secrets..." >&2
		fi
		
		found_high_entropy "$1" "$word" "$HIGH_ENTROPY_THRES"
	done
}


#
# Startpoint of file analysis
#
function start_analysis () {

	local files=$(cat -);
	local total=$(echo "$files" | wc -l);
	local o=$IFS;
	IFS=$(echo -en "\n\b");

	local counter=1;

	for file in $files; do

		if [ "$VERBOSE" == "1" ] || [ "$EXT_VERBOSE" == "1" ]; then
			echo "[INFO THREAD $THREAD_NUMBER] $counter from $total files processed" >&2
		fi

		let counter++;
		analyze_file "$file";
	done

	IFS=o;
}





#
# Argument Parsing and startpoint of the analysis
#
while getopts vehbd:l:m:t:n: option
do 
    case "${option}"
        in
        l)MIN_KEY_SIZE_TEMP=${OPTARG};;
		m)MAX_KEY_SIZE_TEMP=${OPTARG};;
		t)ENTROPY_THRES_TEMP=${OPTARG};;
		n)THREAD_NUMBER=${OPTARG};;
		e)EXT_VERBOSE_TEMP="1";;
		v)VERBOSE_TEMP="1";;
		b)BINARIES_TEMP="0";;
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

start_analysis ;