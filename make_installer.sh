#!/bin/bash

# This script takes the parts from the git repo, combines them with
# downloaded binaries and tars them all up into a tasty treat.

while getopts B:D:P: opt
do
  case "$opt" in
    B)  DEBUG=$OPTARG;;
    D)  DoDataPack=$OPTARG;;
    P)  SrcDataPack=$OPTARG;;
  esac
done

# pgsql_binaries will have been tar'ed up relative to /usr/postgres, so the
# contents are ./opengeo-8.4/*

pkg_name=opengeosuite.tar
staging_dir=/tmp/solarisinst/
pwd=`pwd`

pgsql_binaries="http://data.opengeo.org/solaris/opengeo-pgsql-20120217.tar.gz"
pgsql_smf_script="smf/postgres_og"
pgsql_smf_manifest="smf/postgresql_og.xml.template"
pgsql_installer="scripts/install-opengeo-postgis.sh"

geoserver_war=http://data.opengeo.org/solaris/geoserver.war
geoexplorer_war=http://data.opengeo.org/solaris/geoexplorer.war
dashboard_war=http://data.opengeo.org/solaris/dashboard.war
geoeditor_war=http://data.opengeo.org/solaris/geoeditor.war

geoserver_config=scripts/geoserver.web.xml
geoexplorer_config=scripts/geoexplorer.web.xml

webapps_installer=scripts/install-opengeo-webapps.sh
suite_installer=scripts/install-opengeo-suite.sh

# Set up the staging area
echo "Cleanup staging ..."
if [ -d $staging_dir ]; then
  rm -rf $staging_dir
fi
mkdir $staging_dir
mkdir $staging_dir/resources

# Get the PgSQL binaries
echo "Get PGSQL binaries ..."
wget -O $staging_dir/resources/opengeo-pgsql.tar.gz $pgsql_binaries

# Get the Suite WebApp WARs
echo "Get Suite WebApp WARs ..."
wget -O $staging_dir/resources/geoserver.war $geoserver_war
wget -O $staging_dir/resources/geoexplorer.war $geoexplorer_war

# Copy the text bits into place
echo "Copy text bits into place ..."
cp $pgsql_smf_script $staging_dir/resources
cp $pgsql_smf_manifest $staging_dir/resources
cp $webapps_installer $staging_dir
cp $pgsql_installer $staging_dir

# Copy and then zip template config web.xml files into WARs
# (To keep client/version-specific templates independently of the core WARs)
echo "Copy custom templates into WARs ..."
mkdir $staging_dir/WEB-INF
cp $geoserver_config $staging_dir/WEB-INF/web.xml
pushd $staging_dir && zip -fmrD resources/geoserver.war WEB-INF/web.xml && popd
cp $geoexplorer_config $staging_dir/WEB-INF/web.xml
pushd $staging_dir && zip -fmrD resources/geoexplorer.war WEB-INF/web.xml && popd

if [ -d $staging_dir/WEB-INF ]; then
  rm -R $staging_dir/WEB-INF
fi

if [ "$DoDataPack" == "TRUE" ]; then
  wget -O $staging_dir/datapack.zip $SrcDataPack
  pushd $staging_dir
  zip -d resources/geoserver.war /data/* && unzip datapack.zip && zip -mr resources/geoserver.war data
  rm datapack.zip
  popd
fi

# Pre-Tar Suite WebApps
echo "Pre-Tar'ing Suite WebApps ..."
pushd $staging_dir/resources
tar cvf opengeo-webapps.tar *war 
rm *war
gzip -9 opengeo-webapps.tar

# Tar up the result
echo "Prepping package from artifacts ..."
pushd $staging_dir
tar cvf $pkg_name * 
gzip -9 $pkg_name
mv $pkg_name.gz $pwd

# Done
exit
