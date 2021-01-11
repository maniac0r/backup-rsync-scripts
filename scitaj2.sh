#! /bin/bash
# PREVIOUS
INPUTFILE=$(ls .log/*.txt | tail -n2 | head -n1)
PREVIOUSDATE=$(echo $INPUTFILE | sed 's/^.*\///' | sed s/\.txt$//)

# LATEST
DATAFILE=$(ls .log/*.txt | tail -n1)
LATESTDATE=$(echo $DATAFILE | sed 's/^.*\///' | sed s/\.txt$//)

OUTFILE=$(echo $DATAFILE | sed s/\.txt$/\.csv/)

awk 'BEGIN {

print "<TABLE border=1 class='sortable'>"
print "<caption><a href='https://x.y.z/backup-status.html'>" "'"$LATESTDATE"'" " vs " "'"$PREVIOUSDATE"'" "</a></caption>"

print "<TR><TD ALIGN=RIGHT><b>Server</TD><TD ALIGN=RIGHT><b>Duration</TD><TD ALIGN=RIGHT><b>Transf size</TD><TD ALIGN=RIGHT><b>Backup size</TD><TD ALIGN=RIGHT><b>Durat. &Delta;</TD><TD ALIGN=RIGHT><b>Transf size &Delta;</TD><TD ALIGN=RIGHT><b>Bkp Size &Delta;</b></TD></TR>"
print "Server,Duration,Transf size,Backup size,Duration delta,Transf size delta,Backup size delta" > "'"$OUTFILE"'"; # Print directly to the outputfile

while (getline < "'"$INPUTFILE"'")
{
  split($0,ft0,",");
  server0=ft0[1];
  duration0=ft0[2];
  transsize0=ft0[3];
  serversize0=ft0[4];

  key0=server0;
  data0=duration0","transsize0","serversize0;
  nameArr[key0]=data0;
  duration0Arr[key0]=duration0
  transsize0Arr[key0]=transsize0
  serversize0Arr[key0]=serversize0
}
close("'"$INPUTFILE"'");

while (getline < "'"$DATAFILE"'")
{
  split($0,ft1,",");
  server1=ft1[1];
  duration1=ft1[2];
  transsize1=ft1[3];
  serversize1=ft1[4];

  durrationdiff=duration1-duration0Arr[server1]
  transsizediff=transsize1-transsize0Arr[server1]
  serversizediff=serversize1-serversize0Arr[server1]

  transsizediffh=human(transsizediff)
  serversizediffh=human(serversizediff)

  transsizediffmb=transsizediff/1024/1024
  serversizediffmb=serversizediff/1024/1024
  transsizediffmb=int(transsizediffmb)
  serversizediffmb=int(serversizediffmb)

  transsizemb=transsize1/1024/1024
  serversizemb=serversize1/1024/1024
  transsizemb=int(transsizemb)
  serversizemb=int(serversizemb)

  print "<TR><TD ALIGN=RIGHT style=white-space: nowrap>"server1"</TD><TD ALIGN=RIGHT style=white-space: nowrap>"duration1" s</TD><TD ALIGN=RIGHT style=white-space: nowrap>"transsizemb" MB</TD><TD ALIGN=RIGHT style=white-space: nowrap>"serversizemb" MB</TD><TD ALIGN=RIGHT style=white-space: nowrap>"durrationdiff" s</TD><TD ALIGN=RIGHT style=white-space: nowrap>"transsizediffmb" MB</TD><TD ALIGN=RIGHT style=white-space: nowrap>"serversizediffmb" MB</TD></TR>"
  print server1","duration1","transsize1","serversize1","durrationdiff","transsizediff","serversizediff > "'"$OUTFILE"'"; # Print directly to the outputfile

}

print "</TABLE>"

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
'
