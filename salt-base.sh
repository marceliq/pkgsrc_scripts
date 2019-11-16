#!/usr/bin/env bash

. base.sh

# doplneni promennych do mk.conf
#MKCONF_PATH=$PREFIX/conf/mk.conf

#props="PKG_OPTIONS.python27=\t-x11 CFLAGS-=\t\t-Os CXXFLAGS-=\t\t-Os CPPFLAGS-=\t\t-Os MAKE_JOBS=\t\t$PJOBS SKIP_LICENSE_CHECK=\tyes"

#for prop in $props
#  do
#    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
#    if [ $_nol -eq 0 ]; then
#      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
#    fi
#  done

# build a instalace
# salt
_nol=`$PREFIX/sbin/pkg_info |grep salt |wc -l`
if [ $_nol -eq 0 ]; then
#  (cd ${PKGSRC_BASE}/pkgsrc && curl -L https://api.github.com/repos/marceliq/pkgsrc_overlay/tarball | tar xz --strip=1) || exit 1
#  (cd ${PKGSRC_BASE}/pkgsrc/sysutils/salt && bmake fetch depends clean-depends clean) || exit 1
  (cd ${PKGSRC_BASE}/pkgsrc/sysutils/salt && bmake install clean clean-depends) || exit 1
fi

if [ -d "${PREFIX}/conf/salt" ]; then
  (mv ${PREFIX}/conf/salt ${PREFIX}/conf/salt_dist && mkdir ${PREFIX}/conf/salt) || exit 1
fi

if [ ! -f "${PREFIX}/conf/openssl/certs/ca-certificates.crt" ]; then
  ${PREFIX}/sbin/mozilla-rootcerts install || exit 1
fi
