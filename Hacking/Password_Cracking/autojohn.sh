#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        autojohn.sh
#
# Description:  A script that is meant to simplify and automate the usage of the
#               powerful JohnTheRipper password cracking tool.
#               At the moment, it is solely intended for dictionary attacks.
#
# Usage:        ./autojohn.sh --help|-h
#               ./autojohn.sh --info
#               ./autojohn.sh <HASHES_FILE>
#               ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME>
#               ./autojohn.sh --sessions
#               ./autojohn.sh --status <SESSION_NAME>
#
#
# --TODO--
# - improve and optimize code
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

DICT_DIR=~/dictionaries     # each wordlist in this directory *MUST* be a ".txt" file
POTS_DIR=~/.john            # here you will find the cracked passwords for each session


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}

usage() {
    echo "Usage:"
    echo "  - Show this help:"
    echo "    ./autojohn.sh --help|-h"
    echo "  - Show information about dictionaries:"
    echo "    ./autojohn.sh --info"
    echo "  - List detected hash formats for file <HASHES_FILE>:"
    echo "    ./autojohn.sh <HASHES_FILE>"
    echo "  - Start cracking hashes with dictionary attack:"
    echo "    ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME>"
    echo "  - Show sessions (both finished and running):"
    echo "    ./autojohn.sh --sessions"
    echo "  - Show currently found passwords in a running session:"
    echo "    ./autojohn.sh --status <SESSION_NAME>"
}

logo() {
    echo "                        "
    echo " /\   _|_ _   | _ |_ ._ "
    echo "/--\|_||_(_)\_|(_)| || |"
    echo "                        "
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"john"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done

if [[ ! -d "$DICT_DIR" ]] ; then
    echo "Error! Dictionaries directory not found: $DICT_DIR"

    exit 1
fi

if [[ ! -d "$POTS_DIR" ]] ; then
    echo "Error! Pots directory not found: $POTS_DIR"

    exit 1
fi


# MAIN -------------------------------------------------------------------------

if [[ ! "$#" -le 3 ]] ; then
    usage

    exit 1
else
    FILE=$1

    if [[ "$#" -eq 1 ]] ; then
        logo

        if [[ "$FILE" == "--help" || "$FILE" == "-h" ]] ; then
            usage

            exit 0
        elif [[ "$FILE" == "--info" ]] ; then
            DICT_NUM=$(ls -1 $DICT_DIR/*txt | wc -l | awk '{ print $1 }')
            DICT_SIZ=$(du -ch $DICT_DIR/*txt | tail -1 | awk '{ print $1 }')

            echo "[+] Dictionaries directory:  $DICT_DIR"
            echo "[+] Number of dictionaries:  $DICT_NUM"
            echo "[+] Total dictionaries size: $DICT_SIZ"
            echo

            exit 0
        elif [[ "$FILE" == "--sessions" ]] ; then
            for SESSION in $(ls -1 $POTS_DIR/*.pot | sed -r 's/.*\/(.*).pot.*/\1/') ; do
                if [[ -f "$POTS_DIR/$SESSION.progress" ]] ; then
                    echo "[R] $SESSION"
                else
                    echo "[+] $SESSION"
                fi
            done

            echo

            exit 0
        fi

        if [[ ! -f "$FILE" ]] ; then
            echo "Error! Hashes file not found: $FILE"

            exit 1
        fi

        echo "Detected hash formats:"
        echo

        john --list=unknown $FILE 2>&1 | grep -F -- '--format=' | grep -v '\$' | cut -d'=' -f2 | cut -d'"' -f1 | sort | awk '{ $2 = $1 ; $1 = "-" ; print $0 }'

        echo
        echo "Now, to start cracking, run:"
        echo "./autojohn.sh $FILE <FORMAT> <SESSION_NAME>"

        exit 0
    elif [[ "$#" -eq 2 ]] ; then
        logo

        if [[ "$1" == "--status" ]] ; then
            SESSION=$2
            PROGRESS_FILE=$POTS_DIR/$SESSION.progress

            if [[ -f "$PROGRESS_FILE" ]] ; then
                echo "Found passwords in session \"$SESSION\"":
                echo

                cat $PROGRESS_FILE | grep '(' | grep -v DONE | grep -v Loaded | grep -v Node

                echo
            else
                echo "No cracking is currently running for session \"$SESSION\"."
                echo
            fi
        fi

        exit 0
    elif [[ "$#" -eq 3 ]] ; then
        logo

        if [[ ! -f "$FILE" ]] ; then
            echo "Error! Hashes file not found: $FILE"

            exit 1
        fi

        FORMAT=$2
        SESSION=$3
        POT_FILE=$POTS_DIR/$SESSION.pot
        PROGRESS_FILE=$POTS_DIR/$SESSION.progress
        STATUS=$(john --show --pot=$POT_FILE --format=$FORMAT $FILE | grep -F cracked)
        C=$(echo $STATUS | grep -c -F ', 0 left')

        if [[ $C -eq 1 ]] ; then
            echo "All passwords already found! Exiting..."
            echo

            exit 0
        fi

        OS=$(uname -s)

        if [[ $OS == "Linux" ]] ; then
            CORES=$(grep -c ^processor /proc/cpuinfo)
        elif [[ $OS == "FreeBSD" ]] ; then
            CORES=$(sysctl -n hw.ncpu)
        else
            CORES=1
        fi

        N=$(cat $FILE | wc -l | tr -d ' ')

        echo "[+] Session name: $SESSION"
        echo "[+] Total hashes: $N"
        echo "[+] Hash format:  $FORMAT"
        echo "[+] # of cores:   $CORES"
        echo
        echo "[START] $(date)"
        echo

        for DICT in $(ls -1Sr $DICT_DIR/*.txt) ; do
            echo "[>] $DICT"

            john --wordlist=$DICT --format=$FORMAT --nolog --fork=$CORES --session=$SESSION --pot=$POT_FILE $FILE >> $PROGRESS_FILE 2>&1

            STATUS=$(john --show --pot=$POT_FILE --format=$FORMAT $FILE | grep -F cracked)
            echo $STATUS
            C=$(echo $STATUS | grep -c -F ', 0 left')

            if [[ $C -eq 1 ]] ; then
                echo
                echo "Congratulations! All passwords found!"

                break
            fi
        done

        echo
        echo "[END] $(date)"
        echo
        echo "Found passwords (saved in $POT_FILE):"

        cat $POT_FILE | cut -d':' -f2 | sort -u

        if [[ -f "$PROGRESS_FILE" ]] ; then
            rm -f $PROGRESS_FILE
        fi

        echo

        exit 0
    fi
fi
