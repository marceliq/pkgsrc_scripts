#!/usr/bin/env bash

. base.sh

# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

props="CFLAGS-=\t\t-Os CXXFLAGS-=\t\t-Os CPPFLAGS-=\t\t-Os MAKE_JOBS=\t\t$PJOBS SKIP_LICENSE_CHECK=\tyes"

for prop in $props
  do
    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done

# build a instalace
# salt
_nol=`$PREFIX/sbin/pkg_info |grep python27 |wc -l`
if [ $_nol -eq 0 ]; then
  (cd ${PKGSRC_BASE}/pkgsrc/lang/python27 && bmake install clean clean-depends) || exit 1
fi

#if [ ! -f "${PREFIX}/conf/openssl/certs/ca-certificates.crt" ]; then
#  ${PREFIX}/sbin/mozilla-rootcerts install || exit 1
#fi
