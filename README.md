Adds list of remote links to PiHole
------
sudo ./AddList.pl file\
sudo ./AddList.pl file1 file2\
sudo ./AddList.pl *.txt\
sudo ./AddList.pl *.txt anotherfile

Idea behind this script
------
This script can only be run in Linux (tested under Arch Linux and Raspbian OS).

This script reads a list of remote hosts files to block using Pi-Hole using sqlite3 and adds them to gravity.db. The command will be ignored if the link already exists within the database. At the end, the script performs an update of the list with "pihole -g".

If the database is corrupted, you can use the following command to recreate the database (as instructed in https://docs.pi-hole.net/database/gravity/recovery/)
- pihole -g -r recreate

Then, re-run this script to add the additional lists back.
