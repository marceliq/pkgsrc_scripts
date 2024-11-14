#!/usr/bin/env bash
#set -x

umask 022
_CWD=`pwd`
PKGSRC_BASE=/app
PREFIX=/app/common/lang/nodejs
CVS_BRANCH="HEAD"

PKGSRC_MODULES="lang/gcc10-libs lang/nodejs"

CLEAN_MODULES="autoconf automake bmake bootstrap-mk-files bsdtar bzip2 cmake curl cwrappers db4 digest expat gcc10 gdbm gdbm_compat gtexinfo help2man libarchive libffi libidn2 libtool-base libunistring libuuid lz4 mktools nbpatch ncurses p5-gettext p5-Locale-libintl p5-Text-Unidecode p5-Unicode-EastAsianWidth pax perl pkgconf pkg_install py312-flit_core py312-installer py312-pyparsing py312-packaging python312 readline rhash sqlite3 zstd"
#CLEAN_MODULES="autoconf automake bsdtar bzip2 cmake curl cwrappers db4 digest expat gcc10 gdbm gdbm_compat gtexinfo help2man libarchive libffi libidn2 libtool-base libunistring libuuid lz4 mktools nbpatch ncurses p5-gettext p5-Locale-libintl p5-Text-Unidecode p5-Unicode-EastAsianWidth pax perl pkgconf py312-flit_core py312-installer py312-pyparsing py312-packaging python312 readline rhash sqlite3 zstd"

export PKGSRC_BASE
export PREFIX

. base.sh
# doplneni promennych do mk.conf
MKCONF_PATH=$PREFIX/conf/mk.conf

props="PKG_OPTIONS.nodejs=\topenssl"

for prop in $props
  do
    _nol=`$GREP -P "$prop" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      sed -i "s/\(\.endif.*\)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done

#NODEVER=`$GREP -P "^PY_DISTVERSION" ${PKGSRC_BASE}/pkgsrc/lang/nodejs/dist.mk | ${AWK} -F ' ' '{print $2}'`
#echo $NODEVER

# instalace pkgsrc modulu
for module in $PKGSRC_MODULES
  do
    _module=`echo $module | sed 's/.*\/\(.*\)/\1/g' | sed 's/py-/py\[0-9\]\{2\}-/g'`
    _nol=`$PREFIX/sbin/pkg_info |$GREP -P "^$_module" |wc -l`
    if [ $_nol -eq 0 ]; then
      (cd ${PKGSRC_BASE}/pkgsrc/$module && bmake install clean clean-depends) || exit 1
    fi
  done

exit

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
#  $PREFIX/sbin/pkg_delete $_modules || exit 1
  $PREFIX/sbin/pkg_delete -ff $_modules || exit 1
fi

rm -rf \
$PREFIX/include/* \
$PREFIX/info/* \
$PREFIX/man/* \
$PREFIX/pkgdb \
$PREFIX/pkgdb.refcount \
$PREFIX/share/doc/* \

for f in `find ${PREFIX} -type f | ${GREP} -P '\.a$|\.la$'`; do rm -f ${f}; done

_actual=`pwd`
(cd $PREFIX && python3 $_CWD/origin_rpath.py) || exit 1
cd $_actual

exit
# vytvoreni balicku
(cd $PREFIX/.. && tar czf python-${PYVER}-`uname -s | tr '[:upper:]' '[:lower:]'`-`uname -p`.tar.gz python3.11) || exit 1

