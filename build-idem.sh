#!/usr/bin/env bash
#set -x

umask 022
_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/common/idem
CVS_BRANCH="HEAD"
#CVS_BRANCH="pkgsrc-2021Q1"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

PKGSRC_MODULES="devel/py-poetry"
#PIP_MODULES="voluptuous>=0.9.3 elasticsearch urllib3>=1.24.2,<1.25 requests>=2.20.0 boto3>=1.9.142 requests_aws4auth>=0.9 click>=6.7,<7.0 pyyaml==3.13 certifi>=2019.9.11 six>=1.11.0 elasticsearch-curator"
#PIP_MODULES="elasticsearch-curator"

CLEAN_MODULES="bsdtar cwrappers digest libtool-base makedepend nbpatch pax perl pkgconf unzip xorgproto py39-pip readline ncurses expat py39-expat py39-setuptools ccache bootstrap-mk-files bmake pkg_install"

export PKGSRC_BASE
export PREFIX
 
#. python39-base.sh

. base.sh

#if [ ! -d "${PKGSRC_BASE}/pkgsrc/rb" ]; then
#  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 https://github.com/marceliq/rb.git rb) || exit 1
#fi

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

exit

# instalace modulu pres pip
#for module in ${PIP_MODULES}
#  do
#    $PREFIX/bin/pip3.9 install $module || exit 1
#  done

# odchytnout verzi curatoru
CURATOR_VERSION=`$PREFIX/bin/pip3.9 list elasticsearch-curator |${GREP} -P '^elasticsearch-curator\ +[0-9]' |${AWK} -F ' ' '{print $2}'` || exit 1
echo $CURATOR_VERSION

# odchytnout verzi curatoru
ES_VERSION=`$PREFIX/bin/pip3.9 list elasticsearch |${GREP} -P '^elasticsearch\ +[0-9]' |${AWK} -F ' ' '{print $2}'` || exit 1
echo $ES_VERSION

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

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

# vytvoreni balicku
(cd $PREFIX/.. && tar czf curator-${CURATOR_VERSION}-es-${ES_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz curator) || exit 1

