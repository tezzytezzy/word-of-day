#!/usr/bin/env bash
#
# Unit testing script
set -eo pipefail

filename=./word_of_the_day.sh
_non_existent_file='abc123.txt'
_zero_size_file='./zero.txt'

# . ${filename} is equivalent
# SC1090: ShellCheck can't follow non-constant source. Use a directive to specify location.
# shellcheck disable=SC1090
source ${filename} 

if [[ $(check_inputs) != $(show_help_msg) ]]; then exit 2; fi

if [[ $(check_inputs --help) != $(show_help_msg) ]]; then exit 3; fi

if [[ $(check_inputs -h) != $(show_help_msg) ]]; then exit 4; fi

if [[ $(check_inputs "${_non_existent_file}") != $(show_help_msg) ]]; then exit 5; fi


if [[ $(check_inputs -f "${_non_existent_file}" --firefox) != $(show_no_filename_msg) ]]; then exit 6; fi

if [[ $(check_inputs --file "${_non_existent_file}" --chrome) != $(show_no_filename_msg) ]]; then exit 7; fi


if [[ $(touch "${_zero_size_file}"; check_inputs --file "${_zero_size_file}" --firefox) != $(show_empty_file_msg) ]]; then exit 8; fi
rm ${_zero_size_file}

###
# the following two tests make sure the first line has a number
export word_list_filename=./english_words.txt
search_word_in_the_file
if [[ $(awk 'FNR==1' "${word_list_filename}") != +([[:digit:]]) ]]; then exit 9; fi

export word_list_filename=./german_words.txt
search_word_in_the_file
if [[ $(awk 'FNR==1' "${word_list_filename}") != +([[:digit:]]) ]]; then exit 10; fi
###


selected_word='Heiz\326lr\334cksto\337abd\304mpfung' # Heizölrückstoßabdämpfung
if [[ $(decode_german_letter "${selected_word}") != "Heiz%D6lr%DCcksto%DFabd%C4mpfung" ]]; then exit 11; fi

selected_word='Gr\334nfl\334gelb\334lb\334l' # Grünflügelbülbül
if [[ $(decode_german_letter "${selected_word}") != "Gr%DCnfl%DCgelb%DClb%DCl" ]]; then exit 12; fi

selected_word='Übermäßig'
if [[ $(decode_german_letter "${selected_word}") != "${selected_word}" ]]; then exit 13; fi


if [[ $(launch_browser dummy_word dummy_browser) != $(show_no_browser_installed_msg) ]]; then exit 14; fi


export use_german=0
browser="${FIREFOX_BROWSER}"

launch_browser panopticon "${browser}"
if [[ $(pgrep -c "${browser}") == 0 ]]; then exit 15; fi

sleep 5
pkill -f "${browser}"
sleep 3


export use_german=0
launch_browser gemütlichkeit "${CHROME_BROWSER}"

sleep 10

# "chrome" - The middle word of "google-chrome-stable": Bash only string operation
chrome_process_name="${CHROME_BROWSER:7:6}"

if [[ $(pgrep -c "${chrome_process_name}") == 0 ]]; then exit 16; fi

pkill --oldest "${chrome_process_name}"