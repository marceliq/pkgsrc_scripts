#!/usr/bin/env bash

. base.sh

# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

props="PKG_OPTIONS.rust=\trust-internal-llvm"

for prop in $props
  do
    _nol=`perl -nle "print if m/$prop/" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      $SED "s/(\.endif.*)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done

# build a instalace
# elftoolchain
#_nol=`$PREFIX/sbin/pkg_info |$GREP elftoolchain |wc -l`
#if [ $_nol -eq 0 ]; then
#  (cd ${PKGSRC_BASE}/pkgsrc/devel/elftoolchain && bmake install clean clean-depends) || exit 1
#fi

# rust
#_nol=`$PREFIX/sbin/pkg_info |$GREP rust |wc -l`
#if [ $_nol -eq 0 ]; then
#  (cd ${PKGSRC_BASE}/pkgsrc/lang/rust && bmake install clean clean-depends) || exit 1
#fi

