#!/usr/bin/env bash
#set -x

umask 022
_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/elastic/dists/curator
CVS_BRANCH="HEAD"
#CVS_BRANCH="pkgsrc-2021Q1"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

export PKGSRC_BASE
export PREFIX
 
. python312-base.sh

PYVER=`$PREFIX/sbin/pkg_info | $GREP -P "^python" | $SED 's/python([0-9]{2,3}).*/\1/g'`
PYVER_SEP=`echo ${PYVER:0:1}.${PYVER:1}`

#. base.sh

#PKGSRC_MODULES="devel/py-pip lang/py-cxfreeze databases/py-elasticsearch textproc/py-yaml"
#PKGSRC_MODULES="devel/py-pip lang/py-cxfreeze"
PKGSRC_MODULES="devel/py-pip"
#PIP_MODULES="voluptuous>=0.9.3 elasticsearch urllib3>=1.24.2,<1.25 requests>=2.20.0 boto3>=1.9.142 requests_aws4auth>=0.9 click>=6.7,<7.0 pyyaml==3.13 certifi>=2019.9.11 six>=1.11.0 elasticsearch-curator"
PIP_MODULES="elasticsearch7 elasticsearch-curator==8.0.21"
#PIP_MODULES="elasticsearch-curator==8.0.21"

CLEAN_MODULES="bsdtar cwrappers digest libtool-base makedepend nbpatch pax perl pkgconf unzip xorgproto ${PYVER}-pip ${PYVER}-expat ${PYVER}-setuptools ccache bootstrap-mk-files bmake pkg_install"

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

# instalace modulu pres pip
for module in ${PIP_MODULES}
  do
    $PREFIX/bin/pip${PYVER_SEP} install $module || exit 1
  done

# odchytnout verzi curatoru
CURATOR_VERSION=`$PREFIX/bin/pip${PYVER_SEP} list elasticsearch-curator |${GREP} -P '^elasticsearch-curator\ +[0-9]' |${AWK} -F ' ' '{print $2}'` || exit 1
echo $CURATOR_VERSION

# odchytnout verzi curatoru
#ES_VERSION=`$PREFIX/bin/pip${PYVER_SEP} list elasticsearch |${GREP} -P '^elasticsearch\ +[0-9]' |${AWK} -F ' ' '{print $2}'` || exit 1
#echo $ES_VERSION

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
#  $PREFIX/sbin/pkg_delete $_modules || exit 1
  $PREFIX/sbin/pkg_delete -ff $_modules || exit 1
fi

rm -rf \
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* \
$PREFIX/lib/python${PYVER_SEP}/bsddb/test \
$PREFIX/lib/python${PYVER_SEP}/email/test \
$PREFIX/lib/python${PYVER_SEP}/json/tests \
$PREFIX/lib/python${PYVER_SEP}/unittest/test \
$PREFIX/lib/python${PYVER_SEP}/test \
$PREFIX/lib/python${PYVER_SEP}/ctypes/test \
$PREFIX/lib/python${PYVER_SEP}/lib2to3/tests \
$PREFIX/lib/python${PYVER_SEP}/sqlite3/test \
$PREFIX/lib/python${PYVER_SEP}/distutils/tests \
$PREFIX/lib/python${PYVER_SEP}/idlelib/idle_test \
$PREFIX/lib/python${PYVER_SEP}/lib-tk/test || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

# vytvoreni balicku
(cd $PREFIX/.. && tar czf curator-${CURATOR_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz curator) || exit 1

