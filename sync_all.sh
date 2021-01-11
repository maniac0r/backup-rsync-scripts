#!/bin/bash

OPWD=$PWD
LOG_FILE=".log/"$(/bin/date +%Y-%m-%d_%H:%M:%S)

export RSYNC="rsync -av --delete --delete-excluded"

bytesToHuman() {
    b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}

# Close STDOUT file descriptor
exec 1<&-
# Close STDERR FD
exec 2<&-

# Open STDOUT as $LOG_FILE file for read and write.
exec 1<>$LOG_FILE

# Redirect STDERR to STDOUT
exec 2>&1

for server in `ls */*.sync` ; do
  DEJT=$(date)
  echo "$DEJT Starting rsync of "`basename $server| sed s/\.sync//`" ."
  cd `dirname $server` && 2>&1 time ./`basename $server` | tr \\n \\t | sed 's/^$//'
  SENTBYTES=$(tail -n2 `basename $server.log` | sed 's/.*received\ //' | sed 's/\ bytes.*//' | tr -d , | head -n1 )
  TOTALSIZE=$(tail -n2 `basename $server.log` | sed 's/.*total\ size\ is\ //' | sed 's/\ .*//' | tr -d , | tail -n1 )
  echo "SENTBYTES:$SENTBYTES TOTALSIZE:$TOTALSIZE"
  cd $OPWD
  echo "...Server "`basename $server`" DONE..."
  echo "--------------------------------------"
        REALTIME=$( tail -n 4 $LOG_FILE | egrep 'real' | sed s/.*real\ *// | sed 's/\s//' | sed s/user.*// | sed 's/\s*$//' | sed s/\\..*$/s/ | tr -d , )
        SERVERNAME=$( echo `basename $server` | sed 's/\.sync$//' )

# convert bytes to MBytes
if [ -n "$SENTBYTES" ] ; then
        echo "$SERVERNAME SENTBYTES:$SENTBYTES" >> $LOG_FILE.debug
        SENTBYTESHR=$(($SENTBYTES >> 20))
else
        SENTBYTESHR=0
fi

if [ -n "$TOTALSIZE" ] ; then
        echo "$SERVERNAME TOTALSIZE:$TOTALSIZE" >> $LOG_FILE.debug
        echo "" >> $LOG_FILE.debug
        TOTALSIZEHR=$(($TOTALSIZE >> 20))
else
        TOTALSIZEHR=0
fi
        echo "<TD align=right>$SERVERNAME</TD>" >> $LOG_FILE.new
        echo "<TD align=right>$REALTIME</TD>" >> $LOG_FILE.new
        echo "<TD align=right>$SENTBYTESHR MB</TD>" >> $LOG_FILE.new
        echo "<TD align=right>$TOTALSIZEHR MB</TD>" >> $LOG_FILE.new
        echo "<TR>" >> $LOG_FILE.new

        REALTIME_S=$(echo $REALTIME | sed s/[a-z]//g | awk '{print $1 * 60 + $2}' | tr -d , )
        echo "$SERVERNAME,$REALTIME_S,$SENTBYTES,$TOTALSIZE" >> $LOG_FILE.txt

done

mv $LOG_FILE $LOG_FILE.tmp

cat $LOG_FILE.tmp | \
        sed s/real/\\n\|real/ | \
        egrep -v '^$' | \
        sed s/.*rsync\ of\ /\|\<tr\>\<td\>/ | \
        sed s/\ \.$/\<\\/td\>/ | \
        sed s/^\|real/\<Td\>/ | \
        sed s/.user.*/\<\\/tD\>/ | \
        sed s/--*// | \
        sed s/^ssh:/\<td\>ssh:/ |  \
        tr -d \\n | \
        tr \| \\n | \
        sed s/255^/255\<\\/td\>/ \
        > $LOG_FILE

cat /dev/null > $LOG_FILE.new
cat sorttable.js.html > $LOG_FILE.new
./scitaj2.sh >> $LOG_FILE.new

# feed influxdb@grafana
./parse-rsync-stats.sh $LOG_FILE.csv

echo "<pre>" >> $LOG_FILE.new
cat $LOG_FILE.txt | awk -f backup-sum.awk >> $LOG_FILE.new
echo "</pre>" >> $LOG_FILE.new

cat .log/mailheader-html $LOG_FILE.new .log/mailfooter-html | sendmail -t
cat .log/mailheader-html-web $LOG_FILE.new .log/mailfooter-html > $LOG_FILE.mail

#scp -q $LOG_FILE.mail root@x.y.z:/var/www/backup-status.html
