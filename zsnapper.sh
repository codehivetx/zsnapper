#!/bin/bash

# zsnapper
# Copyright (C) 2024 Code Hive Tx, LLC. All Rights Reserved
# srl295@codehivetx.us
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache-2.0 license, see LICENSE
# https://github.com/codehivetx/zsnapper
#

# usage:
#  1. set TARGET= to something reasonabe
#  2. backup with:  snapper  pool/and/dataset/subdir
#  first time through it creates a nonincremental backup.
# next time through it does an incremental one.

# H/T https://xai.sh/2018/08/27/zfs-incremental-backups.html for idea

# target disk
TARGET=/mnt/backup

if [ ! -d ${TARGET} ];
then
    echo >&2 "$0: error: no target disk ${TARGET}"
    exit 1
fi

# prefix for generated snapshots
SNAPPRE=backup-

# get today's date
TODAY=$(date +%Y-%m-%d)

# verify that we were given a pool
if [ -z $1 ]; then echo >&2 "Usage: $0 [target pool]"; exit 1; fi

targetpool="$1"

shift

if [ ! -d /mnt/${targetpool} ]; then
   echo >&2"$0: error: no pool ${targetpool}"
   exit 1
fi

# the new snapshot
NEWSNAP=${targetpool}@${SNAPPRE}${TODAY}
# target directory
TARGDIR=${TARGET}/${targetpool}
# we use the last element as the base name.  So a pool of /mnt/somepool/a/b/c will create /mnt/backup/somepool/a/b/c/c@backup-0000-11-22
BASEFILE=$(basename ${targetpool})
# this is where the backup will be written to
NEWSNAPFILE=${TARGDIR}/${BASEFILE}@${SNAPPRE}${TODAY}

# make sure the target exists
mkdir -p -v ${TARGDIR} || exit 1

# give the user some status
echo >&2 ${NEWSNAP} to ${TARGDIR}

# find the last known good snapshot, if any
last=$(find ${TARGDIR} -type f -print | sort | fgrep ${BASEFILE}@${SNAPPRE} | tail -n 1)

# did we find anything?
if [[  -z "${last}" ]] || [[ ! -f ${last} ]];
then
    # will have to start from scratch
    echo >&2 no last snap ${last}
    last=
else
    # we found something
    echo -n last snap >&2
    ls -ld ${last} >&2
    # extract actual target
    last=${targetpool}@$(echo ${last} | cut -d@ -f2)
    # if the 'last' snapshot doesn't exist, get out, because we'll fail
    zfs list ${last} >&2 || exit 1
fi

# make the snap - ok if exists
echo zfs snapshot ${NEWSNAP} >&2
zfs snapshot ${NEWSNAP} || true
# but fail if it still doesn't exist
zfs list ${NEWSNAP} >&2 || exit 1

if [[ -f ${NEWSNAPFILE} ]];
then
    echo >&2 "Already done: ${NEWSNAPFILE}"
    exit 0
fi

if [[ -z "${last}" ]];
then
    # non incremental
    echo zfs send -n -w ${NEWSNAP} '>' ${NEWSNAPFILE}
    # dry run first
    zfs send -n -w ${NEWSNAP} || exit 1
    exec zfs send -v -w ${NEWSNAP} > ${NEWSNAPFILE}
else
    # incremental backup
    zfs send -v -n -w -I ${last} ${NEWSNAP} || exit 1
    echo zfs send -w -I ${last} ${NEWSNAP} '>' ${NEWSNAPFILE}
    exec zfs send -v -w -I ${last} ${NEWSNAP} > ${NEWSNAPFILE}
fi

# that's it.
