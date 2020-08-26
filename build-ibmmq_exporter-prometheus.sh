#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/elastic/dists/prometheus/ibmmq_exporter
CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

#PKGSRC_MODULES="devel/chrpath rb/prometheus-ibmmq_exporter"
PKGSRC_MODULES="rb/prometheus-ibmmq_exporter"

CLEAN_MODULES="chrpath ncurses perl bash libtool-base cwrappers pax go14 go112 digest"

export PKGSRC_BASE
export PREFIX
 
. base.sh

if [ ! -d "${PKGSRC_BASE}/pkgsrc/rb" ]; then
  (cd $PKGSRC_BASE/pkgsrc && git clone --depth 1 https://github.com/marceliq/rb.git rb) || exit 1
fi

exit
# doplneni promennych do mk.conf
#MKCONF_PATH=$PREFIX/conf/mk.conf

#props="CFLAGS-=\t\t-Os CXXFLAGS-=\t\t-Os CPPFLAGS-=\t\t-Os"

#for prop in $props
#  do
#    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
#    if [ $_nol -eq 0 ]; then
#      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
#    fi
#  done

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

VERSION=`$PREFIX/sbin/pkg_info | ${GREP} mq-metric-samples | ${AWK} -F '-' '{print $4}' | ${AWK} '{print $1}'`

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

rm -rf \
$PREFIX/include \
$PREFIX/conf \
$PREFIX/bin/bmake \
$PREFIX/info \
$PREFIX/man \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share || exit 1

# vytvoreni balicku
(cd $PREFIX/.. && tar czf ibmmq_exporter-prometheus-${VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz ibmmq_exporter/bin/mq_prometheus ibmmq_exporter/ibm-mqc-redist) || exit 1

