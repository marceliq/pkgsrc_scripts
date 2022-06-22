#!/usr/bin/env bash

_cwd=`pwd`

. base.sh

if [ ! -d "${PKGSRC_BASE}/pkgsrc/rb" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 https://github.com/marceliq/rb.git rb) || exit 1
fi

cd $_cwd

exit
# build a instalace
# python

#. python27-base.sh

# salt
_nol=`$PREFIX/sbin/pkg_info |grep salt |wc -l`
if [ $_nol -eq 0 ]; then
  (cd ${PKGSRC_BASE}/pkgsrc/rb/salt-3004nb2 && bmake install clean clean-depends) || exit 1
fi

if [ -d "${PREFIX}/conf/salt" ]; then
  (mv ${PREFIX}/conf/salt ${PREFIX}/conf/salt_dist && mkdir ${PREFIX}/conf/salt) || exit 1
fi

