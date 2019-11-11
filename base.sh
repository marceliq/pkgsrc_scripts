#!/usr/bin/env bash
#set -x

umask 022

# Nastavi korekne utility dle platformy
AWK=awk
GREP=grep
EGREP=egrep
TAR=tar
CURL=curl
SED="perl -pi -e"

case "`uname`" in
    CYGWIN*)
        cygwin=true
        ;;

    Darwin*)
        darwin=true
        ;;

    Linux)
        linux=true
        PJOBS=`nproc`
        ;;

    SunOS*)
        solaris=true
        AWK=nawk
        GREP=/usr/sfw/bin/ggrep
        EGREP=/usr/sfw/bin/gegrep
        TAR=/usr/sfw/bin/gtar
        WGET=/usr/sfw/bin/wget
        PJOBS=`/usr/sbin/psrinfo -p`
        CC=/usr/sfw/bin/gcc
        ;;

    *)
        other=true
        ;;
esac

#CONFDIR="/app/httpd/conf"

# Stazeni a vybaleni pkgsrc
if [ ! -f "${PKGSRC_BASE}/pkgsrc/bootstrap/bootstrap" ]; then
  if [ "$solaris" = true ]; then
    (cd $PKGSRC_BASE && $WGET -q -O - ${PKGSRC_URL} | ${TAR} -xzf -) || exit 1
  elif [ -v CVS_BRANCH ]; then
    (cd $PKGSRC_BASE && cvs -q -z2 -d anoncvs@anoncvs.NetBSD.org:/cvsroot checkout -r ${CVS_BRANCH} -P pkgsrc) || exit 1
  else
    (cd $PKGSRC_BASE && $CURL -L ${PKGSRC_URL} | ${TAR} -xzf -) || exit 1
  fi
fi

# prolink distfiles do pevneho uloziste
if [ ! -d "${HOME}/distfiles" ]; then
  mkdir ${HOME}/distfiles || exit 1
fi

if [ "$solaris" = false ]; then
  if [ -d "${PKGSRC_BASE}/pkgsrc/distfiles" ]; then
    (cd $PKGSRC_BASE/pkgsrc && rm -rf distfiles && ln -s ${HOME}/distfiles .) || exit 1
  fi
fi

# bootstrap
cd ${PKGSRC_BASE}/pkgsrc/bootstrap || exit 1
if [ "$solaris" = true ]; then
  if [ ! -d "${PKGSRC_BASE}/pkgsrc/bootstrap/work" ]; then
    CC=$CC LDFLAGS="-Wl,--strip-all" SHARED_LDFLAGS="-Wl,--strip-all" CFLAGS="-Os" CPPFLAGS="-Os" CXXFLAGS="-0s" ./bootstrap --abi 32 --make-jobs $PJOBS --prefer-pkgsrc no --prefix $PREFIX --unprivileged --sysconfdir $CONFDIR || exit 1
  fi
else
  if [ ! -d "${PKGSRC_BASE}/pkgsrc/bootstrap/work" ]; then
    LDFLAGS="-Wl,--strip-all" SHARED_LDFLAGS="-Wl,--strip-all" CFLAGS="-Os" CPPFLAGS="-Os" CXXFLAGS="-0s" ./bootstrap --abi 64 --make-jobs $PJOBS --prefer-pkgsrc yes --prefix $PREFIX --unprivileged --sysconfdir $CONFDIR --varbase $VARBASE || exit 1
#    ./bootstrap --abi 64 --make-jobs $PJOBS --prefer-pkgsrc yes --prefix $PREFIX --unprivileged --sysconfdir $CONFDIR || exit 1
  fi
fi

# nastaveni env var PATH
PATH=$PREFIX/bin:$PATH

if [ "$solaris" = true ]; then
  PATH=$PREFIX/bin:$PATH:/usr/sbin:/usr/bin:/usr/dt/bin:/usr/ucb:/usr/ccs/bin:/usr/sfw/bin
  props="FETCH_USING=\t\tfetch CC=\t\t\t\/usr\/sfw\/bin\/gcc PKG_DEVELOPER=\t\tyes"
else
  props="MAKE_JOBS=\t\t$PJOBS SKIP_LICENSE_CHECK=\tyes"
fi

MKCONF_PATH=$CONFDIR/mk.conf

for prop in $props
  do
    _nol=`perl -nle "print if m/$prop/" $MKCONF_PATH | wc -l`
    if [ $_nol -eq 0 ]; then
      $SED "s/(\.endif.*)/$prop\n\1/g" $MKCONF_PATH || exit 1
    fi
  done

export PATH

