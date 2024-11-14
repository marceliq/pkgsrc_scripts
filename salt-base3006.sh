#!/usr/bin/env bash

_cwd=`pwd`

#. python310-base.sh
. python311-base.sh
#. python312-base.sh
cd ${_cwd}
#. rust-base.sh

if [ ! -d "${PKGSRC_BASE}/pkgsrc/rb" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 https://github.com/marceliq/rb.git rb) || exit 1
fi

if [ ! -d "${PKGSRC_BASE}/pkgsrc/wip" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 git://wip.pkgsrc.org/pkgsrc-wip.git wip) || exit 1
fi

cd $_cwd

# build a instalace
# python

#. python27-base.sh

# salt
_nol=`$PREFIX/sbin/pkg_info |grep salt |wc -l`
if [ $_nol -eq 0 ]; then
  (cd ${PKGSRC_BASE}/pkgsrc/rb/salt && bmake -B install clean clean-depends) || exit 1
fi

if [ -d "${PREFIX}/conf/salt" ]; then
  (mv ${PREFIX}/conf/salt ${PREFIX}/conf/salt_dist && mkdir ${PREFIX}/conf/salt)
fi

