#!/usr/bin/env bash
#set -x

umask 022
_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/common/lang/python3.9
CVS_BRANCH="HEAD"
#CVS_BRANCH="pkgsrc-2021Q1"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

PKGSRC_MODULES="devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel"
PIP_MODULES="px-proxy"

CLEAN_MODULES="bsdtar cwrappers digest libtool-base makedepend nbpatch pax perl pkgconf unzip xorgproto ccache bootstrap-mk-files bmake pkg_install"

export PKGSRC_BASE
export PREFIX
 
. python39-base.sh

PYVER=`$GREP -P "^PY_DISTVERSION" ${PKGSRC_BASE}/pkgsrc/lang/python39/dist.mk | ${AWK} -F ' ' '{print $2}'`
echo $PYVER

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

# instalace modulu pres pip
for module in ${PIP_MODULES}
  do
    $PREFIX/bin/pip3.9 install $module || exit 1
  done

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
#  $PREFIX/sbin/pkg_delete -ff $_modules || exit 1
fi

exit

rm -rf \
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* \
$PREFIX/lib/python3.9/bsddb/test \
$PREFIX/lib/python3.9/email/test \
$PREFIX/lib/python3.9/json/tests \
$PREFIX/lib/python3.9/unittest/test \
$PREFIX/lib/python3.9/test \
$PREFIX/lib/python3.9/ctypes/test \
$PREFIX/lib/python3.9/lib2to3/tests \
$PREFIX/lib/python3.9/sqlite3/test \
$PREFIX/lib/python3.9/distutils/tests \
$PREFIX/lib/python3.9/idlelib/idle_test \
$PREFIX/lib/python3.9/lib-tk/test || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

# vytvoreni balicku
(cd $PREFIX/.. && tar czf python-${PYVER}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz python3.9) || exit 1

