#!/usr/bin/env bash
#set -x

umask 022

_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/common/kafkacat
CVS_BRANCH="HEAD"

PKGSRC_MODULES="wip/kafkacat"

CLEAN_MODULES="automake autoconf bmake bootstrap-mk-files bsdtar bzip2 ccache cmake curl cwrappers db4 digest expat help2man libarchive libffi libidn2 libtool-base libunistring libuuid libuv libxml2 makedepend nbpatch ncurses nghttp2 p5-gettext pax perl pkg_install pkgconf python38 readline rhash xmlcatmgr xorgproto"

export PKGSRC_BASE
export PREFIX
 
. base.sh

# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

props="PKGSRC_USE_FORTIFY=\tno"

for prop in $props
  do
    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done


if [ ! -d "${PKGSRC_BASE}/pkgsrc/wip" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 git://wip.pkgsrc.org/pkgsrc-wip.git wip) || exit 1
fi

#
# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

VERSION=`$PREFIX/sbin/pkg_info | ${GREP} kafkacat | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`

# cisteni prefixu
_modules=""
for module in $CLEAN_MODULES
  do
    _module=`echo $module | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module-[0-9]" |wc -l`
#    echo $_module : $_nol
    if [ $_nol -ne 0 ]; then
      _modules="$_modules $_module"
    fi
  done

if [ "$_modules" != "" ]; then
  echo "Deleting modules: $_modules"
  $PREFIX/sbin/pkg_delete -ff $_modules || exit 1
fi

rm -rf \
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

(cd $PREFIX/.. && mv $PREFIX $PREFIX-$VERSION) || exit 1

# vytvoreni balicku
(cd $PREFIX-${VERSION}/.. && tar czf kafkacat-${VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz kafkacat-${VERSION}) || exit 1

