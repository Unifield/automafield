#!/bin/sh

# http://stackoverflow.com/questions/3919755/how-to-parse-query-string-from-a-bash-cgi-script
getvar() {
	s='s/^.*'${1}'=\([^&]*\).*$/\1/p'
	echo $QUERY_STRING | sed -n $s | sed "s/%20/ /g"
}

no() {
	echo "content-type: text/plain"
	echo
	echo "no: $1"
	exit 1
}

# Make sure that:
# 1. they have the key (set it in the apache config file)
[ "$PATH_INFO" != "/$KEY" ] && no key
# 2. they tell us who they are
who=`getvar who`
[ -z "$who" ] && no who
# 3. that $who has no dangerous characters in it
echo "$who" | grep -q '[^a-zA-Z0-9_-]' && no badchars
# 4. that they are posting to us
[ "$REQUEST_METHOD" != "POST" ] && no post

mkdir -p "logs/$who"
when=`date +%Y%m%d-%H%M`
cat > "logs/$who/$when.txt"

echo "content-type: text/plain"
echo
echo "ok"
