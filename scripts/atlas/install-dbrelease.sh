#!/bin/sh

VERSION="$1"
DBREL="$2"
HOST_CE="$3"
DBRELNAME=DBRelease-$DBREL

# Help
if [ "$1" == "" -o "$2" == "" -o "$3" == "" ] ; then
  echo "Usage: `basename` $0 <version> <db version> <CE fqdn>"
  exit -1
fi

# General setup
experiment=atlas
LCG_DIR=${LCG_LOCATION}/bin
TAG="VO-${experiment}-dbrelease-${DBREL}-${VERSION}"
DBRELCACHE="http://atlas.web.cern.ch/Atlas/GROUPS/DATABASE/pacman4/DBRelease"

# Download and/or setup pacman
[ "$PACMAN_VER" == "" ] && PACMAN_VER=3.15
PACMAN_DIR=pacman-${PACMAN_VER}
PACMAN_TAR=${PACMAN_DIR}.tar.gz
PACMAN_URL=http://physics.bu.edu/~youssef/pacman/sample_cache/tarballs
[ "$PACMAN_OPTS" == "" ] && export PACMAN_OPTS="-trust-all-caches -allow unsupported-platforms -allow bad-tar-filenames"
if [ "$platform" != "" -a "$platform" != "auto" ] ; then
  PACMAN_OPTS="$PACMAN_OPTS -pretend-platform $platform"
fi
cd $VO_ATLAS_SW_DIR
if [ ! -d $PACMAN_DIR ]; then
  echo "INSTALLER> Pacman not found: installing it."
  wget $PACMAN_URL/$PACMAN_TAR
  \ls -l $PACMAN_TAR
  tar xzvf $PACMAN_TAR
  rm -fr $PACMAN_TAR
fi
cd $PACMAN_DIR
source setup.sh

# Install the db release
source $VO_ATLAS_SW_DIR/software/$VERSION/setup.sh
DBRELMAJ="`echo $DBREL | cut -d. -f 1`"
DBRELMIN="`echo $DBREL | cut -d. -f 2`"
if [ $DBRELMAJ -eq 2 -a $DBRELMIN -le 1 ] ; then
  # 2.0 <= DBRelease <= 2.1
  mkdir $VO_ATLAS_SW_DIR/db
  cd $VO_ATLAS_SW_DIR/db
  echo "INSTALLER> Installing $DBRELNAME in $PWD ..."
  pacman $PACMAN_OPTS -get $DBRELCACHE:$DBRELNAME
  lastretcode=$?
  let retcode=$retcode+$lastretcode
  if [ $lastretcode -eq 0 ] ; then
    cd $VO_ATLAS_SW_DIR/software/$VERSION
    echo "source $VO_ATLAS_SW_DIR/db/setup.sh" >> setup.sh
    echo "################### Last 10 lines of $PWD/setup.sh"
    tail setup.sh -n 10
    echo "###################"
  fi
else
  # DBRelease >= 2.2
  if [ "$SITEROOT" != "" ] ; then
    cd $SITEROOT
    echo "INSTALLER> Installing $DBRELNAME in $PWD ..."
    pacman $PACMAN_OPTS -get $DBRELCACHE:$DBRELNAME
    retcode=$?
  else
    echo "INSTALLER> SITEROOT is not set"
    retcode=1
  fi
fi

# Add the tag
if [ $retcode -eq 0 ] ; then
  cd $VO_ATLAS_SW_DIR
  echo "INSTALLER> Running on "/bin/hostname
  echo "INSTALLER> Executing command:"
  echo perl ${LCG_DIR}/lcg-ManageVOTag -host $HOST_CE -vo $experiment --add -tag $TAG
  echo yes | perl ${LCG_DIR}/lcg-ManageVOTag -host $HOST_CE -vo $experiment --add -tag $TAG
  let retcode=$retcode+$?
fi

# End of the task
echo
echo "#########################"
[ "$retcode" -ne 0 ] && echo "INSTALLER> Error during the installation process"
echo "INSTALLER> End of the Task"

exit $retcode
