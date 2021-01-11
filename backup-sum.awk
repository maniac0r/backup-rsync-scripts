#!/usr/bin/awk
# $SERVERNAME,$REALTIME,$SENTBYTESHR,$TOTALSIZEHR

BEGIN {
  totaltime=0
  totaltransf=0
  totalsize=0
  FS=","
  i=0
  time_m=0
  time_s=0
}

{
  server[i]=$1
  realtime[i]=$2
  transfsize[i]=$3
  serversize[i]=$4
  totaltime=totaltime+realtime[i]
  totaltransf=totaltransf+transfsize[i]
  totalsize=totalsize+serversize[i]
  i++
}

END {
  tth=human(totaltransf)
  tsobh=human(totalsize)
  tbt=hms(totaltime)
  print "Total transferred:",tth
  print "Total size of backups:",tsobh
  print "Total backup time:",tbt
}

function human(x) {
         s=" B   KiB MiB GiB TiB EiB PiB YiB ZiB"
         while (x>=1024 && length(s)>1)
               {x/=1024; s=substr(s,5)}
         s=substr(s,1,4)
         xf=(s==" B  ")?"%5d   ":"%8.2f"
         out1=sprintf( xf"%s", x, s)
         gsub(/^[ \t+]+/, "", out1)             # remove leading space
         return sprintf( "%s", out1)
      }

function hms(s) {
  h=int(s/3600);
  s=s-(h*3600);
  m=int(s/60);
  s=s-(m*60);
  return sprintf("%d:%02d:%02d", h, m, s);
}
