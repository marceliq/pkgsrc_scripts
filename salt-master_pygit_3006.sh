#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/salt/salt3006

#CVS_BRANCH="pkgsrc-2019Q4"
#CVS_BRANCH="pkgsrc-2020Q3"
CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/pkgsrc-2018Q4/pkgsrc.tar.gz"

export PKGSRC_BASE
export PREFIX

. salt-base3006.sh

PYVER=`$PREFIX/sbin/pkg_info | $GREP -P "^python" | $SED 's/python([0-9]{2,3}).*/\1/g'`
PYVER_SEP=`echo ${PYVER:0:1}.${PYVER:1}`

#PYVER=`$GREP -P "^PYTHON_VERSION_DEFAULT" ${PKGSRC_BASE}/pkgsrc/lang/python/pyversion.mk | ${AWK} -F ' ' '{print $2}'`
#PYVER_SEP=`echo ${PYVER:0:1}.${PYVER:1}`

#PKGSRC_MODULES="devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel databases/py-redis devel/py-kafka-python devel/py-mako devel/git-base sysutils/py-kazoo time/py-dateutil www/py-cherrypy17 security/py-m2crypto security/gnupg2 sysutils/py-Glances databases/py-sqlite3"
#PKGSRC_MODULES="devel/py-pip devel/py-readline devel/py-curses /devel/py-cursespanel databases/py-redis devel/py-kafka-python devel/py-mako sysutils/py-kazoo time/py-dateutil www/py-cherrypy rb/py-m2crypto databases/py-sqlite3"
PKGSRC_MODULES="misc/screen sysutils/monit devel/py-pygit2 devel/py-pip databases/py-redis devel/py-kafka-python devel/py-mako sysutils/py-kazoo time/py-dateutil misc/py-immutables www/py-cherrypy net/py-boto net/py-boto3 textproc/py-toml wip/py-hvac"

#PIP_MODULES="jira python-consul dohq-artifactory croniter timelib hvac python-gnupg GitPython docker pywinrm pymdstat ptpython==0.41 elasticsearch"
#PIP_MODULES="jira python-consul dohq-artifactory croniter timelib hvac python-gnupg docker pywinrm pymdstat elasticsearch px-proxy"
PIP_MODULES="contextvars croniter timelib"
CLEAN_MODULES="automake autoconf bmake bootstrap-mk-files bsdtar ccache cmake cwrappers digest flex gtexinfo help2man libarchive libtool-base libuv mktools nbpatch p5-Locale-libintl p5-Text-Unidecode p5-Unicode-EastAsianWidth p5-gettext pax perl pkg_install pkgconf rhash rust py${PYVER}-build py${PYVER}-calver py${PYVER}-cython py${PYVER}-flit_core py${PYVER}-hatch-fancy-pypi-readme py${PYVER}-hatchling py${PYVER}-installer py${PYVER}-maturin py${PYVER}-pathspec py${PYVER}-pip py${PYVER}-pluggy py${PYVER}-pyproject_hooks py${PYVER}-semantic_version py${PYVER}-setuptools-rust py${PYVER}-tomli py${PYVER}-trove-classifiers py${PYVER}-wheel"

# uprava Makefile pro pygit2
#PYGIT_MODULE="devel/py-pygit2"
#MK_PATH="${PKGSRC_BASE}/pkgsrc/$PYGIT_MODULE/Makefile"

#_nol=`$GREP -P "^USE_LANGUAGES=\s+c\ c99" $MK_PATH | wc -l`
#_nol=`$GREP -P "^USE_LANGUAGES=\s+c99" $MK_PATH | wc -l`
#if [ $_nol -eq 0 ]; then
#  sed -i "s/^\(PYTHON_VERSIONS_INCOMPATIBLE=\s\+27\)/USE_LANGUAGES\=	c99\n\1/g" $MK_PATH || exit 1
#fi

#PKGSRC_MODULES="$PYGIT_MODULE $PKGSRC_MODULES"

# uprava Makefile pro monit
#MONIT_MODULE="sysutils/monit"
#MK_PATH="${PKGSRC_BASE}/pkgsrc/$MONIT_MODULE/Makefile"

#_nol=`$GREP -P "^CONFIGURE_ARGS\+=\s+--without-pam" $MK_PATH | wc -l`
#if [ $_nol -eq 0 ]; then
#  sed -i "s/^\(PKG_SYSCONFSUBDIR=\s\+monit\)/CONFIGURE_ARGS\+\=\ \ \ \ \ \ \ \ --without-pam\n\1/g" $MK_PATH || exit 1
#fi

#PKGSRC_MODULES="$MONIT_MODULE $PKGSRC_MODULES"

# uprava Makefile pro py-ldap
#PYLDAP_MODULE="databases/py-ldap"
#MK_PATH="${PKGSRC_BASE}/pkgsrc/$PYLDAP_MODULE/Makefile"

#prop='.include "../../security/cyrus-sasl/buildlink3.mk"'

#_nol=`$GREP -P "\.include\ \"\.\.\/\.\.\/security\/cyrus-sasl\/buildlink3\.mk\"" $MK_PATH | wc -l`
#if [ $_nol -eq 0 ]; then
#  echo $prop >> $MK_PATH || exit 1
#  sed -i "s/^\(\.include.*lang.*\)/\.include\ \"\.\.\/\.\.\/security\/cyrus-sasl\/buildlink3\.mk\"\n\1/g" $MK_PATH || exit 1
#fi

#PKGSRC_MODULES="$PYLDAP_MODULE $PKGSRC_MODULES"

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2,3\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake -B install clean clean-depends) || exit 1
    fi
  done

# instalace modulu pres pip
$PREFIX/bin/pip${PYVER_SEP} install $PIP_MODULES || exit 1

exit
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
#  $PREFIX/sbin/pkg_delete $_modules || exit 1
fi

rm -rf \
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* \
$PREFIX/lib/python${PYVER_SEP}/unittest/test \
$PREFIX/lib/python${PYVER_SEP}/test \
$PREFIX/lib/python${PYVER_SEP}/ctypes/test \
$PREFIX/lib/python${PYVER_SEP}/lib2to3/tests \
$PREFIX/lib/python${PYVER_SEP}/tkinter/test \
$PREFIX/lib/python${PYVER_SEP}/idlelib/idle_test || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

# vytvoreni balicku
(cd $PREFIX/.. && tar czf salt-master-${SALT_VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz salt3006) || exit 1

