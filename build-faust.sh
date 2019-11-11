#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/elastic/dists/faust
PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"
PJOBS=`nproc`

PKGSRC_MODULES="devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel databases/py-elasticsearch databases/py-redis devel/py-kafka-python sysutils/py-kazoo www/py-aiohttp databases/py-sqlalchemy databases/py-sqlalchemy-i18n wip/rocksdb"
PIP_MODULES="aredis aioinflux elasticsearch-async faust faust[rocksdb]"

CLEAN_MODULES="automake autoconf bison bsdtar cmake cwrappers digest docbook-xsl docbook-xml fontconfig ghostscript-gpl ghostscript googletest groff ghostscript-fonts freetype2 gettext-lib gettext-tools gmake gperf gtexinfo help2man jasper netpbm jbigkit tiff jpeg libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxml2 libxslt makedepend m4 mandoc nbpatch p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax pkgconf png py37-argparse py37-atomicwrites py37-test-runner py37-test py37-cElementTree py37-xcbgen py37-funcsigs py37-linecache2 py37-unittest2 py37-pathlib2 py37-pbr py37-traceback2 py37-pluggy py37-py py37-scandir py37-setuptools_scm py37-setuptools_scm_git_archive rhash swig tradcpp xcb-proto xmlcatmgr xorgproto xtrans unzip"

export PKGSRC_BASE
export PREFIX
export PJOBS
 
. python37-base.sh

if [ ! -d "${PKGSRC_BASE}/pkgsrc/wip" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 git://wip.pkgsrc.org/pkgsrc-wip.git wip) || exit 1
fi

if [ -f "${PKGSRC_BASE}/pkgsrc/wip/rocksdb/patches/patch-port_stack__trace.cc" ]; then
  rm -f ${PKGSRC_BASE}/pkgsrc/wip/rocksdb/patches/patch-port_stack__trace.cc || exit 1
fi

# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

#props="PKG_OPTIONS.rocksdb\+=\tbz2 PKG_OPTIONS.rocksdb\+=\tjni PKG_OPTIONS.rocksdb\+=\tlz4 PKG_OPTIONS.rocksdb\+=\trados PKG_OPTIONS.rocksdb\+=\tsnappy PKG_OPTIONS.rocksdb\+=\tsse42 PKG_OPTIONS.rocksdb\+=\tzlib PKG_OPTIONS.rocksdb\+=\tzstd"

props="PKG_OPTIONS.rocksdb\+=\tbz2 PKG_OPTIONS.rocksdb\+=\tlz4 PKG_OPTIONS.rocksdb\+=\tsnappy PKG_OPTIONS.rocksdb\+=\tportable PKG_OPTIONS.rocksdb\+=\tzlib PKG_OPTIONS.rocksdb\+=\tzstd"

for prop in $props
  do
    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done

_nol=`$GREP -P "Mportable" ${PKGSRC_BASE}/pkgsrc/wip/rocksdb/options.mk | wc -l`
if [ $_nol -eq 0 ]; then
  sed -i "s/PKG_SUPPORTED_OPTIONS\(.*\)/PKG_SUPPORTED_OPTIONS\1\ portable/g" ${PKGSRC_BASE}/pkgsrc/wip/rocksdb/options.mk || exit 1
  echo >> ${PKGSRC_BASE}/pkgsrc/wip/rocksdb/options.mk
  echo ".if !empty(PKG_OPTIONS:Mportable)" >> ${PKGSRC_BASE}/pkgsrc/wip/rocksdb/options.mk
  echo "MAKE_ENV+=      PORTABLE=1" >> ${PKGSRC_BASE}/pkgsrc/wip/rocksdb/options.mk
  echo ".endif" >> ${PKGSRC_BASE}/pkgsrc/wip/rocksdb/options.mk
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

# odchytnout verzi faustu
FAUST_VERSION=`$PREFIX/bin/pip3.7 search faust |${GREP} -P '^faust\ \([0-9]' |${AWK} -F '[()]' '{print $2}'` || exit 1
echo $FAUST_VERSION

# instalace modulu pres pip
$PREFIX/bin/pip3.7 install $PIP_MODULES || exit 1

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
(cd $PREFIX/.. && tar czf faust-${FAUST_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz faust) || exit 1

