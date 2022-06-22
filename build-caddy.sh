#!/usr/bin/env bash
#set -x

umask 022

PKGSRC_BASE=/app
PREFIX=/app/httpd/apache2
CVS_BRANCH="HEAD"
#PKGSRC_URL="https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz"

#PKGSRC_MODULES="devel/chrpath rb/prometheus-ibmmq_exporter"
PKGSRC_MODULES="www/caddy"

CLEAN_MODULES="bsdtar pkgconf ccache chrpath gtexinfo ncurses p5-gettext help2man p5-Locale-libintl p5-Text-Unidecode p5-Unicode-EastAsianWidth perl bash libtool-base nbpatch cwrappers pax go14 go112 go116 go117 digest unzip zlib"
CLEAN_MODULES="$CLEAN_MODULES bmake bootstrap-mk-files pkg_install"

export PKGSRC_BASE
export PREFIX
 
. base.sh

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

VERSION=`$PREFIX/sbin/pkg_info | ${GREP} caddy | ${AWK} -F '-' '{print $2}' | ${AWK} '{print $1}'`
echo $VERSION

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
$PREFIX/conf \
$PREFIX/include \
$PREFIX/info \
$PREFIX/man \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share || exit 1

# symlink
(cd $PREFIX/bin && mv caddy httpd && ln -s httpd caddy) || exit 1

# vytvoreni balicku
(cd $PREFIX/.. && tar czf caddy-${VERSION}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz apache2) || exit 1

