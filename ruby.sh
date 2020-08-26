#!/usr/bin/env bash

. base.sh

# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

# ruby
_nol=`$PREFIX/sbin/pkg_info |$GREP ruby |wc -l`
if [ $_nol -eq 0 ]; then
  (cd ${PKGSRC_BASE}/pkgsrc/lang/ruby && bmake install clean clean-depends) || exit 1
fi

#if [ ! -f "${PREFIX}/conf/openssl/certs/ca-certificates.crt" ]; then
#  ${PREFIX}/sbin/mozilla-rootcerts install || exit 1
#fi

