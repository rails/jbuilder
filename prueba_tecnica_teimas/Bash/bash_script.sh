#! /bin/bash

show_help() {
    cat << EOF
Usage: $0 <directory> <keyword>

This script searches through all files in the specified directory for the given keyword.
It counts the total number of files in the given directory, the number of files containing the keyword, and
the total number of lines that contain the keyword.

Arguments:
  <directory>   The directory to search in.
  <keyword>     The keyword to search for in the files.

Example:
  $0 /path/to/directory keyword

EOF
    exit 0
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
fi

if [ $# -ne 2 ]; then
    echo "Usage: $0 <directory> <keyword>"
    echo "Try '$0 --help' for more information."
    exit 1
fi

DIRECTORI=$1
KEY=$2
NUMBER_FILES=0
NUMBER_LINES=0
FILES_WITH_KEY=0

if [ ! -d "$DIRECTORI" ]; then
    echo "The directory '$DIRECTORI' does not exist"
    exit 1
fi

for file in "$DIRECTORI"/*; do
    if [ -f "$file" ]; then
        NUMBER_FILES=$((NUMBER_FILES+1))
        lines=$(grep -ci "$KEY" "$file")
        if [ "$lines" -gt 0 ]; then
            FILES_WITH_KEY=$((FILES_WITH_KEY+1))
            NUMBER_LINES=$((NUMBER_LINES+lines))
            echo "The file '$file' has $lines lines with the key '$KEY'"
        fi
    fi
done

echo "Total number of files: $NUMBER_FILES"
echo "Total number of files with the key '$KEY': $FILES_WITH_KEY"
echo "Total number of lines with the key '$KEY': $NUMBER_LINES"