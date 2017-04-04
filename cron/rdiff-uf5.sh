#!/bin/sh

rdiff-backup /root backup::root
rdiff-backup /etc backup::etc
rdiff-backup /opt backup::opt
rdiff-backup /usr/local backup::local
