#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/httpd/apache2
CONFDIR=/app/httpd/conf
VARBASE=/app/httpd/var

CVS_BRANCH="HEAD"
#PKGSRC_URL="ftp://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

#PKGSRC_MODULES="rb/ap24-auth-gssapi rb/ap-modsecurity2 rb/ap-php"
PKGSRC_MODULES="rb/ap24-auth-gssapi"

export PKGSRC_BASE
export PREFIX
export CONFDIR
export VARBASE

. base.sh

if [ ! -d "${PKGSRC_BASE}/pkgsrc/rb" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 https://github.com/marceliq/rb.git rb) || exit 1
fi

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |perl -nle "print if m/^$_module/" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

CLEAN_MODULES="mktools lz4 bmake bootstrap-mk-files pkg_install ccache libuv libidn2 libarchive flex perl curl automake autoconf bison bsdtar cmake cwrappers digest docbook-xsl docbook-xml fontconfig ghostscript-gpl ghostscript googletest groff ghostscript-fonts freetype2 gettext-lib gettext-tools gmake gperf gtexinfo help2man jasper netpbm jbigkit tiff jpeg libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxslt makedepend m4 mandoc nbpatch p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax pkgconf png rhash swig tradcpp xcb-proto xorgproto xtrans unzip zstd"

# odchytnout verzi
APACHE_VERSION=`$PREFIX/sbin/pkg_info | ${GREP} apache-2 | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`
echo $APACHE_VERSION

OPENSSL_VERSION=`$PREFIX/sbin/pkg_info | ${GREP} openssl | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`
echo $OPENSSL_VERSION

# cisteni prefixu
_modules=""
for module in $CLEAN_MODULES
  do
    _module=`echo $module | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |perl -nle "print if m/^$_module-[0-9]/" |wc -l`
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
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* \
$PREFIX/lib/libkadm5clnt.la \
$PREFIX/lib/libkadm5srv.la \

for f in `find ${PREFIX} -type f | perl -nle 'print if m/\.pyc$|\.pyo$|\.a$|\.la$/'`; do rm -f ${f}; done

# vytvoreni balicku
(cd $PREFIX/../.. && ${TAR} czf httpd-${APACHE_VERSION}-openssl-${OPENSSL_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz httpd) || exit 1

