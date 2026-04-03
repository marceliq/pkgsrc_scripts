#!/usr/bin/env bash
#set -x

umask 022

_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/elastic/dists/redis

CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

PKGSRC_MODULES="databases/redis"

CLEAN_MODULES="bmake bootstrap-mk-files checkperms cwrappers digest libnbcompat libtool-base mktools nbpatch perl pkgconf pkg_install"

export PKGSRC_BASE
export PREFIX
 
. base.sh

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

VERSION=`$PREFIX/sbin/pkg_info | ${GREP} redis | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`

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
#  $PREFIX/sbin/pkg_delete $_modules || exit 1
fi

rm -rf \
$PREFIX/include \
$PREFIX/conf \
$PREFIX/bin/bmake \
$PREFIX/info \
$PREFIX/man \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share \
$PREFIX/sbin || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

(cd $PREFIX/.. && mv $PREFIX $PREFIX-$VERSION) || exit 1

# vytvoreni balicku
(cd $PREFIX-${VERSION}/.. && tar czf redis-${VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz redis-${VERSION}) || exit 1

