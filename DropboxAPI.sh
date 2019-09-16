
#########################
## Variables
#########################
#DEBUG="Y"
CURLOPTS="-sS"

#########################
## Checks
#########################

if [ -z $AUTH ]; then
    echo "ERROR: AUTH ($AUTH) is empty, need an authorization key, exiting"
    exit 1
fi

#########################
## Operational Functions
#########################
function DropboxDebug {
    if [ "$DEBUG" == "Y" ]; then
        echo -e "$( date +"%b %d %H:%M:%S" ) $1"
    fi

}

function DropboxSuccess {
    DropboxDebug "SUCCESS ($1)"
}

function DropboxFail {
    ERROR=1
    echo -e "\n\tFAIL ($1): $FEEDBACK\n"
}

function DropboxFileCheck {
    if [ -z "$FILE" ]; then  
        ERROR=1
        echo "ERROR: Variable FILE needs to be set ($FILE)"
        exit 1
    fi

    STAT=`echo $FILE | grep "^./" -c ||true`
    DropboxDebug "STAT $STAT"

    if [ $STAT != 0 ]; then
        ERROR=1
        echo -e "\n\t ERROR: no leading ./ in FILE Variable ($FILE)\n"
        exit 1
    fi
}

function DropboxDirCheck {
    if [ -z "$DIR" ]; then  
        ERROR=1
        Debug "ERROR: Variable DIR needs to be set ($DIR)"
        exit 1
    fi

    STAT=`echo $DIR | grep "/$" -c ||true`
    DropboxDebug "STAT $STAT"

    if [ $STAT != 0 ]; then
        ERROR=1
        Debug "\n\t ERROR: no trailing / in DIR Variable ($DIR)\n"
        exit 1
    fi

}

#########################
## API Calls
#########################

function DropboxDelete {

    DropboxFileCheck
    DropboxDirCheck

    Debug "curl $CURLOPTS -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header \"Authorization: Bearer AUTH\" \
    --header 'Content-Type: application/json' \
    --data \"{\"path\":\"$DIR/$FILE\"}\" && DropboxSuccess \"api call\" || DropboxFail \"api call\""

    FEEDBACK=`curl $CURLOPTS -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header "Authorization: Bearer $AUTH" \
    --header 'Content-Type: application/json' \
    --data "{\"path\":\"$DIR/$FILE\"}" && DropboxSuccess "api call" || DropboxFail "api call"`

    FEEDBACK2=`echo "$FEEDBACK" | grep -ci error||true`

    if [ $FEEDBACK2 != 0 ]; then
        DropboxFail "action"
    else
        DropboxSuccess "action"
    fi
}

function DropboxSearch {

    DropboxFileCheck
    DropboxDirCheck

    FEEDBACK=`curl $CURLOPTS -X POST https://api.dropboxapi.com/2/files/search \
    --header "Authorization: Bearer $AUTH" \
    --header 'Content-Type: application/json' \
    --data "{\"path\":\"$DIR\",\"query\":\"$FILE\",\"mode\":{\".tag\":\"filename\"} }" && DropboxSuccess "api call" || DropboxFail "api call"`

    FEEDBACK2=`echo "$FEEDBACK" | grep -ci error||true`
    if [ $FEEDBACK2 != 0 ]; then
        DropboxFail "action"
    else
        DropboxSuccess "action"
    fi

    if [ "$ERROR" != 1 ]; then  
        # Everything is fine, keep going
        echo "$FEEDBACK" | tr ',' '\n' | grep path_display | cut -d \" -f 4||true
    fi

}

function DropboxUpload {

    DropboxFileCheck
    DropboxDirCheck

    FEEDBACK=`curl $CURLOPTS -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $AUTH" \
    --header 'Content-Type: application/octet-stream' \
    --header "Dropbox-API-Arg: {\"path\":\"${DIR}/${FILE}\",\"autorename\":true}" \
    --data-binary @"${FILE}" && DropboxSuccess "api call" || DropboxFail "api call"`

    FEEDBACK2=`echo "$FEEDBACK" | grep -ci error||true`

    if [ $FEEDBACK2 != 0 ]; then
        DropboxFail "action"
    else
        DropboxSuccess "action"
    fi
}
