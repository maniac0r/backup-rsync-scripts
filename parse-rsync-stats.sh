#!/opt/bin/bash

LOGFF=$1
LOGF2=$(echo $LOGFF | tr _ - | tr : - | sed s/.*\\/// | sed s/\\..*//)
LOGF=$LOGF2

  if [ -z "$LOGF" ] ; then
    echo "Please specify log file to analyze"
    exit 1
  else
    if [ "$LOGF" == "-a" ] ; then
      for FILE in `ls .log/*.csv` ; do
        ./parse-rsync-stats.sh "$FILE"
      done
      exit 0
    fi
  fi

LOGTIMESTAMP=$(date -d "$(echo $LOGF | sed s/.*\.log-// | sed s/-/\ /3 | sed s/-/\:/3)" +%s%N )

echo "Processing log:$LOGFF"
echo "Datetime: $LOGF"
echo "Timestamp: $LOGTIMESTAMP"

# Server,Duration,Transf size,Backup size,Duration delta,Transf size delta,Backup size delta
declare -A ARR_SERVER
declare -A ARR_DURATION
declare -A ARR_TRANSF_SIZE
declare -A ARR_BACKUP_SIZE
declare -A ARR_DURATION_DELTA
declare -A ARR_TRANSF_SIZE_DELTA
declare -A ARR_BACKUP_SIZE_DELTA

for LINE in `egrep -v 'Server,Duration,' $LOGFF` ; do
  SERVER=$(echo $LINE | awk -F ',' '{print $1}')
  DURATION=$(echo $LINE | awk -F ',' '{print $2}')
  TRANSF_SIZE=$(echo $LINE | awk -F ',' '{print $3}')
  BACKUP_SIZE=$(echo $LINE | awk -F ',' '{print $4}')
  DURATION_DELTA=$(echo $LINE | awk -F ',' '{print $5}')
  TRANSF_SIZE_DELTA=$(echo $LINE | awk -F ',' '{print $6}')
  BACKUP_SIZE_DELTA=$(echo $LINE | awk -F ',' '{print $7}')

  ARR_SERVER[$SERVER]=$SERVER
  ARR_DURATION[$SERVER]=$DURATION
  ARR_TRANSF_SIZE[$SERVER]=$TRANSF_SIZE
  ARR_BACKUP_SIZE[$SERVER]=$BACKUP_SIZE
  ARR_DURATION_DELTA[$SERVER]=$DURATION_DELTA
  ARR_TRANSF_SIZE_DELTA[$SERVER]=$TRANSF_SIZE_DELTA
  ARR_BACKUP_SIZE_DELTA[$SERVER]=$BACKUP_SIZE_DELTA
done


cat /dev/null > parse-stats.txt

for SERVER in "${!ARR_SERVER[@]}" ; do
  [[ -z "${ARR_DURATION[$SERVER]}" ]] && ARR_DURATION[$SERVER]=0
  [[ -z "${ARR_TRANSF_SIZE[$SERVER]}" ]] && ARR_TRANSF_SIZE[$SERVER]=0
  [[ -z "${ARR_BACKUP_SIZE[$SERVER]}" ]] && ARR_BACKUP_SIZE[$SERVER]=0
  [[ -z "${ARR_DURATION_DELTA[$SERVER]}" ]] && ARR_DURATION_DELTA[$SERVER]=0
  [[ -z "${ARR_TRANSF_SIZE_DELTA[$SERVER]}" ]] && ARR_TRANSF_SIZE_DELTA[$SERVER]=0
  [[ -z "${ARR_BACKUP_SIZE_DELTA[$SERVER]}" ]] && ARR_BACKUP_SIZE_DELTA[$SERVER]=0

  echo "rsyncbackup.duration,host=${ARR_SERVER[$SERVER]} value=${ARR_DURATION[$SERVER]} $LOGTIMESTAMP" >> parse-stats.txt
  echo "rsyncbackup.size.transf.size,host=${ARR_SERVER[$SERVER]} value=${ARR_TRANSF_SIZE[$SERVER]} $LOGTIMESTAMP" >> parse-stats.txt
  echo "rsyncbackup.size.backupsize,host=${ARR_SERVER[$SERVER]} value=${ARR_BACKUP_SIZE[$SERVER]} $LOGTIMESTAMP" >> parse-stats.txt
  echo "rsyncbackup.size.duration.delta,host=${ARR_SERVER[$SERVER]} value=${ARR_DURATION_DELTA[$SERVER]} $LOGTIMESTAMP" >> parse-stats.txt
  echo "rsyncbackup.size.total.transf.size.delta,host=${ARR_SERVER[$SERVER]} value=${ARR_TRANSF_SIZE_DELTA[$SERVER]} $LOGTIMESTAMP" >> parse-stats.txt
  echo "rsyncbackup.backup.size.delta,host=${ARR_SERVER[$SERVER]} value=${ARR_BACKUP_SIZE_DELTA[$SERVER]} $LOGTIMESTAMP" >> parse-stats.txt

done

echo "Submitting: $LOGTIMESTAMP to InfluxDB"

/sbin/curl -i -X POST 'http://in.fl.ux.ip:8086/write?db=backups' --data-binary '@parse-stats.txt'
