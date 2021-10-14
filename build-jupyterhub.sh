#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/testik

CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"
#PKGSRC_URL="ftp://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"
#PKGSRC_URL="ftp://ftp.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.gz"

PKGSRC_MODULES="devel/py-ipython_genutils www/py-notebook devel/py-pip lang/npm"
PIP_MODULES="confluent-kafka[avro] jupyterhub"
NPM_MODULES="configurable-http-proxy"

CLEAN_MODULES=""

export PKGSRC_BASE
export PREFIX
 
#. python37-base.sh
. base.sh

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |perl -nle "print if m/^$_module/" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

#if [ ! -f "${PREFIX}/conf/openssl/certs/ca-certificates.crt" ]; then
#  bash ${PREFIX}/sbin/mozilla-rootcerts install || exit 1
#fi

# instalace modulu pres pip
$PREFIX/bin/pip3.8 install $PIP_MODULES || exit 1

# instalace modulu pres npm
$PREFIX/bin/npm install -g $NPM_MODULES || exit 1

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

exit

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

for f in `find ${PREFIX} -type f | perl -nle 'print if m/pyc$|pyo$/'`; do rm -f ${f}; done

# vytvoreni balicku
(cd $PREFIX/.. && ${TAR} czf glances-${VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz glances) || exit 1

