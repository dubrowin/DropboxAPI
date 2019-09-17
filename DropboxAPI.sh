logit "reached DropboxAPI.sh"

#########################
## Variables
#########################
#DEBUG="Y"
CURLOPTS="-sS"
FEEDBACK=""
ERROR=""

#########################
## Checks
#########################
logit "checking for AUTH"
if [ "$AUTH" == "" ]; then
    logit "ERROR: AUTH ($AUTH) is empty, need an authorization key, exiting"
    exit 1
fi

#########################
## Operational Functions
#########################
#logit "starting to load Functions"

#logit "loading DropboxDebug"
function DropboxDebug {
    if [ "$DEBUG" == "Y" ]; then
        logit "$( date +"%b %d %H:%M:%S" ) $1"
    fi

}

DropboxDebug "loading DropboxSuccess"
function DropboxSuccess {
    DropboxDebug "SUCCESS ($1)"
}

DropboxDebug "loading DropboxFail"
function DropboxFail {
    ERROR=1
    logit "\n\tFAIL ($1): $FEEDBACK\n"
}

DropboxDebug "loading DropboxFileCheck"
function DropboxFileCheck {
    if [ -z "$DBFILE" ]; then  
        ERROR=1
        logit "ERROR: Variable DBFILE needs to be set ($DBFILE)"
        exit 1
    fi

    STAT=`echo $DBFILE | grep "^./" -c ||true`
    DropboxDebug "STAT $STAT"

    if [ $STAT != 0 ]; then
        ERROR=1
        logit "\n\t ERROR: no leading ./ in DBFILE Variable ($DBFILE)\n"
        exit 1
    fi
}

DropboxDebug "loading DropboxDirCheck"
function DropboxDirCheck {
    if [ -z "$DIR" ]; then  
        ERROR=1
        DropboxDebug "ERROR: Variable DIR needs to be set ($DIR)"
        exit 1
    fi

    STAT=`echo $DIR | grep "/$" -c ||true`
    DropboxDebug "STAT $STAT"

    if [ $STAT != 0 ]; then
        ERROR=1
        DropboxDebug "\n\t ERROR: no trailing / in DIR Variable ($DIR)\n"
        exit 1
    fi

}

#########################
## API Calls
#########################
DropboxDebug "loading DropboxDelete"
function DropboxDelete {

    DropboxFileCheck
    DropboxDirCheck

    DropboxDebug "curl $CURLOPTS -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header \"Authorization: Bearer AUTH\" \
    --header 'Content-Type: application/json' \
    --data \"{\"path\":\"$DIR/$DBFILE\"}\" && DropboxSuccess \"api call\" || DropboxFail \"api call\""

    FEEDBACK=`curl $CURLOPTS -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header "Authorization: Bearer $AUTH" \
    --header 'Content-Type: application/json' \
    --data "{\"path\":\"$DIR/$DBFILE\"}" && DropboxSuccess "api call" || DropboxFail "api call"`

    FEEDBACK2=`echo "$FEEDBACK" | grep -ci error||true`

    if [ $FEEDBACK2 != 0 ]; then
        DropboxFail "action"
    else
        DropboxSuccess "action"
    fi
}

DropboxDebug "loading DropboxSearch"
function DropboxSearch {

    DropboxFileCheck
    DropboxDirCheck

    FEEDBACK=`curl $CURLOPTS -X POST https://api.dropboxapi.com/2/files/search \
    --header "Authorization: Bearer $AUTH" \
    --header 'Content-Type: application/json' \
    --data "{\"path\":\"$DIR\",\"query\":\"$DBFILE\",\"mode\":{\".tag\":\"filename\"} }" && DropboxSuccess "api call" || DropboxFail "api call"`

    FEEDBACK2=`echo "$FEEDBACK" | grep -ci error||true`
    if [ $FEEDBACK2 != 0 ]; then
        DropboxFail "action"
    else
        DropboxSuccess "action"
    fi

    if [ "$ERROR" != 1 ]; then  
        # Everything is fine, keep going
        echo "$FEEDBACK" | tr ',' '\n' | grep path_display | cut -d \" -f 4||true
	if [ "$VERBOSE" == "Y" ]; then
		echo $FEEDBACK
	fi
    fi

}

DropboxDebug "loading DropboxUpload"
function DropboxUpload {

    DropboxFileCheck
    DropboxDirCheck

    FEEDBACK=`curl $CURLOPTS -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $AUTH" \
    --header 'Content-Type: application/octet-stream' \
    --header "Dropbox-API-Arg: {\"path\":\"${DIR}/${DBFILE}\",\"autorename\":true}" \
    --data-binary @"${DBFILE}" && DropboxSuccess "api call" || DropboxFail "api call"`

    FEEDBACK2=`echo "$FEEDBACK" | grep -ci error||true`

    DropboxDebug "FEEDBACK: $FEEDBACK  FEEDBACK2: $FEEDBACK2"

    if [ $FEEDBACK2 != 0 ]; then
        DropboxFail "action"
    else
        DropboxSuccess "action"
    fi
}
logit "Finished reading DropboxAPI.sh"
