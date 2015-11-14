#!/bin/bash
#
# This program downloads search results from a given query string on a #selected servers:
#
# which is specified by user input upon execution of the program.
#
# The user may then decide to use a proxy file as to not become blacklisted by the servers. Proxyfile should be in the IP:PORT format.
# If a proxyfile is used, the program will switch proxies every 10 downloads to evade suspicion. 
#
# The source command is required to execute the script in order to change the http_proxy environmental
# varaible. If the user does not specify a proxyfile, nomral ./libgendownloader.sh can be used.
#
# If there is incomplete information from the curl requests or wget retries 25 times 
# without success (usually due to bad proxies or wrong file size) the program will save the bookID #
# to /path/to/searchquery/bookIDs.notfound for later processing.
# 
# In addition libgendownloader will also create a file called 'lastfile.txt'. This file contains the count of the ID it was currently processing along with the bookID number and the bookID file. This can be used in case you want to exit the script and return to processing the IDs for later.
# Usage: source libgendownloader.sh searchterm <bookIDfile>
#
# Be sure to place a '+' where spaces would normally go in searchterm. 
#
# Example 1.) When the user doesn't have a bookID file:
# source libgendownloader.sh Modular+Forms
#
# The directory Modular_Forms will be created to store the results.
# The user will then be prompted for a server option and whether a proxyfile is to be used.
#
# Example 2.) When then user has a preprocessed bookID file:
# source libgendownloader.sh Modular+Forms /home/user/Modular_Forms/bookIDs.notfound
# 
# Again the user will be prompted for a server and proxyfile.
# 
# Note: a proxyfile doesn't have to be used and you can download normally, but be advised
# that you may be blacklisted for too many downloads or webpage requests. 
#
# Written by: bubonic
# August 2015

if [ "$#" -lt 1 ]; then
    echo " " 
    echo "Usage: source libgendownloader.sh searchterm <bookIDfile>"
    echo "Besure to use a '+' where spaces go in searchterm"
    echo " "
    echo "Example: source libgendownloader.sh Automorphic+Forms"
    echo "Use absolute path for <bookIDfile> (i.e., /home/user/Automorphic_Forms/Automorphic+Forms.bookIDs)"
    echo "Written by: bubonic"
    return
fi

query=$1

if [ -n "$2" ]; then
	bookID_file=$2
	echo "BookID file: $bookID_file"
else
	bookID_file=$query.bookIDs
	echo "BookID file will be: $bookID_file"
fi

echo " "
echo "1) http://businesslibtechsciencebooksfreeaccess.org"
echo "2) http://scienceengineering.library.scilibgen.org"
echo "3) http://faith.freeonsciencelibraryguide.com/"
echo "4) http://croco.freeonsciencelibraryguide.com"
echo "5)* http://open.freeonsciencelibraryguide.com"
echo "6)* http://serious.freeonsciencelibraryguide.com"
echo "7)* http://gen.golibgen.com"
echo "* means working sites"
echo -ne "Select what server you want to use: "
read OPTION

if [ "$OPTION" -eq "1" ]; then
	HOST="http://businesslibtechsciencebooksfreeaccess.org"
elif [ "$OPTION" -eq "2" ]; then
	HOST="http://scienceengineering.library.scilibgen.org"
elif [ "$OPTION" -eq "3" ]; then
	HOST="http://faith.freeonsciencelibraryguide.com"
elif [ "$OPTION" -eq "4" ]; then
	HOST="http://croco.freeonsciencelibraryguide.com"
elif [ "$OPTION" -eq "5" ]; then
	HOST="http://open.freeonsciencelibraryguide.com"
elif [ "$OPTION" -eq "6" ]; then
	HOST="http://serious.freeonsciencelibraryguide.com"
else 
	HOST="http://gen.golibgen.com"
fi

echo " "
echo -e "1) Yes \t 2) No"
echo -ne "Would you like to use a proxyfile: "
read OPTION2
if [ "$OPTION2" -eq "1" ]; then
	echo -ne "Enter absolute path of proxyfile (i.e., /home/user/Proxies/proxies.txt): "
	read proxy_file
else
	http_proxy=""
	export http_proxy
fi


i=0
POS=0
count=0
varagent="Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:38.0) Gecko/20100101 Firefox/38.0"
DL_URL_PREFIX="http://store-k.free-college.org/noleech1.php?"
WGET_COUNTER=0
TERMINATED_COUNTER=0
CURL_COUNTER=0

change_proxy () {
	return_value="500"
	while [ "$return_value" !=  "200 OK" ]; do
                echo -ne "Changing Proxies..."
		proxy=`shuf -n 1 $proxy_file`
                proxy_addr=`echo $proxy | awk -F: '{print $1}'`
                proxy_port=`echo $proxy | awk -F: '{print $2}'`
                HPROXY=`echo "http://$proxy_addr:$proxy_port/"`
                return_value=`HEAD -d -p $HPROXY -t 12 http://www.google.com`
                if [ "$return_value" = "200 OK" ]; then
                        echo -ne "Connection to $HPROXY is a success!\n"
                        http_proxy=$HPROXY
                        export http_proxy
                else
                        echo "Connection to $HPROXY  failed!"
                fi
        done
}


DIR_NAME="${1//+/_}"

if [ ! -d "$DIR_NAME" ]; then
	mkdir $DIR_NAME
else
	echo "$DIR_NAME exists"
fi

cd $DIR_NAME

getBookIDs () { 
	curl_return_code=`curl --write-out %{http_code} -v --connect-timeout 90 --max-time 120 -A "$varagent" -o "libgensearch-"$i".html" --referer "$HOST" $HOST"/search.php?button="$query"&submit=Dig+for&search_type=magic&pos="$POS`
	if [ ! -e "libgensearch-"$i.html ]; then
		HTML_BYTES=0
	else
		HTML_BYTES=`wc -c < "libgensearch-"$i.html`
	fi

	while [ "$curl_return_code" -ne "200" ] || [ "$HTML_BYTES" -le "7000" ] ; do
		rm -rf "libgensearch-"$i.html
		echo "Return code is: $curl_return_code"
		echo "HTML file: $HTML_BYTES bytes"
		if [ "$OPTION2" -eq "1" ]; then
			change_proxy
		fi
		echo "Sleeping for 15 seconds..."
		sleep 15
		curl_return_code=`curl --write-out %{http_code} -v --connect-timeout 90 --max-time 120 -A "$varagent" -o "libgensearch-"$i".html" --referer "$HOST" $HOST"/search.php?button="$query"&submit=Dig+for&search_type=magic&pos="$POS`
		if [ ! -e "libgensearch-"$i.html ]; then
			HTML_BYTES=0
		else
			HTML_BYTES=`wc -c < "libgensearch-"$i.html`
		fi

		let CURL_COUNTER++
		if [ "$CURL_COUNTER" -eq "25" ]; then
			echo "I've tried to curl the page 25 times... I'm tired. Exiting."
			return
		fi
	done
	CURL_COUNTER=0
	NUM_OF_RESULTS=`cat "libgensearch-"$i.html | grep "records found" | cut -d ">" -f 3 | cut -d "<" -f 1 | sed -e 's/records found//g' | tr -d ' '`

	echo "Number of results: $NUM_OF_RESULTS books"
	if [ -z "$NUM_OF_RESULTS" ]; then
		echo "Error in obtaining bookIDs... quitting"
		return
	fi

	cat "libgensearch-"$i.html | grep "javascript:window.open" | cut -d "(" -f 2 | cut -d "=" -f 2 | cut -d "\"" -f 1 >> $bookID_file
	
	let i++

	if [ "$NUM_OF_RESULTS" -gt "50" ]; then
		R=$(($NUM_OF_RESULTS % 50))
		MULTIPLE=$((($NUM_OF_RESULTS - $R)/50))
	else
		MULTIPLE=0
	fi
	echo "Multiple: $MULTIPLE"
	sleep 60

	while [ "$i" -le "$MULTIPLE" ]; do
		PREV_POS=$POS
		POS=$(($i * 50))
		curl_return_code=`curl --write-out %{http_code} -v --connect-timeout 90 --max-time 120 -A "$varagent" -o "libgensearch-"$i.html --referer $HOST"/search.php?button="$query"&submit=Dig+for&search_type=magic&pos="$PREV_POS $HOST"/search.php?button="$query"&submit=Dig+for&search_type=magic&pos="$POS`
		if [ ! -e "libgensearch-"$i.html ]; then
			HTML_BYTES=0
		else
			HTML_BYTES=`wc -c < "libgensearch-"$i.html`
		fi


		while [ "$curl_return_code" -ne "200" ] || [ "$HTML_BYTES" -le "7000" ] ; do
			rm -rf "libgensearch-"$i.html
			echo "Return code is: $curl_return_code"
			echo "HTML file: $HTML_BYTES bytes"
			if [ "$OPTION2" -eq "1" ]; then
				change_proxy
			fi
			echo "Sleeping for 15 seconds..."
			sleep 15
			curl_return_code=`curl --write-out %{http_code} -v --connect-timeout 90 --max-time 120 -A "$varagent" --referer $HOST"/search.php?button="$query"&submit=Dig+for&search_type=magic&pos="$PREV_POS $HOST"/search.php?button="$query"&submit=Dig+for&search_type=magic&pos="$POS --output "libgensearch-"$i.html`
			if [ ! -e "libgensearch-"$i.html ]; then
				HTML_BYTES=0
			else
				HTML_BYTES=`wc -c < "libgensearch-"$i.html`
			fi

			let CURL_COUNTER++
			if [ "$CURL_COUNTER" -eq "25" ]; then
				echo "I've tried to curl the page 25 times... I'm tired. Exiting."
				return
			fi
		done
		CURL_COUNTER=0
		cat "libgensearch-"$i.html | grep "javascript:window.open" | cut -d "(" -f 2 | cut -d "=" -f 2 | cut -d "\"" -f 1 >> $bookID_file
		rm -rf "libgensearch-"$i".html"
		let i++
		sleep 30
	done

sleep 60      
}

if [ -z "$2" ]; then
	if [ "$OPTION2" -eq "1" ]; then
		if [ -z "$http_proxy" ]; then
			echo "Setting http_proxy..."
			change_proxy
		fi
	fi
	echo "Getting BookIDs..."
	sleep 2
	getBookIDs
	echo "Done."
fi

while read bookID; do
	let count++
	echo "$count : BookID $bookID"
	echo -e "Number: $count\nBookID: $bookID\nFilename: $bookID_file" > lastfile.txt
	echo "---------------------------------------------------------------------------"
	m=`expr $count % 10`

	if [ "$m" -eq 0 ]; then
		if [ "$OPTION2" -eq "1" ]; then
			change_proxy
		fi
	fi

	curl_return_code=`curl --write-out %{http_code} -v --connect-timeout 90 --max-time 120 -A "$varagent" -o $bookID.html --referer "$HOST" $HOST"/view.php?id="$bookID`
	if [ ! -e "$bookID.html" ]; then
		HTML_BYTES=0
	else
		HTML_BYTES=`wc -c < $bookID.html`
	fi


	while [ "$curl_return_code" -ne "200" ] || [ "$HTML_BYTES" -le "14000" ] ; do
		rm -rf $bookID.html
		echo "Return code is: $curl_return_code"
		echo "HTML file: $HTML_BYTES bytes"
		if [ "$OPTION2" -eq "1" ]; then
			change_proxy
		fi
		echo "Sleeping for 15 seconds..."
		sleep 15
		curl_return_code=`curl --write-out %{http_code} -v --connect-timeout 90 --max-time 120 -A "$varagent" -o $bookID.html --referer "$HOST" $HOST"/view.php?id="$bookID`

		if [ ! -e "$bookID.html" ]; then
			HTML_BYTES=0
		else
			HTML_BYTES=`wc -c < $bookID.html`
		fi
	
		let CURL_COUNTER++
		if [ "$CURL_COUNTER" -eq "25" ]; then
			echo "I've tried to curl the page 25 times... I'm tired. Exiting."
			return
		fi
	done
	CURL_COUNTER=0

	TITLE=`cat $bookID.html | grep "<strong>" | cut -d ">" -f 3 | cut -d "<" -f 1 | tr -d '\r'`
	if [ -n "$TITLE" ]; then
		AUTHOR=`cat $bookID.html | grep "<strong>" | cut -d ">" -f 4 | cut -d "<" -f 1 | tr -d '\r'`
		echo "$TITLE $AUTHOR"
		FILE_TYPE=`cat $bookID.html | grep "hidden0" | perl -pe "s/.*\.//" | cut -d "\"" -f 1 | tr -d '\r' | head -1`
		echo "Filetype: $FILE_TYPE"
		FILE_NAME_TMP=$TITLE"_"$AUTHOR"."$FILE_TYPE
		FILE_LENGTH=${#FILE_NAME_TMP}
        	echo "Filename character length is: $FILE_LENGTH"
        	if [ "$FILE_LENGTH" -gt 100 ]; then
        		echo "Filename too long, parsing..."
        	        FILE_NAME_TMP2=`echo $FILE_NAME_TMP | cut -c 1-96`
        	        FILE_NAME=$FILE_NAME_TMP2.$FILE_TYPE
        	else
        	        FILE_NAME=$FILE_NAME_TMP
        	fi
	
		FILE_NAME_TMP3=$FILE_NAME
		FILE_EXISTS=`ls -1 | grep "$FILE_NAME"`
		k=1
		while [ -n "$FILE_EXISTS" ]; do
			echo "File exists! ($FILE_NAME)"
			FILE_NAME=$FILE_NAME_TMP3.$k
			let k++
			FILE_EXISTS=`ls -1 | grep "$FILE_NAME"`
		done
	
        	echo "File name: $FILE_NAME"
	
		LINK=`cat $bookID.html | grep "name=\"hidden\"" | cut -d "=" -f 4 | cut -d ">" -f 1`
		DL_URL=$DL_URL_PREFIX"hidden="$LINK
		RFILE_BYTES=`cat $bookID.html | grep "bytes" | cut -d ">" -f 2 | cut -d "<" -f 1 | sed 's/Size: //g' | sed 's/ bytes//g'`
		echo "File should be: $RFILE_BYTES bytes"

		echo "Download link: $DL_URL"
		echo "Sleeping for 90 seconds before retrieving file"
		sleep 90

		if [ -z "$LINK" ] || [ -z "$FILE_TYPE" ] || [ -z "$AUTHOR" ] || [ -z "$TITLE" ]; then
			echo "Incomplete information... saving $bookID to a file for later processing"
			echo $bookID >> bookIDs.notfound
		else
			echo "Downloading: $FILE_NAME"
			sleep 5
			wget -c -O "$FILE_NAME" -e use-proxy=yes -e http_proxy=$http_proxy --user-agent="$varagent" --referer $HOST"/view.php?id="$bookID "$DL_URL"
			wget_return_value=$?
			FILE_BYTES=`wc -c < "$FILE_NAME"`
			echo "File size: $FILE_BYTES bytes"
			while [ "$wget_return_value" -ne 0 ] || [ "$FILE_BYTES" != "$RFILE_BYTES" ]; do
				echo "wget return value: $wget_return_value"
                                case $wget_return_value in
				0)
				  echo "Wget exited normally and downloaded a file"
				  echo "Filesizes must not be the same! Retrying..."
				  rm -rf "$FILE_NAME"
				  if [ "$OPTION2" -eq "1" ]; then
				  	change_proxy
				  fi
				  echo "Sleeping for 15 seconds..."
				  sleep 15
			 	  wget -c -O "$FILE_NAME" -e use-proxy=yes -e http_proxy=$http_proxy --user-agent="$varagent" --referer $HOST"/view.php?id="$bookID "$DL_URL" 
				  wget_return_value=$?
				  FILE_BYTES=`wc -c < "$FILE_NAME"`
  				  let WGET_COUNTER++
				  ;;
				[1-8])
				  echo "Wget error. Retrying..."
				  rm -rf "$FLIE_NAME"
				  if [ "$OPTION2" -eq "1" ]; then
				  	change_proxy
				  fi
				  echo "Sleeping for 15 seconds..."
				  sleep 15
			 	  wget -c -O "$FILE_NAME" -e use-proxy=yes -e http_proxy=$http_proxy --user-agent="$varagent" --referer $HOST"/view.php?id="$bookID "$DL_URL" 
				  wget_return_value=$?
				  FILE_BYTES=`wc -c < "$FILE_NAME"`
  				  let WGET_COUNTER++
				  ;;
				143)
				  echo "Wget: Terminated. Retrying the download..."
				  if [ "$TERMINATED_COUNTER" -ge 10 ]; then
					if [ "$OPTION2" -eq "1" ]; then
					  	change_proxy
					fi
				  fi

 		   	  	  wget -c -O "$FILE_NAME" -e use-proxy=yes -e http_proxy=$http_proxy --user-agent="$varagent" --referer $HOST"/view.php?id="$bookID "$DL_URL"
				  wget_return_value=$?
				  FILE_BYTES=`wc -c < "$FILE_NAME"`
				  let WGET_COUNTER++
				  let TERMINATED_COUNTER++
				  ;;
				*)
				  if [ "$OPTION2" -eq "1" ]; then
					  change_proxy
				  fi
				  echo "Retrying."
				  echo "Sleeping for 15 seconds..."
				  sleep 15
				  rm -rf "$FILE_NAME"
			 	  wget -c -O "$FILE_NAME" -e use-proxy=yes -e http_proxy=$http_proxy --user-agent="$varagent" --referer $HOST"/view.php?id="$bookID "$DL_URL"
				  wget_return_value=$?
				  FILE_BYTES=`wc -c < "$FILE_NAME"`
  				  let WGET_COUNTER++
				  ;;
				esac
				if [ "$WGET_COUNTER" -gt 25 ]; then
					echo "I've retried to download the file 25 times... I am tired. I will save $bookID to bookIDs.notfound for later processing."
					echo $bookID >> bookIDs.notfound
					break
				fi
			done
		fi
		WGET_COUNTER=0
		TERMINATED_COUNTER=0
		FILE_BYTES=`wc -c < "$FILE_NAME"`
		echo " "
		echo "Everything went as planned!"
		echo "File Size: $FILE_BYTES bytes"
	else
		echo "$bookID not found... saving to a file"
		echo $bookID >> bookIDs.notfound
	fi
	echo "Sleeping for 3 minutes"
	rm -rf $bookID.html
	echo "---------------------------------------------------------------------------"
	sleep 180
done < $bookID_file
