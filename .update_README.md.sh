#!/usr/bin/env bash

README=README.md

{
echo '# Scripts'
echo 'A collection of personal and useful shell scripts for Unix and GNU/Linux systems.'
echo '```'
find ./ -type f \( -iname \*.sh -o -iname \*.txt -o -iname \*.py -o -iname \*.sql \) | grep -v update_README.md.sh | sort
echo '```'
} > $README

