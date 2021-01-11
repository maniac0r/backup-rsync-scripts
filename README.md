# backup-rsync-scripts

To run backup cd to this directory and run ./sync_all.sh .
Script will try to fetch per server */*.sync files, where backup for particular server is defined. See example in folder "group1" - you might create group folder(s) with any name your like.

Script is using scp to deliver html report to destination and also submitting metrics into the IfluxdB.
