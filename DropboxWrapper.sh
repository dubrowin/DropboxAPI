#!/bin/bash

DIR="/temp"
AUTHTMP="/tmp/$( basename "$0" ).authtmp"
## Reset IFS to handle spaces in names
OIFS="$IFS"
IFS=$'\n'

case $1 in
	-d | --debug )
		echo "Enabling Debug"
		DEBUG=Y
		shift 
	;;
esac

function Debug {
    if [ "$DEBUG" == "Y" ]; then
        echo -e "$( date +"%b %d %H:%M:%S" ) $1"
    fi
}

function logit {
	Debug $1
}

function RequestFile {
    if [ -z "$1" ]; then  
        echo "ERROR: Need to request a file"
        exit 1
    else
        DBFILE="$1"
    fi
}

function RequestSearch {
    if [ -z "$1" ]; then  
        echo "ERROR: Need to provide a search string"
        exit 1
    else
        DBFILE="$1"
    fi
}

function Success {
	Debug "Success"
}

function Fail {
	Debug "Fail"
	echo "Fail"
	exit 1
}


function GetAuth {
	if [ -z "$AUTH" ]; then
		Debug "executing authorization request"
		aws --profile shlomo ssm get-parameters --names "Dropbox" --region us-east-2 > $AUTHTMP && Success || Fail
		AUTH=`grep Value $AUTHTMP | cut -d \" -f 4`
	fi
	source /Users/shlomod/docs/dropbox-encfs/enc-temp/dropbox-api/DropboxAPI.sh
}

case $0 in
	*DropboxSearch* )
		RequestSearch $1
		GetAuth
		DropboxSearch $DBFILE
	;;
	*DropboxUpload* )
		RequestFile $1
		GetAuth
		DropboxUpload $DBFILE
	;;
	*DropboxDelete* )
		RequestFile $1
		GetAuth
		DropboxDelete $DBFILE
	;;
	*)
		echo -e "\n\tERROR: unknown command ($0)\n"
		exit 1
	;;

esac

# Reset IFS to what it was before
IFS="$OIFS"

