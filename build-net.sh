#!/usr/bin/env bash
#set -x

umask 022

_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/common/nettools
CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

PKGSRC_MODULES="net/nmap net/iperf2 net/iperf3 net/tcpdump net/netcat net/haproxy net/hping net/socat www/nginx www/tinyproxy"

CLEAN_MODULES="asciidoc bmake bootstrap-mk-files bzip2 ccache expat flex libidn2 libuv m4 libunistring automake autoconf bison bsdtar cmake cwrappers curl db4 digest docbook-xsl docbook-xml fontconfig getopt ghostscript-gpl ghostscript groff ghostscript-fonts freetype2 gettext-lib gettext-tools gmake gperf gtexinfo help2man jasper netpbm jbigkit tiff jpeg libarchive libffi libgcrypt libgpg-error libuuid libxml2 libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxslt makedepend mandoc nghttp2 nbpatch p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax perl pkg_install pkgconf png python38 rhash swig tradcpp unzip xcb-proto xmlcatmgr xorgproto xtrans xz"

# CLEAN_MODULES="asciidoc bzip2 ccache expat flex libidn2 libuv m4 libunistring automake autoconf bison bsdtar cmake cwrappers curl db4 digest docbook-xsl docbook-xml fontconfig getopt ghostscript-gpl ghostscript groff ghostscript-fonts freetype2 gettext-lib gettext-tools gmake gperf gtexinfo help2man jasper netpbm jbigkit tiff jpeg libarchive libffi libgcrypt libgpg-error libuuid libxml2 libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxslt makedepend mandoc nghttp2 nbpatch p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax perl pkgconf png python38 rhash swig tradcpp unzip xcb-proto xmlcatmgr xorgproto xtrans xz"

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
$PREFIX/include \
$PREFIX/conf \
$PREFIX/bin/bmake \
$PREFIX/info \
$PREFIX/man \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

# vytvoreni balicku
(cd $PREFIX/.. && tar czf nettools-`date +%Y%m%d`-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz nettools) || exit 1

