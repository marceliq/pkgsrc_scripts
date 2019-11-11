#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/zabbix
PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.gz"
PJOBS=8

PKGSRC_MODULES="sysutils/zabbix"
#PIP_MODULES="jira python-consul dohq-artifactory croniter timelib hvac python-gnupg docker-py GitPython"

CLEAN_MODULES=""

export PKGSRC_BASE
export PREFIX
export PJOBS
 
. base.sh

# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

props="CFLAGS-=\t\t-O2 CXXFLAGS-=\t\t-O2 CPPFLAGS-=\t\t-O2 MAKE_JOBS=\t\t$PJOBS SKIP_LICENSE_CHECK=\tyes"

for prop in $props
  do
    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done

# uprava Makefile pro monit
MONIT_MODULE="sysutils/monit"
MK_PATH="${PKGSRC_BASE}/pkgsrc/$MONIT_MODULE/Makefile"

_nol=`$GREP -P "^CONFIGURE_ARGS\+=\s+--without-pam" $MK_PATH | wc -l`
if [ $_nol -eq 0 ]; then
  sed -i "s/^\(PKG_SYSCONFSUBDIR=\s\+monit\)/CONFIGURE_ARGS\+\=\ \ \ \ \ \ \ \ --without-pam\n\1/g" $MK_PATH || exit 1
fi

PKGSRC_MODULES="$MONIT_MODULE $PKGSRC_MODULES"

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

# odchytnout verzi saltu
ZABBIX_VERSION=`$PREFIX/sbin/pkg_info | ${GREP} zabbix | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`
echo $ZABBIX_VERSION

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

#rm -rf \
#$PREFIX/include/* \
#$PREFIX/info/* \
#$PREFIX/man/* \
#$PREFIX/pkgdb \
#$PREFIX/pkgdb.refcount \
#$PREFIX/share/doc/* \

#for f in `find ${PREFIX} -type f | ${GREP} -P 'pyc$|pyo$'`; do rm -f ${f}; done

# pridani monitrc pro salt
#echo "check process salt-master" >$PREFIX/conf/monit/monitrc
#echo "  with pidfile /app/salt/var/run/salt-master.pid" >>$PREFIX/conf/monit/monitrc
#echo "  start "/app/salt/bin/salt-master -d"" >>$PREFIX/conf/monit/monitrc
#echo "  stop "/app/salt/saltkillall" " >>$PREFIX/conf/monit/monitrc

# vytvoreni balicku
#(cd $PREFIX/.. && tar czf salt-master-${SALT_VERSION}-`uname -s`-`uname -p`.tar.gz salt) || exit 1

