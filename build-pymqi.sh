#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/elastic/dists/pymqi
PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"
PJOBS=`nproc`

PKGSRC_MODULES="devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel"
#PIP_MODULES="pymqi"
PIP_MODULES=""

CLEAN_MODULES="automake autoconf bison bsdtar cmake cwrappers digest docbook-xsl docbook-xml fontconfig ghostscript-gpl ghostscript googletest groff ghostscript-fonts freetype2 gettext-lib gettext-tools gmake gperf gtexinfo help2man jasper netpbm jbigkit tiff jpeg libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxml2 libxslt makedepend m4 mandoc nbpatch p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax pkgconf png py37-argparse py37-atomicwrites py37-test-runner py37-test py37-cElementTree py37-xcbgen py37-funcsigs py37-linecache2 py37-unittest2 py37-pathlib2 py37-pbr py37-traceback2 py37-pluggy py37-py py37-scandir py37-setuptools_scm py37-setuptools_scm_git_archive rhash swig tradcpp xcb-proto xmlcatmgr xorgproto xtrans unzip"

export PKGSRC_BASE
export PREFIX
export PJOBS
 
. python37-base.sh

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

#if [ ! -f "${PREFIX}/bin/dspmqver" ]; then
#  (cd ${PREFIX} && tar xzvf ~/distfiles/9.1.3.0-IBM-MQC-Redist-LinuxX64.tar.gz) || exit 1
#fi

# odchytnout verzi pymqi
PYMQI_VERSION=`$PREFIX/bin/pip3.7 search pymqi |${GREP} -P '^pymqi\ \([0-9]' |${AWK} -F '[()]' '{print $2}'` || exit 1
echo $PYMQI_VERSION

# instalace modulu pres pip
#python3.7 setup.py build_ext --rpath /app/elastic/dists/pymqi/mqclient/lib64
#$PREFIX/bin/pip3.7 install --upgrade --force-reinstall --no-cache-dir --no-binary :all: $PIP_MODULES || exit 1

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
  $PREFIX/sbin/pkg_delete $_modules || exit 1
fi

rm -rf \
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* \
$PREFIX/lib/python3.7/bsddb/test \
$PREFIX/lib/python3.7/email/test \
$PREFIX/lib/python3.7/json/tests \
$PREFIX/lib/python3.7/unittest/test \
$PREFIX/lib/python3.7/test \
$PREFIX/lib/python3.7/ctypes/test \
$PREFIX/lib/python3.7/lib2to3/tests \
$PREFIX/lib/python3.7/sqlite3/test \
$PREFIX/lib/python3.7/distutils/tests \
$PREFIX/lib/python3.7/idlelib/idle_test \
$PREFIX/lib/python3.7/lib-tk/test || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

# vytvoreni balicku
(cd $PREFIX/.. && tar czf pymqi-${PYMQI_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz pymqi) || exit 1

