#! /bin/bash 

## USAGE
## * To dump:
## ** example: ./cloudant.sh -d -I -n nodered -f local.doc
## * To upload:
## ** example: ./cloudant.sh -u -L -n humix-audiobox-db -f local.doc

##START: FUNCTIONS
usage(){
    echo
	echo "Usage: $0 [-d|-u] [-L|-I] -n <DB_NAME> -f <dump_FILE>"
	echo -e "\t-d   Run script in dump(Backup) mode."
	echo -e "\t-u   Run script in upload(Restore) mode."
	echo -e "\t-L   Local CouchDB path(http://127.0.0.1:5984/)."
	echo -e "\t-I   IBM cloudant DB path."
	echo -e "\t-n   CouchDB Database name to dump/upload."
	echo -e "\t-f   File to dump-to/upload-from."
#	echo -e "\t-c   Create DB on demand, if they are not listed."
	echo -e "\t-q   Run in quiet mode. Suppress output, except for errors and warnings."
#	echo -e "\t-T   Add datetime stamp to output file name (dump Only)"
	echo -e "\t-V   Display version information."
	echo -e "\t-h   Display usage information."
	echo
	exit 1
}

SCRIPTVERSION()
{
	echo
	echo -e "\t** IBM Bluemix cloudant shell script version: $scriptversionnumber **"
	exit 1
}

# If quiet option: Setup echo mode and curl '--silent' opt
VERBOSEMODE()
{
	if [ "$verboseMode" = true ]; then
		curlSilentOpt=""
		echoVerbose=true
	else
		curlSilentOpt="--silent"
		echoVerbose=false
	fi
	
	exit 1
}

TIMESTAMP()
{
	# If -T (timestamp) option, append datetime stamp ("-YYYYMMDD-hhmmss") before file extension
	datetime=`date "+%Y%m%d-%H%M%S"`                      # Format: YYYYMMDD-hhmmss
	echo $datetime
	exit 1
}

DB_URL()
{
	if [ "$cloudantdb" = true ]; then
		db_path=$cloudant_path$db_name
	elif [ "$localdb" = true ]; then
		db_path=$local_path$db_name
	fi
}

# Catch no args:
if [ "x$1" = "x" ]; then
    usage
fi

# Default Args
scriptversionnumber="0.3.0"
username="4fa75cd1-58c9-40f8-b564-f0ea711bd506-bluemix"
password="9490c5b340b894b4db5f02b357cf59bf1a6fec84543e2080bcb1049cd2d4a4f5"
local_path="http://127.0.0.1:5984/"
cloudant_path="https://4fa75cd1-58c9-40f8-b564-f0ea711bd506-bluemix.cloudant.com/"
localdb=false
cloudantdb=false
dump=false
upload=false
port=5984
#createDBsOnDemand=false
verboseMode=true
#compress=false

while getopts ":h?L?I?n:f:c?q?z?T?v?V?d?u?" opt; do
    case "$opt" in
	h) usage;;
	d) dump=true ;;
	u) upload=true ;;
	L) localdb=true ;;
	I) cloudantdb=true ;;
	n) db_name="$OPTARG" ;;
	f) file_name="$OPTARG" ;;
	c) createDBsOnDemand=true;;
	q) VERBOSEMODE;;
	T) TIMESTAMP;;
	v|V) SCRIPTVERSION;;
	:) echo "... ERROR: Option \"-${OPTARG}\" requires an argument"; usage ;;
	*|\?) echo "... ERROR: Unknown Option \"-${OPTARG}\""; usage;;
	esac
done

#$echoVerbose && echo "... INFO: "
#$echoVerbose && echo "... INFO: "

# Trap unexpected extra args
shift $((OPTIND-1))
[ "$1" = "--" ] && shift
if [ ! "x$@" = "x" ]; then
	echo "... ERROR: Unknown Option \"$@\""
	usage
fi

# Handle invalid dump/upload states:	
if [ $dump = true ]&&[ $upload = true ]; then
	echo "... ERROR: Cannot pass both '-b' and '-r'"
	usage
elif [ $dump = false ]&&[ $upload = false ]; then
	echo "... ERROR: Missing argument '-b' (dump), or '-r' (upload)"
	usage
fi

# Handle invalid Local/IBM cloudant states:	
if [ $localdb = true ]&&[ $cloudantdb = true ]; then
	echo "... ERROR: Cannot pass both '-L' and '-I'"
	usage
elif [ $localdb = false ]&&[ $cloudantdb = false ]; then
	echo "... ERROR: Missing argument '-L' (dump), or '-I' (upload)"
	usage
fi

# Handle empty args
# db_name
if [ "x$db_name" = "x" ]; then
	echo "... ERROR: Missing argument '-n <DB_NAME>'"
	usage
fi

# file_name	
if [ "x$file_name" = "x" ]; then
	echo "... ERROR: Missing argument '-f <FILENAME>'"
	usage
fi

# Combine URL and DB name
DB_URL

### If user selected dump, run the following code:
if [ $dump = true ]&&[ $upload = false ]; then
    #################################################################
    ####################### DUMP START ##############################
    #################################################################
	$echoVerbose && echo "... INFO: Dump database \"$db_name\" from $db_path"
	if [ "$cloudantdb" = true ]; then
		couchdb-dump --json-module=json $db_path -u $username -p $password > $file_name
	elif [ "$localdb" = true ]; then
		couchdb-dump --json-module=json $db_path > $file_name
	fi

### Else if user selected upload:
elif [ $dump = false ]&&[ $upload = true ]; then
	#################################################################
	###################### UPLOAD START #############################
	#################################################################

	# Check if input file not exists:
	if [ ! -f ${file_name} ]; then
		echo "... ERROR: Input file ${file_name} not found."
		exit 1
	fi

	$echoVerbose && echo "... INFO: Upload database \"$db_name\" into $db_path"
	if [ "$cloudantdb" = true ]; then
		couchdb-load --json-module=json --input=$file_name $db_path -u $username -p $password
	elif [ "$localdb" = true ]; then
		couchdb-load --json-module=json --input=$file_name $db_path
	fi

	#### VALIDATION END
#	$echoVerbose && echo "... INFO: Checking for database"
fi

exit 1

