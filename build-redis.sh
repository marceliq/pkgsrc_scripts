#!/usr/bin/env bash
#set -x

umask 022

_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/elastic/dists/redis

CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

PKGSRC_MODULES="databases/redis"

CLEAN_MODULES="bmake bootstrap-mk-files bzip2 ccache expat ncurses libidn2 perl libuv m4 libunistring automake autoconf bison bsdtar cmake cwrappers curl digest docbook-xsl docbook-xml fontconfig ghostscript-gpl ghostscript groff ghostscript-fonts freetype2 gettext-lib gettext-tools gmake gperf gtexinfo help2man jasper netpbm jbigkit tiff jpeg libarchive libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxml2 libxslt makedepend mandoc nbpatch p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax pkgconf pkg_install png py27-argparse py27-atomicwrites py27-test py27-attrs py27-cElementTree py27-xcbgen py27-funcsigs py27-linecache2 py27-unittest2 py27-pathlib2 py27-pbr py27-traceback2 py27-pluggy py27-py py27-scandir py27-setuptools_scm py27-setuptools_scm_git_archive rhash swig tradcpp xcb-proto xmlcatmgr xorgproto xtrans zlib"

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

