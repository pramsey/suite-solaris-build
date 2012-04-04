#!/bin/bash

# TODO (General)
# - rewire source assumptions around consolidated package
# - Action (Eventual hook for the install type: New, Upgrade, Repair, etc.)
# - root-relative path names
# - handle template data packs in standard directory
# -- (in place before war is deployed or packed into WAR)
# - (Re)start Container service/SMF
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

  dSourceDir="$(pwd)/resources"
  dSourcePkg="$dSourceDir/opengeo-webapps.tar.gz"

  dTempDir="/tmp/opengeo-suite-temp"

  dContainer="/glassfish3/glassfish/domains/domain1"
  dTargetDir="$dContainer/autodeploy"

  dJNDIConnRef="jndi/conn/ref/yo"

  dContainerUser="dcuser"

  dIncludeGeoExplorer="FALSE"
  IncludeGeoExplorer=$dIncludeGeoExplorer

# ============================================================
# Script Subroutines
# ============================================================

usage() {
  echo "Usage:"
  echo "  $0 -S /source/to/targz/package/ -T /war/deploy/dir [options]"
  echo ""
  echo "Sample:"
  echo "  $0 -S /tmp/opengeo-webapps.tar.gz -T /glassfish3/glassfish/domains/domain1/autodeploy [Options] ..."
  echo ""
  echo "Required Parameters:"
  echo ""
  echo "  S SourcePkg (required)"
  echo "     Full path to source tarball of the OpenGeo Suite web applications (excluding PostGIS)."
  echo "     Script will fail if the path does not exist."
  echo ""
  echo "  T TargetDir (required)"
  echo "     Full path to the servlet container auto-deploy directory."
  echo "     Script will fail if the path does not exist."
  echo ""
  echo "Options:"
  echo ""
  echo "  I InstallLog (default (pwd)/install-opengeo-suite.log)"
  echo "     Full path to the the log from this installation."
  echo "     Will make the specified file if it does not exist, or append otherwise."
  echo ""
  echo "  M TempDir (default /tmp/opengeo-suite-temp)"
  echo "     Full path to the installation's temporary directory."
  echo "     If the directory can't be created the script will exit."
  echo ""
  echo "  B DebugMode (default FALSE)"
  echo "     If TRUE, it clears contents from any of:"
  echo "     InstallLog, TempDir, GeoExplorerDataDir, GeoServerDataDir, and GeoServerLogDir."
  echo ""
  echo "  X IncludeGeoExplorer (default FALSE)"
  echo "     Deploy GeoExplorer.WAR to the webapps directory."
  echo "     Script will not deploy GeoExplorer unless this is set to 'TRUE'"
  echo ""   
  echo "  E GeoExplorerDataDir (default TargetDir/geoexplorer/data)"
  echo "     Full path to a custom GeoExplorer Data Directory."
  echo "     Script will exit if a custom path is specified but doesn't exist."
  echo ""   
  echo "  G GeoServerDataDir (default TargetDir/geoserver/data)"
  echo "     Full path to a custom GeoServer Data Directory."
  echo "     Script will exit if a custom path is specified but doesn't exist."
  echo ""   
  echo "  L GeoServerLogDir (default TargetDir/geoexplorer/logs)"
  echo "     Full path to a custom GeoServer Log Directory."
  echo "     Script will exit if a custom path is specified but doesn't exist."
  echo ""
  echo "  P TemplateDataPack (default data contents of the GeoServer.WAR)"
  echo "     Full path to a ZIP file containing a preconfigured GeoServer data directory."
  echo "     Script will exit if a custom data pack is specified but doesn't exist."   
  echo ""
  echo "  J JNDIConnRef (default none)"
  echo "     Custom reference to a container-level JNDI connection string."
  echo ""   
  echo "  U ContainerUser (default dcuser)"
  echo "     Username of the user that runs the servlet container process."
  echo "     The script makes this user the owner of any custom log/data dirs."
  echo ""
  echo "  O ContainerGroup (default dcuser)"
  echo "     Groupname of the user that runs the servlet container process."
  echo "     The script makes this group the owner of any custom log/data dirs."
  echo ""
  echo "  C OverwriteExisting (default none)"
  echo "     If we find existing data/binary directories do we over-write them?"
  echo "     APP overwrites binaries / DATA overwrites data / ALL overwrites both."
  echo ""
  echo "  A ScriptAction (default install)"
  echo "     Eventual hook for an installation type (install, upgrade, repair, recover, etc.)"
  echo "     Not used."
  echo ""
  echo "  * Any other option is unexpected, and envokes the Usage Message and Exits the script."
  exit
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

while getopts B:I:S:T:M:E:G:L:P:J:U:O:X:C:A: opt
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
    U)  #echo "  Found the $opt (ContainerUser) option, with value $OPTARG"
        ContainerUser=$OPTARG;;
    O)  #echo "  Found the $opt (ContainerGroup) option, with value $OPTARG"
        ContainerGroup=$OPTARG;;
    X)  #echo "  Found the $opt (IncludeGeoExplorer) option, with value $OPTARG"
        IncludeGeoExplorer=$OPTARG;;
    C)  #echo "  Found the $opt (OverwriteExisting) option, with value $OPTARG"
        OverwriteExisting=$OPTARG;;
    A)  #echo "  Found the $opt (ScriptAction) option, with value $OPTARG"
        ScriptAction=$OPTARG;;
    *) usage;;
  esac
done

echo ""
echo "Preamble ..."

# Check required parameters.
# ============================================================

if [ "x$SourcePkg" == "x" ] || [ "x$TargetDir" == "x" ]; then
  usage
fi

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

if [ -f "$TargetDir/geoserver.war" ] || [ -f "$TargetDir/geoexplorer.war" ]; then
  if [ "$OverwriteExisting" == "ALL" ] || [ "$OverwriteExisting" == "APP" ]; then 
    log "Binaries exist in target directory and overwrite directive (-C) is set to $OverwriteExisting. Overwriting."
  else
    quit "Binaries exist in target directory ($TargetDir) and overwrite directive (-C) not set, or not set to overwrite ($OverwriteExisting)."
  fi
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
  fi
fi

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

# o Container Service User and Group # * Yes, action # * No, use default
# ============================================================

log "** Container User (-U) and Group (-O)"

if [ "x" == "x$ContainerUser" ]; then
  log "Not specified on the commandline ..."
  log "Will use default $dContainerUser."
  ContainerUser=$dContainerUser
else
  log "Found on the commandline ..."
  log "Using the value provided $ContainerUser"
fi

if [ "x" == "x$ContainerGroup" ]; then
  log "Not specified on the commandline ..."
  log "Will use default $dContainerUser."
  ContainerGroup=$dContainerUser
else
  log "Found on the commandline ..."
  log "Using the value provided $ContainerGroup"
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

$GtarPath -xf $SourcePkg -C $TempDir
checkrv $? "$GtarPath -xf $SourcePkg -C $TempDir"

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
  newvalue="<context-param><param-name>GEOSERVER_DATA_DIR<\/param-name><param-value>${GeoServerDataDir//$match/$replace}/geoserver.log<\/param-value><\/context-param>"
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
  newvalue="<context-param><param-name>GEOSERVER_LOG_LOCATION<\/param-name><param-value>${GeoServerLogDir//$match/$replace}<\/param-value><\/context-param>"
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
  if [ ! "x$(ls -A $GeoServerDataDir)" == "x" ]; then
    if [ "$OverwriteExisting" == "ALL" ] || [ "$OverwriteExisting" == "DATA" ]; then 
      log "Data exist in the GeoServer data directory and overwrite directive (-c) is set to $OverwriteExisting. Overwriting."
    else
      quit "Data exists in GeoServer data directory ($TargetDir) and overwrite directive (-C) not set, or not set to overwrite  ($OverwriteExisting)."
    fi
  fi
  # unpack the tempate data file into the data dir
  $UnZipPath -f $TemplateDataPack -d $GeoServerDataDir
  checkrv $? "$UnZipPath $TemplateDataPack -d $GeoServerDataDir"
else
  log "Nothing to do ... Using stock data"  
fi

# Check/Set directory permissions for GFish user 
# [[[]]] TODO - iterate this

log "** Directory Permissions"

# GeoExplorer Data Dir
if [ "$GeoExplorerDataDir" != "0" ]; then
  uid=`ls -al $GeoExplorerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f3 -d' '`
  gid=`ls -al $GeoExplorerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f4 -d' '`
  if [ "$uid" != "$ContainerUser" ] || [ "$gid" != "$ContainerGroup" ]; then
    log "Updating permissions on GeoExplorerDataDir for $ContainerUser:$ContainerGroup"
    chown -hR $ContainerUser:$ContainerGroup $GeoExplorerDataDir
    checkrv $? "chown -hR $ContainerUser:$ContainerGroup $GeoExplorerDataDir"
  else
    log "'$GeoExplorerDataDir' is already owned by '$ContainerUser:$ContainerGroup'"
  fi
fi

# GeoServer Data Dir
if [ "$GeoServerDataDir" != "0" ]; then  
  uid=`ls -al $GeoServerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f3 -d' '`
  gid=`ls -al $GeoServerDataDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f4 -d' '`
  if [ "$uid" != "$ContainerUser" ] || [ "$gid" != "$ContainerGroup" ]; then
    log "Updating permissions on GeoServerDataDir for $ContainerUser:$ContainerGroup"
    chown -hR $ContainerUser:$ContainerGroup $GeoServerDataDir
    checkrv $? "chown -hR $ContainerUser:$ContainerGroup $GeoServerDataDir"
  else
    log "'$GeoServerDataDir' is already owned by '$ContainerUser:$ContainerGroup'"
  fi
fi

# GeoServer Log Dir
if [ "$GeoServerLogDir" != "0" ]; then  
  uid=`ls -al $GeoServerLogDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f3 -d' '`
  gid=`ls -al $GeoServerLogDir | head -n2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f4 -d' '`
  if [ "$uid" != "$ContainerUser" ] || [ "$gid" != "$ContainerGroup" ]; then
    log "Updating permissions on GeoServerLogDir for $ContainerUser:$ContainerGroup"
    chown -hR $ContainerUser:$ContainerGroup $GeoServerLogDir
    checkrv $? "chown -hR $ContainerUser:$ContainerGroup $GeoServerLogDir"
  else
    log "'$GeoServerLogDir' is already owned by '$ContainerUser:$ContainerGroup'"
  fi
fi

log "** Copying processed WARs to WebAppTarget Directory"

#  Deploy GeoExplorer
# o Copy WAR to Target Directory

if [ $IncludeGeoExplorer = "TRUE" ]; then
  cp $TempDir/geoexplorer.war $TargetDir
  checkrv $? "cp $TempDir/geoexplorer.war $TargetDir"
  log "Copied geoexplorer.war to $TargetDir"
else
  log "Geoexplorer.war not copied to $TargetDir. Option set to $IncludeGeoExplorer"
fi

# Deploy GeoServer
# o Copy WAR to Target Directory
cp $TempDir/geoserver.war $TargetDir
checkrv $? "cp $TempDir/geoserver.war $TargetDir"
log "Copied geoserver.war to $TargetDir"

log "** (Re)starting Container domain SMF / service"
# (Re)start Container domain SMF
# Confirm that we need to do this ...?
