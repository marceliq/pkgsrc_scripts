#!/usr/bin/env bash
#set -x

umask 022

_CWD=`pwd`

PKGSRC_BASE=/app
PREFIX=/app/common/www

CVS_BRANCH="HEAD"

export PKGSRC_BASE
export PREFIX

. base.sh


#PKGSRC_MODULES="devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel databases/py-redis devel/py-kafka-python devel/py-mako devel/git-base sysutils/py-kazoo time/py-dateutil www/py-cherrypy17 security/py-m2crypto security/gnupg2 sysutils/py-Glances databases/py-sqlite3"
PKGSRC_MODULES="security/mozilla-rootcerts-openssl devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel net/wget net/httptunnel"

#PIP_MODULES="jira python-consul dohq-artifactory croniter timelib hvac python-gnupg GitPython docker pywinrm pymdstat ptpython==0.41 elasticsearch"
PIP_MODULES="px-proxy"


# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

PYVER=`$GREP -P "^PYTHON_VERSION_DEFAULT" ${PKGSRC_BASE}/pkgsrc/lang/python/pyversion.mk | ${AWK} -F ' ' '{print $2}'`
PYVER_SEP=`echo ${PYVER:0:1}.${PYVER:1}`

# instalace modulu pres pip
$PREFIX/bin/pip${PYVER_SEP} install $PIP_MODULES || exit 1

# odchytnout verzi saltu
VERSION=`$PREFIX/sbin/pkg_info | ${GREP} wget | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`
echo $VERSION

CLEAN_MODULES="automake autoconf bison bmake bootstrap-mk-files bsdtar ccache cmake cwrappers digest docbook-xsl docbook-xml fontconfig ghostscript-gpl ghostscript groff ghostscript-fonts freetype2 gettext-lib gettext-tools ghostscript-agpl gmake gperf gtexinfo help2man jasper jbig2dec netpbm jbigkit tiff jpeg lcms2 libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxslt makedepend mandoc nbpatch openjpeg p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax perl pkg_install pkgconf png py${PYVER}-argparse py${PYVER}-atomicwrites py${PYVER}-test py${PYVER}-attrs py${PYVER}-cElementTree py${PYVER}-xcbgen py${PYVER}-funcsigs py${PYVER}-linecache2 py${PYVER}-unittest2 py${PYVER}-pathlib2 py${PYVER}-pbr py${PYVER}-traceback2 py${PYVER}-pluggy py${PYVER}-py py${PYVER}-scandir py${PYVER}-setuptools_scm py${PYVER}-setuptools_scm_git_archive rhash swig tradcpp xcb-proto xorgproto xtrans urw-fonts"

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
$PREFIX/lib/python${PYVER_SEP}/tkinter/test \
$PREFIX/lib/python${PYVER_SEP}/distutils/tests \
$PREFIX/lib/python${PYVER_SEP}/idlelib/idle_test \
$PREFIX/lib/python${PYVER_SEP}/lib-tk/test || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

# vytvoreni balicku
(cd $PREFIX/.. && tar czf www-${VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz www) || exit 1

