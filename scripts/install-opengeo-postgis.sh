#!/bin/bash

verbose=1
pg_version=opengeo-8.4

installer_dir=`dirname $0`
resources_dir="$installer_dir/resources"
pkg="$resources_dir/opengeo-pgsql.tar.gz"

id=`id | grep id=0`

gtar=/usr/sfw/bin/gtar

usage() {
  echo "usage: $0 -I /install/path -D /db/path [-L /install/log/file] [-C APP|ALL]"
  echo ""
  echo "   Standard Solaris install location is /usr/postgres and db location"
  echo "   is /var/postgres. Recommended install command:"
  echo ""
  echo "      $0 -I /usr/postgres -D /var/postgres"
  echo ""
}

log() {
  dt=`date +%Y-%m-%d\ %H:%M:%S`
  if [ $verbose -gt 0 ]; then
    printf "[%s] %s\n" "$dt" "$1"
  fi
  printf "[%s] %s\n" "$dt" "$1" >> $log_file
}

quit() {
  log "FATAL: $1"
  exit 1
}

checkrv() {
  rv=$1
  if [ $rv -ne 0 ]; then
    quit $2 failed with exit code $1
  fi
}

# Check commandline parameters
while getopts I:D:L:C: opt
do
  case "$opt" in 
    I) install_path=$OPTARG;;
    D) db_path=$OPTARG;;
    L) log_file=$OPTARG;;
    C) overwrite=$OPTARG;;
    *) usage;;
  esac
done

# Check that the overwrite parameter uses the correct arguments if
# it is being used at all
if [ -n $overwrite ]; then
  if [ "ALL" != $overwrite ] && [ "APP" != $overwrite ]; then
     usage
     exit 1
  fi
fi

if [ ! -n "$install_path" ] || [ ! -n "$db_path" ]; then
  usage
  exit 1
fi

# Set default install log location if necessary
if [ "x" == "x$log_file" ]; then
  log_file="./install.log"
fi

# Have to run as root
if [ "x" == "x$id" ]; then
  quit "$0 must be run as root"
fi

# Check for existence of logging file location
log_dir=`dirname $log_file`
if [ ! -d $log_dir ]; then
  quit "Logging directory $log_dir does not exist"
fi

log "------------------------------------------"
log "Install started, logging to $log_file"

# Check for existence of software package
if [ ! -f $pkg ]; then
  quit "Software bundle $pkg is missing"
else
  log "Found software bundle $pkg"
fi

# Check for existence of install location
if [ ! -d $install_path ]; then
  quit "Install directory $install_path does not exist"
else
  log "Found install directory $install_path"
fi

# Check for existence of database location
if [ ! -d $db_path ]; then
  quit "Database directory $db_path does not exist"
else
  log "Found data directory $db_path"
fi

# Check for absolute paths
ginst=`echo $install_path | grep "^/"`
gdb=`echo $db_path | grep "^/"`
if [ "x" == "x$ginst" ]; then
  quit "Install path must be absolute (starts with /) not relative"
fi
if [ "x" == "x$gdb" ]; then
  quit "Data path must be absolute (starts with /) not relative"
fi

# Check for existence of the postgres user
pguser=`cat /etc/passwd | grep postgres`
if [ "x" == "x$pguser" ]; then
  quit "Database user 'postgres' does not exist. Please create the user and try again"
else
  log "Confirmed existence of 'postgres' user"
fi

# Calculate shared memory availability
shmax_size=`prctl -n project.max-shm-memory $$ | grep priv | perl -pe 's/.* (\d+)\w+ .*/$1/'`
shmax_units=`prctl -n project.max-shm-memory $$ | grep priv | perl -pe 's/.* \d+(\w+) .*/$1/'`
log "Found total shared memory of about $shmax_size$shmax_units"

# calculate 75% of size
shmax=`expr $shmax_size \* 3 / 4`
shared_buffer="$shmax$shmax_units"
log "Using $shared_buffer as shared_buffer size for PostgreSQL"

# Check suitability of the data directory
#gid=`getfacl $db_path | grep group | cut -f2 -d: | tr -d ' '`
uid=`ls -al $db_path | head -2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f3 -d' ' | tr -d '\n'`
gid=`ls -al $db_path | head -2 | tail +1 | sed -e 's/[ ][ ]*/ /g' | cut -f4 -d' ' | tr -d '\n'`
if [ "$uid" != "postgres" ] || [ "$gid" != "postgres" ]; then
  quit "Database directory '$db_path' must be owned by 'postgres' user and group. Run this command: chown postgres:postgres $db_path"
else
  log "Checking that '$db_path' is owned by 'postgres:postgres'"
fi

# Untar the software into the destination location
if [ ! -x $gtar ]; then
  quit "Cannot find $gtar to unpack archive"
fi
if [ -d "$install_path/$pg_version" ]; then
  if [ $overwrite == "APP" ] || [ $overwrite == "ALL" ]; then
    log "Removing existing software from $install_path/$pg_version "
    /bin/rm -rf "$install_path/$pg_version"
    checkrv $? "/bin/rm -rf $install_path/$pg_version"
  else
    quit "There is already software installed at $install_path/$pg_version"
  fi
fi
# Untar the software
log "Untaring $pkg to $install_path"
$gtar -xf $pkg -C $install_path 
checkrv $? "$gtar -xf $pkg -C $install_path"
# Set the ownership to system users
log "Setting ownership of $install_path/$pg_version to root:bin"
chown -R root:bin $install_path/$pg_version
checkrv $? "chown -R root:bin $install_path/$pg_version"

# Install the SMF start script
svc_name=postgresql_og
svc_script_name=postgres_og
svc_script_loc=/lib/svc/method/$svc_script_name
svc_script_template=$resources_dir/$svc_script_name
svc_manifest_xml=${svc_name}.xml
svc_manifest_loc=/var/svc/manifest/application/database/$svc_manifest_xml
svc_manifest_template=$resources_dir/${svc_manifest_xml}.template
bin_path=$install_path/$pg_version/bin/64
data_path=$db_path/$pg_version

if [ -d "$data_path" ] && [ $overwrite == "ALL" ]; then
  log "Overwriting data directory $data_path"
  /bin/rm -rf "$data_path"
  checkrv $? "/bin/rm -rf $data_path"
fi
if [ ! -f $svc_script_template ]; then
  quit "Cannot find SMF start script template '$svc_script_template'"
else
  log "Found SMF script template '$svc_script_template'"
fi
if [ ! -f $svc_manifest_template ]; then
  quit "Cannot find SMF manifest template '$svc_manifest_template'"
else
  log "Found SMF manifest template '$svc_manifest_template'"
fi

# Copy start script into place
/bin/cp -f $svc_script_template $svc_script_loc
checkrv $? "cp $svc_script_template $svc_script_loc"
log "Installed $svc_script_loc"

# Write data and bin locations into the manifest file
sed s,@bin@,$bin_path, $svc_manifest_template | \
  sed s,@data@,$data_path, > \
  $svc_manifest_loc
log "Installed ${svc_manifest_loc}"

# Add the install library locations to the system library path
/usr/bin/crle -u -l $install_path/$pg_version/lib
/usr/bin/crle -64 -u -l $install_path/$pg_version/lib/64

# Log results out
log "PostgreSQL/PostGIS installed"
log "Binaries in $install_path/$pg_version"
log "Database in $db_path/$pg_version"
log "Installation complete, to enable the PostgreSQL service, run:"
log ""
log "   /usr/sbin/svccfg import ${svc_manifest_loc}"
log "   /usr/sbin/svcadm enable ${svc_name}:default"
log ""
log "Done"

exit 0

