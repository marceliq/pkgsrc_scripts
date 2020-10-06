#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/salt

#CVS_BRANCH="pkgsrc-2019Q4"
CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/pkgsrc-2018Q4/pkgsrc.tar.gz"

PKGSRC_MODULES="security/mozilla-rootcerts-openssl devel/py-pip devel/py-readline devel/py-pygit2 devel/py-mako security/py-m2crypto security/gnupg2"
PIP_MODULES="croniter timelib hvac python-gnupg docker"

CLEAN_MODULES="automake autoconf bison bmake bootstrap-mk-files bsdtar cmake cwrappers digest docbook-xsl docbook-xml fontconfig ghostscript-gpl ghostscript groff ghostscript-fonts freetype2 gettext-lib gettext-tools ghostscript-agpl gmake gperf gtexinfo help2man jasper jbig2dec netpbm jbigkit tiff jpeg lcms2 libarchive libuv libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxslt makedepend mandoc nbpatch openjpeg pcre perl p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax pkg_install pkgconf png py37-argparse py37-atomicwrites py37-test py37-attrs py37-cElementTree py37-xcbgen py37-funcsigs py37-linecache2 py37-unittest2 py37-pathlib2 py37-pbr py37-traceback2 py37-pluggy py37-pip py37-py py37-scandir py37-setuptools_scm py37-setuptools_scm_git_archive rhash swig swig3 tradcpp xcb-proto xorgproto xtrans urw-fonts"

export PKGSRC_BASE
export PREFIX

. salt-base.sh

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
$PREFIX/bin/pip3.7 install $PIP_MODULES || exit 1

# odchytnout verzi saltu
SALT_VERSION=`$PREFIX/sbin/pkg_info | ${GREP} salt | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`
echo $SALT_VERSION

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
(cd $PREFIX/.. && tar czf salt-docker-${SALT_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz salt) || exit 1

