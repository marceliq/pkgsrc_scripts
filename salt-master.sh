#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/salt

#CVS_BRANCH="pkgsrc-2019Q4"
CVS_BRANCH="pkgsrc-2020Q3"
#CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/pkgsrc-2018Q4/pkgsrc.tar.gz"

PKGSRC_MODULES="devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel databases/py-redis devel/py-kafka-python devel/py-mako devel/git-base sysutils/py-kazoo time/py-dateutil www/py-cherrypy17 security/py-m2crypto security/gnupg2 sysutils/py-Glances databases/py-sqlite3"
PIP_MODULES="jira python-consul dohq-artifactory croniter timelib hvac python-gnupg GitPython docker pywinrm pymdstat ptpython==0.41 elasticsearch"

CLEAN_MODULES="automake autoconf bison bmake bootstrap-mk-files bsdtar cmake cwrappers digest docbook-xsl docbook-xml fontconfig ghostscript-gpl ghostscript groff ghostscript-fonts freetype2 gettext-lib gettext-tools ghostscript-agpl gmake gperf gtexinfo help2man jasper jbig2dec netpbm jbigkit tiff jpeg lcms2 libICE libSM libXt libXaw libXmu libXpm libX11 libXext libXau libxcb libXdmcp libpaper libtool-base libxslt makedepend mandoc nbpatch openjpeg p5-CPAN-Meta p5-Locale-libintl p5-Module-Build p5-Perl4-CoreLibs p5-Scalar-List-Utils p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext p5-inc-latest p5-Sub-Uplevel p5-Test-Exception p5-Test-Warn p5-Test-NoWarnings p5-Test-Simple pax pkg_install pkgconf png py27-argparse py27-atomicwrites py27-test py27-attrs py27-cElementTree py27-xcbgen py27-funcsigs py27-linecache2 py27-unittest2 py27-pathlib2 py27-pbr py27-traceback2 py27-pluggy py27-py py27-scandir py27-setuptools_scm py27-setuptools_scm_git_archive rhash swig swig3 tradcpp xcb-proto xorgproto xtrans urw-fonts"

export PKGSRC_BASE
export PREFIX

. salt-base.sh

# uprava Makefile pro monit
MONIT_MODULE="sysutils/monit"
MK_PATH="${PKGSRC_BASE}/pkgsrc/$MONIT_MODULE/Makefile"

_nol=`$GREP -P "^CONFIGURE_ARGS\+=\s+--without-pam" $MK_PATH | wc -l`
if [ $_nol -eq 0 ]; then
  sed -i "s/^\(PKG_SYSCONFSUBDIR=\s\+monit\)/CONFIGURE_ARGS\+\=\ \ \ \ \ \ \ \ --without-pam\n\1/g" $MK_PATH || exit 1
fi

PKGSRC_MODULES="$MONIT_MODULE $PKGSRC_MODULES"

# uprava Makefile pro py-ldap
PYLDAP_MODULE="databases/py-ldap"
MK_PATH="${PKGSRC_BASE}/pkgsrc/$PYLDAP_MODULE/Makefile"

#prop='.include "../../security/cyrus-sasl/buildlink3.mk"'

_nol=`$GREP -P "\.include\ \"\.\.\/\.\.\/security\/cyrus-sasl\/buildlink3\.mk\"" $MK_PATH | wc -l`
if [ $_nol -eq 0 ]; then
#  echo $prop >> $MK_PATH || exit 1
  sed -i "s/^\(\.include.*lang.*\)/\.include\ \"\.\.\/\.\.\/security\/cyrus-sasl\/buildlink3\.mk\"\n\1/g" $MK_PATH || exit 1
fi

PKGSRC_MODULES="$PYLDAP_MODULE $PKGSRC_MODULES"

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
$PREFIX/bin/pip2.7 install $PIP_MODULES || exit 1

# vytvoreni killovacich skriptu
_TYPES="master minion syndic api"
for _type in $_TYPES
  do
    echo "kill \`cat ${PREFIX}/var/run/salt-${_type}.pid\`" >"$PREFIX/bin/salt-kill-$_type"
    chmod +x $PREFIX/bin/salt-kill-$_type || exit 1
  done

# pridani monitrc pro salt
echo "check process salt-master" >$PREFIX/conf/monit/monitrc
echo "  with pidfile ${PREFIX}/var/run/salt-master.pid" >>$PREFIX/conf/monit/monitrc
echo "  start ${PREFIX}/bin/salt-master -d" >>$PREFIX/conf/monit/monitrc
echo "  stop ${PREFIX}/bin/salt-kill-master" >>$PREFIX/conf/monit/monitrc
echo >>$PREFIX/conf/monit/monitrc
echo "check process salt-minion" >>$PREFIX/conf/monit/monitrc
echo "  with pidfile ${PREFIX}/var/run/salt-minion.pid" >>$PREFIX/conf/monit/monitrc
echo "  start ${PREFIX}/bin/salt-minion -d" >>$PREFIX/conf/monit/monitrc
echo "  stop ${PREFIX}/bin/salt-kill-minion" >>$PREFIX/conf/monit/monitrc
echo >>$PREFIX/conf/monit/monitrc
echo "#check process salt-syndic" >>$PREFIX/conf/monit/monitrc
echo "#  with pidfile ${PREFIX}/var/run/salt-syndic.pid" >>$PREFIX/conf/monit/monitrc
echo "#  start ${PREFIX}/bin/salt-syndic -d" >>$PREFIX/conf/monit/monitrc
echo "#  stop ${PREFIX}/bin/salt-kill-syndic" >>$PREFIX/conf/monit/monitrc
echo >>$PREFIX/conf/monit/monitrc
echo "#check process salt-api" >>$PREFIX/conf/monit/monitrc
echo "#  with pidfile ${PREFIX}/var/run/salt-api.pid" >>$PREFIX/conf/monit/monitrc
echo "#  start ${PREFIX}/bin/salt-api -d" >>$PREFIX/conf/monit/monitrc
echo "#  stop ${PREFIX}/bin/salt-kill-api" >>$PREFIX/conf/monit/monitrc

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
$PREFIX/lib/python2.7/bsddb/test \
$PREFIX/lib/python2.7/email/test \
$PREFIX/lib/python2.7/json/tests \
$PREFIX/lib/python2.7/unittest/test \
$PREFIX/lib/python2.7/test \
$PREFIX/lib/python2.7/ctypes/test \
$PREFIX/lib/python2.7/lib2to3/tests \
$PREFIX/lib/python2.7/sqlite3/test \
$PREFIX/lib/python2.7/distutils/tests \
$PREFIX/lib/python2.7/idlelib/idle_test \
$PREFIX/lib/python2.7/lib-tk/test || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

# vytvoreni balicku
(cd $PREFIX/.. && tar czf salt-master-${SALT_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz salt) || exit 1

