#!/usr/bin/env bash

. base.sh
exit
# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

props="PYTHON_DEFAULT_VERSION=\t312 PYTHON_VERSION_DEFAULT=\t312 PYPACKAGE=\t\tpython312 PKG_OPTIONS.python312=\t-x11"

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

# python
_nol=`$PREFIX/sbin/pkg_info |$GREP python312 |wc -l`
if [ $_nol -eq 0 ]; then
  (cd ${PKGSRC_BASE}/pkgsrc/lang/python312 && bmake install clean clean-depends) || exit 1
fi

