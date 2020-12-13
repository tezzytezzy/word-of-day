#!/usr/bin/env bash

set -eo pipefail

filename=./word_of_the_day_english.sh

# . ${filename} is equivalent
# SC1090: ShellCheck can't follow non-constant source. Use a directive to specify location.
# shellcheck disable=SC1090
source ${filename} 

# Output should be help menu for all
if [[ "${filename}" != show_help_menu ]]; then exit 2; fi

if [[ "$("${filename}" --help)" != show_help_menu ]]; then exit 3; fi

if [[ "$("${filename}" -h)" != show_help_menu ]]; then exit 4; fi

if [[ "$("${filename}" abc)" != show_help_menu ]]; then exit 5; fi

if [[ "$("${filename}" -f ./abc)" != show_help_menu ]]; then exit 6; fi

if [[ "$("${filename}" --file ./abc)" != show_help_menu ]]; then exit 7; fi

# # Output should be help menu for all
# if [[ "$(./word_of_the_day_english.sh)" != show_help_menu ]]; then exit 2; fi

# if [[ "$(./word_of_the_day_english.sh --help)" != show_help_menu ]]; then exit 3; fi

# if [[ "$(./word_of_the_day_english.sh -h)" != show_help_menu ]]; then exit 4; fi

# if [[ "$(./word_of_the_day_english.sh abc)" != show_help_menu ]]; then exit 5; fi

# if [[ "$(./word_of_the_day_english.sh -f ./abc)" != show_help_menu ]]; then exit 6; fi

# if [[ "$(./word_of_the_day_english.sh --file ./abc)" != show_help_menu ]]; then exit 7; fi