#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/salt

for f in `find ${PREFIX} -type f | grep -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

