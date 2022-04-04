#!/usr/bin/env bash

_cwd=`pwd`

. base.sh

# build a instalace
# python

#. python27-base.sh

# salt
_nol=`$PREFIX/sbin/pkg_info |grep salt |wc -l`
if [ $_nol -eq 0 ]; then
  (cd ${PKGSRC_BASE}/pkgsrc/sysutils/salt && bmake install clean clean-depends) || exit 1
fi

if [ -d "${PREFIX}/conf/salt" ]; then
  (mv ${PREFIX}/conf/salt ${PREFIX}/conf/salt_dist && mkdir ${PREFIX}/conf/salt) || exit 1
fi

