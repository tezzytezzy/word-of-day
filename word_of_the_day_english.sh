#!/usr/bin/env bash
#
# Launch a selected browser with a cyclically chosen word of day from the file

set -eo pipefail
# e: The script will exit on an error
# u: <ABORTED> Treat unset variables as an error when performing parameter expansion
#  This gives an error, "$1: unbound variable", when taking in input parameter of a command
# o pipefail: If any element of the pipeline fails, then the pipeline as a whole will fail
#  This is dangerous as pipelines only return a failure if the last command errors by default


# All variables in bash are global by default
# Global variables should be in ALL_CAPITAL_CASE with readonly designation 
# Variable substitution within a sting should be "${variable}", NOT just $variable
# Use POSIX-compliant [[ ]], i.e., ksh, zsh, etc., rather than []

get_word() {
  # local keyword: can only be used in a function

  # Default line number when an error occurs
  local line_num_when_error=1
  
  local total_line_num
  local line_num_of_last_word_used
  local before_carriage_return_removed

  total_line_num=$(wc -l "${word_list_filename}" | awk '{print $1}') # "$1" = first field (column) reference

  line_num_of_last_word_used=$(awk 'FNR==1' "${word_list_filename}") # FNR = line number in the current file

  line_num_of_last_word_used=$(remove_carriage_return "${line_num_of_last_word_used}")


  # https://www.gnu.org/software/bash/manual/bash.html#Pattern-Matching (extended patterns)
  # +(pattern-list): Matches one or more occurrences of the given patterns
  # [:digit:]: POSIX's character classes  
  if [[ "${line_num_of_last_word_used}" != +([[:digit:]]) ]]; then
    # Must be a brand new file without the last used word number in Line 1
    #  Insert a number pointing to the first word from the top
    
    # Normally sed use '/' character delimiter with '\' escape character, like below
    #  sed -i '1s/\$line_num_of_last_word_used/\$line_num_of_next_word/' $1
    # BUT, we can use '|' or any character that doesn't appear in the regexp itself.
    # The usual opening and closing ''' does NOT substitute variables inside them, MUST use '"'
    # Make sure of the last '|' before the ending '"'. An error "unterminated `s' command" without it
    # It inserts a number at the very begininng of the file PLUS a newline ('\n'), pushing down the previous Line 1 to Line 2
    sed -i "1 s|^|${line_num_when_error}\n|" "${word_list_filename}"
    line_num_of_last_word_used="${line_num_when_error}"
  fi

  # The arithmetic expansion can be performed using the double parentheses ((...)) and $((...)) 
  local line_num_of_next_word=$(("${line_num_of_last_word_used}"+1))
  
  if [[ "${line_num_of_next_word}" -gt "${total_line_num}" ]]; then
    line_num_of_next_word="${line_num_when_error}"
  fi

  # Make sure of the last '|' before the ending '"'. An error "unterminated `s' command" without it
  sed -i "1 s|${line_num_of_last_word_used}|${line_num_of_next_word}|" "${word_list_filename}"

  # Use awk's variable assignment feature with '-v'
  before_carriage_return_removed=$(awk -v line_num="${line_num_of_next_word}" 'FNR==line_num' "$1")
  # echo "$(echo "${before_carriage_return_removed}" | sed "s|\r||")"

  # Need `echo` to return value back to the caller
  # Without the below line, an error of "SC2005: Useless echo? Instead of 'echo $(cmd)', just use 'cmd'"
  # shellcheck disable=SC2005
  echo "$(remove_carriage_return "${before_carriage_return_removed}")"
}

remove_carriage_return() {
  # Enter a carriage return ('^M') by pressing Ctrl+V and Ctrl+M
  # (base) to@mx:~$ echo abc^M | od -c
  # 0000000   a   b   c  \r  \n
  # 0000005
  # (base) to@mx:~$ echo abc^M | sed 's|\r||' | od -c
  # 0000000   a   b   c  \n
  # 0000004

  # SC2001: See if you can use ${variable//search/replace} instead.
  #  We need to use `echo` to return value to the function caller
  # shellcheck disable=SC2001,SC2005
  echo "$(echo "$1" | sed "s|\r||")"
}

show_help_menu() {
  local help_msg

  help_msg="
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
      --german
        a flag to launch the German dictionary
      -h, --help
        display this help and exit
    "
  
  # echo $help_msg (without quotes) does NOT retain the new lines!
  # After expanding, the enclosing double quotes stop '(field) splitting (via $IFS) and globbing(i.e., pathname expansion))'
  echo "${help_msg}"
}

decode_german_letter () {
  # Convert utf-8 encoding to "ISO-8859-1": from octal to hex
  # In some cases (on UNIX terminal), "Küste" gets passed into this function as "K\334ste"

  # `declare` inside the function behaves just like `local`
  declare -A char_map # `-A` = associative array

  # `decoded_word` gets assgined with "K334ste" in value although "$1" comes in as "K\334ste"!
  local decoded_word="$1"

  char_map=(
    # ä("\304"), Ä("\344"), ü("\334"), Ü("\374"), ö("\326"), Ö("\366") and ß("\337")
    ["\304"]="%C4" ["\344"]="%E4"
    ["\334"]="%DC" ["\374"]="%FC"
    ["\326"]="%D6" ["\366"]="%F6"
    ["\337"]="%DF"
  )

  for octal in "${!char_map[@]}"; do
    # decoded_word=${"$decoded_word"//"$_temp"/$"char_map[${octal}]"} gives "Bad substitution error"
    #  Not sure why... Bash substring substituion above is not POSIX compliant
    #  See https://tldp.org/LDP/abs/html/string-manipulation.html
    # `${octal:1}` drops the first character "\": "\334" -> "334". The left-most character being position 0
    
    # shellcheck disable=SC2001
    decoded_word=$(echo "${decoded_word}" | sed "s|${octal:1}|${char_map[${octal}]}|g")    
  done

  echo "${decoded_word}"
}

if [[ $# -eq 0 ]]; then
  show_help_menu
  exit
else
  while [[ "$1" != "" ]]; do
    case $1 in
      -f | --file)
        shift # Need this to read the filename followed by '-f' or '--file'
        word_list_filename=$1 # $1 is the first function input parameter
        ;;
      --firefox)
        browser='firefox'
        ;;
      --chrome)
        browser='google-chrome-stable'
        ;;
      --german)
        use_german=0
        ;;
      -h | --help)
        show_help_menu
        exit 1
        ;;
      *)
        show_help_menu # Unrecognisable input parameter
        exit 1
        ;;
    esac
    shift
  done
fi

if [[ -z "${browser}" ]]; then # `-z` True if the length of the tested is zero
  echo "No browser specified. Use --firefox or --chrome!"
elif [[ ! -f "${word_list_filename}" ]]; then
  echo "${word_list_filename} does not exist!"
elif [[ $(wc -c "${word_list_filename}" | awk '{print $1}') -eq 0 ]]; then
  # Look into the file size with '-c'
  echo "The file is empty!"
else
  word=$(get_word "${word_list_filename}")
  word=$(decode_german_letter "${word}")

  # & = Fork(), creating a child process and gracefully exit this .sh
  # The following does NOT work: $(which $browser) "https://dictionary.cambridge.org/dictionary/english/$word" &
  #  $(which $browser) gets first executed and this script exits to Terminal. THEN, the whole line gets executed and hangs
  browser_dir_and_exec=$(which "${browser}")
  
  if [[ -z "${use_german}" ]]; then
    echo "$browser_dir_and_exec" "https://dictionary.cambridge.org/dictionary/english/${word}" &
  else
    echo "$browser_dir_and_exec" "https://dict.tu-chemnitz.de/deutsch-englisch/${word}.html" &
  fi
fi
