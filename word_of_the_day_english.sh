#!/usr/bin/env bash
set -eo pipefail
# e: The script will exit on an error
# u: <ABORTED> Treat unset variables as an error when performing parameter expansion
#  This gives an error, "$1: unbound variable", when taking in input parameter of a command
# o pipefail: If any element of the pipeline fails, then the pipeline as a whole will fail
#  This is dangerous as pipelines only return a failure if the last command errors by default


# TO DOS
#1. Intepret German correctly
#DONE 2. Ability to accpet switch between browser Chrome or FireFox, plus error handling
#3. Travis CI
#DONE 4. No parameter specified: Show help menu


# All variables in bash are global by default
# Global variables should be in ALL_CAPITAL_CASE with readonly designation 
# Variable substitution within a sting should be "${variable}", NOT just $variable
	
get_word() {
	# local: can only be used in a function
	# Default line number when an error occurs
	local line_num_when_error=2
	
	# "$1" = first field (column) reference
	local total_line_num=$(wc -l "${word_list_filename}" | awk '{print $1}')
	
	
	# FNR = line number in the current file
	local line_num_of_last_word_used=$(awk 'FNR==1' "${word_list_filename}")

	# https://www.gnu.org/software/bash/manual/bash.html#Pattern-Matching (extended patterns)
	# +(pattern-list): Matches one or more occurrences of the given patterns
	# [:digit:]: POSIX's character classes  
	if [[ "${line_num_of_last_word_used}" != +([[:digit:]]) ]]; then
		# Must be a brand new file without the last used word number in Line 1. Insert a number pointing to the first word from the top
		
		# Normally sed use '/' character delimiter with '\' escape character, like below
   		#  sed -i '1s/\$line_num_of_last_word_used/\$line_num_of_next_word/' $1
    	# BUT, we can use '|' or any character that doesn't appear in the regexp itself.
   	    # The usual opening and closing ''' does NOT substitute variables inside them, MUST use '"'
		# Make sure of the last '|' before the ending '"'. An error "unterminated `s' command" without it
		# It inserts a number at the very begininng of the file PLUS a newline ('\n'), pushing down the previous Line 1 to Line 2
		sed -i "1 s|^|"${line_num_when_error}"\n|" "${word_list_filename}"
		total_line_num=$(("${total_line_num}"+1))
		line_num_of_last_word_used="${line_num_when_error}"
	fi

	# The arithmetic expansion can be performed using the double parentheses ((...)) and $((...)) 
	local line_num_of_next_word=$(("${line_num_of_last_word_used}"+1))
	
	if [[ "$line_num_of_next_word" -gt "$total_line_num" ]]; then
        line_num_of_next_word="${line_num_when_error}"
    fi

    # Make sure of the last '|' before the ending '"'. An error "unterminated `s' command" without it
    sed -i "1 s|"${line_num_of_last_word_used}"|"${line_num_of_next_word}"|" "${word_list_filename}"
    
	# Use awk's variable assignment feature with '-v'
	echo $(awk -v line_num="${line_num_of_next_word}" 'FNR==line_num' $1)
}

show_help_menu() {
	local help_msg="
		NAME
			launch a Web dictionary, Cambridge (en) or BEOLINGUS (de), with a word
			cyclically chosen from the given file on the selected browser
		SYNOPSIS
			word_of_the_day.sh -f|--file filename --firefox|--chrome
		DESCRIPTION
			-f, --file
				a file name containing a list of words, one per line
			--firefox
				use Mozilla Firefox
			--chrome
				use Google Chrome
			-h, --help
				display this help and exit
		"
	
	# echo $help_msg does NOT retain the new lines!
	# After expanding, the enclosing double quotes stop so-called '(field) splitting (via $IFS) and pathname expansion (a.k.a. globbing)'
	echo "${help_msg}"
}

if [[ $# -eq 0 ]]; then
	show_help_menu
	exit
else
	while [[ "$1" != "" ]]; do
		case $1 in
			-f | --file)	shift # Need this to read the filename followed by '-f' or '--file'
							word_list_filename=$1 # $1 is the first function input parameter
							;;
			--firefox)		browser='firefox'
							;;
			--chrome)		browser='google-chrome-stable'
							;;	
			-h | --help)	show_help_menu
							exit 1
							;;
			*)				show_help_menu # Unrecognisable input parameter
							exit 1
							;;
		esac
		shift
	done
fi

if [[ -z "${browser}" ]]; then
	echo "No browser specified. Use --firefox or --chrome!"
	exit 1
elif [[ $(wc -c "${word_list_filename}" | awk '{print $1}') -eq 0 ]]; then
	# Look into the file size with '-c'
	echo "The file is empty!"
	exit 1
elif [[ -f "${word_list_filename}" ]]; then
	word=$(get_word "${word_list_filename}")

	# & = Fork(), creating a child process and gracefully exit this .sh
	# The following does NOT work: $(which $browser) "https://dictionary.cambridge.org/dictionary/english/$word" &
	#  $(which $browser) gets first executed and this script exits to Terminal. THEN, the whole line gets executed and hangs
	browser_dir_and_exec=$(which "${browser}")
	"$browser_dir_and_exec" "https://dictionary.cambridge.org/dictionary/english/${word}" &
fi

#"https://dict.tu-chemnitz.de/dings.cgi?service=deen&opterrors=0&optpro=0&query=$word&iservice="
# https://dict.tu-chemnitz.de/deutsch-englisch/$word.html





