#!/bin/bash

# TODO (General)
# - Replace getfacl for storage on ZFS
# - Make log output(s) & terminology consistent
# - Usage
# - Action (Eventual hook for the install type: New, Upgrade, Repair, etc.)
# - root-relative path names
# - handle template data packs in standard directory
# -- (in place before war is deployed or packed into WAR)
# - confirm optional directories exist if options are specified
# - (Re)start Glassfish domain SMF
# - Set container-specific JNDI connection string
# - confirm binary checks

# ============================================================
# Script Options / Defaults
# ============================================================

# Script Options

  GtarPath="/usr/sfw/bin/gtar"
  ZipPath="/usr/bin/zip"
  UnZipPath="/usr/bin/unzip"

  VerboseLogging=1

# Script Defaults

  dInstallLog="$(pwd)/install-opengeo-suite.log"

  dSourceDir="$(pwd)/pkg"
  dSourcePkg="$dSourceDir/opengeo-suite-2.4.3-ee-solaris.tar"

  dTempDir="/tmp/opengeo-suite-temp"

  dGlassfish="/glassfish3/glassfish/domains/domain1"
  dTargetDir="$dGlassfish/autodeploy"

  dJNDIConnRef="jndi/conn/ref/yo"

  dGlassfishUser="ssmith"

# ============================================================
# Script Subroutines
# ============================================================

usage() {
  echo "Usage ..."
  echo ""
}

log() {
  dt=`date +%Y-%m-%d\ %H:%M:%S`
  if [ $VerboseLogging > 0 ]; then
    printf "[%s] %s\n" "$dt" "$1"
  fi
  printf "[%s] %s\n" "$dt" "$1" >> "$InstallLog"
}

quit() {
  log "FATAL: $1"
  exit 1
}

checkrv() {
  rv=$1
  if [ $rv -ne 0 ]; then
    quit "Command $2 failed with exit code $1"
  fi
}

# ============================================================
# Poll commandline arguments
# ============================================================

while getopts B:I:S:T:M:E:G:L:J:U:A: opt
do
  case "$opt" in
    B)  #echo "  Found the $opt (Debug/Testing Mode), with value $OPTARG"
        DebugMode=$OPTARG;;
    I)  #echo "  Found the $opt (InstallLog) option, with value $OPTARG"
        InstallLog=$OPTARG;;
    S)  #echo "  Found the $opt (SourcePkg) option, with value $OPTARG"
        SourcePkg=$OPTARG;;
    T)  #echo "  Found the $opt (TargetDir) option, with value $OPTARG"
        TargetDir=$OPTARG;;
    M)  #echo "  Found the $opt (TempDir) option, with value $OPTARG"
        TempDir=$OPTARG;;
    E)  #echo "  Found the $opt (GeoExplorerDataDir) option, with value $OPTARG"
        GeoExplorerDataDir=$OPTARG;;
    G)  #echo "  Found the $opt (GeoServerDataDir) option, with value $OPTARG"
        GeoServerDataDir=$OPTARG;;
    L)  #echo "  Found the $opt (GeoServerLogDir) option, with value $OPTARG"
        GeoServerLogDir=$OPTARG;;
    P)  #echo "  Found the $opt (TemplateDataPack) option, with value $OPTARG"
        TemplateDataPack=$OPTARG;;
    J)  #echo "  Found the $opt (JNDIConnRef) option, with value $OPTARG"
        JNDIConnRef=$OPTARG;;
    U)  #echo "  Found the $opt (GlassfishUser) option, with value $OPTARG"
        GlassfishUser=$OPTARG;;
    A)  #echo "  Found the $opt (ScriptAction) option, with value $OPTARG"
        ScriptAction=$OPTARG;;
    *)  #echo "Unknown option: $opt, with value $OPTARG"
        usage;;
  esac
done

echo ""
echo "Preamble ..."

# Are we effectively root? Yes, go. No, bail.
# ============================================================

if [ "$(/usr/xpg4/bin/id -u)" != "0" ]; then
   quit "This script must be run as root, exiting ..."
else
   echo "Confirmed that we're effectively running as root ..."
fi

# ============================================================
# Evaluate commandline arguments against script requirements/defaults
# ============================================================

# o Install Log # * Yes, proceed # * No, use default
# ============================================================

# Set default install log location if necessary
if [ "x" == "x$InstallLog" ]; then
  echo "InstallLog (-I) not specified ..."
  echo "Using default log file $dInstallLog"
  InstallLog=$dInstallLog
fi

# Check for existence of logging file location
InstallLogDir=`dirname $InstallLog`
if [ ! -d $InstallLogDir ]; then
  quit "Logging directory $InstallLogDir does not exist, exiting ..."
fi

# Clean up if we're debugging/testing
# ============================================================

if [ "TRUE" == "$DebugMode" ]; then
  echo "DEBUG Deleting $InstallLog"
  rm $InstallLog
  read -p "DEBUG Deleted $InstallLog ???"
  DebugArray=($TempDir $GeoExplorerDataDir $GeoServerDataDir $GeoServerLogDir)
  for i in "${DebugArray[@]}"; do
    if [ -d $i ]; then
      echo "DEBUG Deleting from $i"      
      find $i/* -exec rm -Rf {} ';'
      read -p "DEBUG Deleted $i ???"
    fi 
  done
fi

echo ""

log "================================================"
log "Install started"
log "================================================"
log "** Logging to $InstallLog"
log ""

# Source Pkg # * Yes, proceed # * No, log and bail
# ============================================================

log "** SourcePkg (-S)"

if [ "x" == "x$SourcePkg" ]; then
  log "Not specified on the commandline ..."
  log "Will attempt to use default $dSourcePkg"
  SourcePkg=$dSourcePkg
else
  log "Found on the commandline ..."
  log "Using the value provided $SourcePkg"
fi

if [ ! -f $SourcePkg ]; then
  quit "Source package $SourcePkg does not exist, exiting ..."
else
  log "Found source package $SourcePkg"
fi

# Target Dir # * Yes (exists), proceed # * No, log and bail
# ============================================================

log "** TargetDir (-T)"

if [ "x" == "x$TargetDir" ]; then
  log "Not specified on the commandline ..."
  log "Will attempt to use default $dTargetDir"
  TargetDir=$dTargetDir
else
  log "Found on the commandline ..."
  log "Using the value provided $TargetDir"
fi

if [ ! -d $TargetDir ]; then
  quit "Target directory $TargetDir does not exist, exiting ..."
else
  log "Found target directory $TargetDir"
fi

# o Temp directory for unpacking
# ============================================================

log "** TempDir (-M)"

if [ "x" == "x$TempDir" ]; then
  log "Not specified on the commandline ..."
  log "Will attempt to use default $dTempDir"
  TempDir="$dTempDir"
else
  log "Found on the commandline ..."
  log "Using the value provided $TempDir"
  TempDir="$TempDir"
fi

if [ ! -d $TempDir ]; then
  log "$TempDir does not exist, trying mkdir ..."
  mkdir $TempDir
  checkrv $? "mkdir $TempDir"
else
  log "Found and/or created $TempDir"
fi

# o GeoExplorer Data Dir # * Yes, proceed # * No, use default
# ============================================================

log "** GeoExplorerDataDir (-E)"

if [ "x" == "x$GeoExplorerDataDir" ]; then
  log "Not specified on the commandline ..."
  log "Will use app default data directory"
  GeoExplorerDataDir=0
else
  log "Found on the commandline ..."
  log "Will use the value provided $GeoExplorerDataDir"
  if [ ! -d $GeoExplorerDataDir ]; then
    quit "GeoExplorerDataDir directory $GeoExplorerDataDir does not exist, exiting ..."
  else
    log "Found GeoExplorerDataDir directory $GeoExplorerDataDir, proceeding ..."
  fi
fi

# o GeoServer Data Dir # * Yes, proceed # * No, use default
# ============================================================

log "** GeoServerDataDir (-G)"

if [ "x" == "x$GeoServerDataDir" ]; then
  log "Not specified on the commandline ..."
  log "Will use app default data directory"
  GeoServerDataDir=0
else
  log "Found on the commandline ..."
  log "Will use the value provided $GeoServerDataDir"
  if [ ! -d $GeoServerDataDir ]; then
    quit "GeoServerDataDir directory $GeoServerDataDir does not exist, exiting ..."
  else
    log "Found GeoServerDataDir directory $GeoServerDataDir, proceeding ..."
  fi
fi

# o GeoServer Log Dir # * Yes, proceed # * No, use default
# ============================================================

log "** GeoServerLogDir (-L)"

if [ "x" == "x$GeoServerLogDir" ]; then
  log "Not specified on the commandline ..."
  log "Will use app default log directory"
  GeoServerLogDir=0
else
  log "Found on the commandline ..."
  log "Will use the value provided $GeoServerLogDir"
  if [ ! -d $GeoServerLogDir ]; then
    quit "GeoServerLogDir directory $GeoServerLogDir does not exist, exiting ..."
  else
    log "Found GeoServerLogDir directory $GeoServerLogDir, proceeding ..."
  fifi

# o TemplateDataPack # * Yes, action # * No, do nothing
# ============================================================

log "** TemplateDataPack (-P)"

if [ "x" == "x$TemplateDataPack" ]; then
  log "Not specified on the command line ..."
  log "Will not use TemplateDataPack"
  TemplateDataPack=0
else
  log "Found on the commandline ..."
  log "Using the value provided $TemplateDataPack"
  if [ ! -f $TemplateDataPack ]; then
    quit "TemplateDataPack $TemplateDataPack was specified but does not exist, exiting ..."
  else
    log "Found TemplateDataPack file $TemplateDataPack, proceeding ..."
  fi
fi

# o JNDI Connection Reference # * Yes, action # * No, do nothing
# ============================================================

log "** JNDIConnRef (-J)"

if [ "x" == "x$JNDIConnRef" ]; then
  log "Not specified on the command line ..."
  log "Will not set JNDIConnRef"
  JNDIConnRef=0
else
  log "Found on the commandline ..."
  log "Using the value provided $JNDIConnRef"
fi

# o Glassfish Service User # * Yes, action # * No, use default
# ============================================================

log "** Glassfish User (-U)"

if [ "x" == "x$GlassfishUser" ]; then
  log "Not specified on the commandline ..."
  log "Will use default $dGlassfishUser."
  GlassfishUser=$dGlassfishUser
else
  log "Found on the commandline ..."
  log "Using the value provided $GlassfishUser"
fi

# ============================================================
# Actions
# ============================================================

# Untar the software into the temp location
log "** Untar'ing Suite installation package into temp dir"

if [ ! -x $GtarPath ]; then
  quit "Cannot find $GtarPath to unpack archive"
else
  log "Found Gtar where we expected it $GtarPath"
fi

$GtarPath xf $SourcePkg -C $TempDir
checkrv $? "$GtarPath xf $SourcePkg -C $TempDir"

# Unzipping WAR files that need updating with custom params

if [ ! -x $UnZipPath ] || [ ! -x $ZipPath ]; then
  quit "Cannot find $Zip or $UnZipPath to pack/unpack WAR files"
else
  log "Found Zip/UnZip where we expected it ($ZipPath & $UnZipPath)"
fi

match="/"
replace="\/"

log "** Custom GeoExplorerDataDir"
if [ $GeoExplorerDataDir == 0 ]; then
  log "Nothing to do ... Using default GeoExplorerDataDir."
else
  log "Unpacking GeoExplorer WAR for custom configs"  
  $UnZipPath $TempDir/geoexplorer.war WEB-INF/web.xml -d $TempDir/geoexplorer/
  checkrv $? "unzip $TempDir/geoexplorer.war /WEB-INF/web.xml -d $TempDir/geoexplorer/"
  oldvalue="<!--CustomGeoExplorerDataDir-->" 
  newvalue="<init-param><param-name>GEOEXPLORER_DATA<\/param-name><param-value>${GeoExplorerDataDir//$match/$replace}<\/param-value><\/init-param>"
  log "Writing custom GeoExplorer DataDir to template configuration file"
  log "($newvalue)"
  sedfile=$TempDir/geoexplorer/WEB-INF/web.xml
  sedtemp=$TempDir/geoexplorer/WEB-INF/web.xml.tmp
  sed s/$oldvalue/$newvalue/g $sedfile > $sedtemp && mv $sedtemp $sedfile 
  checkrv $? "sed s/$oldvalue/$newvalue/g $sedfile > $sedtemp && mv $sedtemp $sedfile"
  pushd $TempDir/geoexplorer
  $ZipPath -fmrD ../geoexplorer.war WEB-INF/web.xml
  checkrv $? "$ZipPath -fmrD ../geoexplorer.war WEB-INF/web.xml"
  popd
fi

log "** Custom GeoServer Log and/or Data Dir"

# if we need to do some GeoServer param customizations, upack the WAR
if [ ! $GeoServerDataDir == 0 ] || [ ! $GeoServerLogDir == 0 ]; then
  log "Unpacking GeoServer WAR for custom configs"
  $UnZipPath $TempDir/geoserver.war WEB-INF/web.xml -d $TempDir/geoserver/
  checkrv $? "$UnZipPath $TempDir/geoserver.war WEB-INF/web.xml -d $TempDir/geoserver/"
else
  log "Not unpacking GeoServer WAR - No custom configs"
fi

# custom GeoServer DataDir?
if [ $GeoServerDataDir == 0 ]; then
  log "Nothing to do ... Using default GeoServerDataDir."
else
  oldvalue="<!--CustomGeoServerDataDir-->"
  newvalue="<context-param><param-name>GEOSERVER_DATA_DIR<\/param-name><param-value>${GeoServerDataDir//$match/$replace}<\/param-value><\/context-param>"
  log "Writing custom GeoServer DataDir to template configuration file"
  log "($newvalue)"
  sedfile=$TempDir/geoserver/WEB-INF/web.xml
  sedtemp=$TempDir/geoserver/WEB-INF/web.xml.tmp
  sed s/$oldvalue/$newvalue/g $sedfile > $sedtemp && mv $sedtemp $sedfile 
  checkrv $? "sed s/$oldvalue/$newvalue/g $sedfile > $sedtemp && mv $sedtemp $sedfile"
fi

# custom GeoServerLogDir?
if [ $GeoServerLogDir == 0 ]; then
  log "Nothing to do ... Using default GeoServerLogDir."
else
  oldvalue="<!--CustomGeoServerLogDir-->"
  newvalue="<context-param><param-name>GEOSERVER_LOG_DIR<\/param-name><param-value>${GeoServerLogDir//$match/$replace}<\/param-value><\/context-param>"
  log "Writing custom GeoServer LogDir to template configuration file"
  log "($newvalue)"
  sedfile=$TempDir/geoserver/WEB-INF/web.xml
  sedtemp=$TempDir/geoserver/WEB-INF/web.xml.tmp
  sed s/$oldvalue/$newvalue/g $sedfile > $sedtemp && mv $sedtemp $sedfile 
  checkrv $? "sed s/$oldvalue/$newvalue/g $sedfile > $sedtemp && mv $sedtemp $sedfile"
fi

# if we did something here, repack the WAR
if [ ! $GeoServerDataDir == 0 ] || [ ! $GeoServerLogDir == 0 ]; then
  log "Repacking GeoServer WAR with custom configurations"
  pushd $TempDir/geoserver
  $ZipPath -fmrD ../geoserver.war WEB-INF/web.xml
  checkrv $? "$ZipPath -fmrD ../geoserver.war WEB-INF/web.xml"
  popd
else
  log "Not repacking geoserver WAR - No custom configs"
fi

# Copy TemplateDataPack into Live Data Dir
# (we already confirmed/made the data dir)

log "** Custom Template Data Pack"
if [ ! $TemplateDataPack == 0 ]; then
  log "Importing TemplateDataPack"
  # sfs unpack the tempate data file into the data dir
  $UnZipPath $TemplateDataPack -d $GeoServerDataDir
  checkrv $? "$UnZipPath $TemplateDataPack -d $GeoServerDataDir"
  read -p "DataUnzipSFS"
else
  log "Nothing to do ... Using stock data"  
fi

# Check/Set directory permissions for GFish user 
# [[[]]] TODO iterate this ???

# GeoExplorer Data Dir
if [ "$GeoExplorerDataDir" != "0" ]; then
  uid=`ls -al $GeoExplorerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f3 -d' '`
  gid=`ls -al $GeoExplorerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f4 -d' '`
  if [ "$uid" != "$GlassfishUser" ] || [ "$gid" != "$GlassfishUser" ]; then
    log "Setting permissions on GeoExplorerDataDir"
    chown -hR $GlassfishUser:$GlassfishUser $GeoExplorerDataDir
    checkrv $? "chown -hR $GlassfishUser:$GlassfishUser $GeoExplorerDataDir"
  else
    log "'$GeoExplorerDataDir' is owned by '$GlassfishUser$GlassfishUser'"
  fi
fi

# GeoServer Data Dir
if [ "$GeoServerDataDir" != "0" ]; then  
  uid=`ls -al $GeoServerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f3 -d' '`
  gid=`ls -al $GeoServerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f4 -d' '`
  if [ "$uid" != "$GlassfishUser" ] || [ "$gid" != "$GlassfishUser" ]; then
    log "Setting permissions on GeoServerDataDir"
    chown -hR $GlassfishUser:$GlassfishUser $GeoServerDataDir
    checkrv $? "chown -hR $GlassfishUser:$GlassfishUser $GeoServerDataDir"
  else
    log "'$GeoServerDataDir' is owned by '$GlassfishUser:$GlassfishUser'"
  fi
fi

# GeoServer Log Dir
if [ "$GeoServerLogDir" != "0" ]; then  
  uid=`ls -al $GeoServerLogDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f3 -d' '`
  gid=`ls -al $GeoServerLogDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f4 -d' '`
  if [ "$uid" != "$GlassfishUser" ] || [ "$gid" != "$GlassfishUser" ]; then
    log "Setting permissions on GeoServerLogDir"
    chown -hR $GlassfishUser:$GlassfishUser $GeoServerLogDir
    checkrv $? "chown -hR $GlassfishUser:$GlassfishUser $GeoServerLogDir"
  else
    log "'$GeoServerLogDir' is owned by '$GlassfishUser:$GlassfishUser'"
  fi
fi

#  Deploy GeoExplorer
# o Copy WAR to Target Directory
cp $TempDir/geoexplorer.war $TargetDir
checkrv $? "cp $TempDir/geoexplorer.war $TargetDir"

# Deploy GeoServer
# o Copy WAR to Target Directory
cp $TempDir/geoserver.war $TargetDir
checkrv $? "cp $TempDir/geoserver.war $TargetDir"

# (Re)start Glassfish domain SMF
# Confirm that we need to do this ...?
