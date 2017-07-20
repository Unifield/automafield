#!/bin/sh

for i in root etc opt local
do
	rdiff-backup --remove-older-than 30D --force -v2 backup::$i
done

rdiff-backup /root backup::root
rdiff-backup /etc backup::etc
rdiff-backup /opt backup::opt
rdiff-backup /usr/local backup::local
