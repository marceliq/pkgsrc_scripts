#!/usr/bin/env bash
#set -x

umask 022

_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/kafka/dist/cx_oracle

CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"
#PKGSRC_URL="ftp://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"
#PKGSRC_URL="ftp://ftp.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.gz"

#PKGSRC_MODULES="lang/gcc7"
PKGSRC_MODULES="devel/patchelf wip/libaio devel/py-readline devel/py-curses /devel/py-cursespanel databases/py-cx_Oracle"
PIP_MODULES="confluent-kafka[avro]"

CLEAN_MODULES="bmake bootstrap-mk-files bsdtar ccache cwrappers digest expat libtool-base nbpatch pax perl pkg_install pkgconf py39-expat py39-setuptools"

export PKGSRC_BASE
export PREFIX
 
#. python37-base.sh
. base.sh

if [ ! -d "${PKGSRC_BASE}/pkgsrc/wip" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 git://wip.pkgsrc.org/pkgsrc-wip.git wip) || exit 1
fi

# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

props=""
#props="USE_NATIVE_GCC=\tyes CHECK_COMPILER=\tyes"
#props="USE_PKGSRC_GCC=\tyes USE_PKGSRC_GCC_RUNTIME=\tyes CHECK_COMPILER=\tyes"
#props="USE_NATIVE_GCC=\tyes USE_PKGSRC_GCC=\tyes USE_PKGSRC_GCC_RUNTIME=\tyes CHECK_COMPILER=\tyes"

for prop in $props
  do
    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done

# ztazeni oracle instatn clienta
# https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip
_nol=`ls -1 $PREFIX | grep instantclient | wc -l`
if [ $_nol -eq 0 ]; then
  TMPFILE_IC=`mktemp`
  TMPFILE_SQLPLUS=`mktemp`
  TMPFILE_SDK=`mktemp`
  $CURL -JL "https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip" >$TMPFILE_IC || exit 1
  $CURL -JL "https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip" >$TMPFILE_SDK || exit 1
  $CURL -JL "https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip" >$TMPFILE_SQLPLUS || exit 1
  unzip -d $PREFIX $TMPFILE_IC || exit 1
  unzip -d $PREFIX $TMPFILE_SDK || exit 1
  unzip -d $PREFIX $TMPFILE_SQLPLUS || exit 1
  rm $TMPFILE_IC $TMPFILE_SDK $TMPFILE_SQLPLUS || exit 1
fi
_oh=`ls -1 $PREFIX | grep instantclient` 
ORACLE_HOME="$PREFIX/$_oh"
export ORACLE_HOME
#FORCE_RPATH=1
#export FORCE_RPATH

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |perl -nle "print if m/^$_module/" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

exit

# odchytnout verzi
VERSION=`$PREFIX/sbin/pkg_info | ${GREP} -i cx_oracle | ${AWK} -F '-' '{print $3}' | ${AWK} '{print $1}'`
echo $VERSION

# instalace modulu pres pip
#$PREFIX/bin/pip3.8 install $PIP_MODULES || exit 1

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
fi

rm -rf \
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* \
$PREFIX/lib/python3.9/bsddb/test \
$PREFIX/lib/python3.9/email/test \
$PREFIX/lib/python3.9/json/tests \
$PREFIX/lib/python3.9/unittest/test \
$PREFIX/lib/python3.9/test \
$PREFIX/lib/python3.9/ctypes/test \
$PREFIX/lib/python3.9/lib2to3/tests \
$PREFIX/lib/python3.9/sqlite3/test \
$PREFIX/lib/python3.9/distutils/tests \
$PREFIX/lib/python3.9/idlelib/idle_test \
$PREFIX/lib/python3.9/lib-tk/test || exit 1

for f in `find ${PREFIX} -type f | ${GREP} -P '\.pyc$|\.pyo$|\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

# vytvoreni balicku
(cd $PREFIX/.. && ${TAR} czf cx_oracle-${VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz cx_oracle) || exit 1

