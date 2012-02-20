#!/bin/bash

# This script takes the parts from the git repo, combines them with
# downloaded binaries and tars them all up into a tasty treat.

# pgsql_binaries will have been tar'ed up relative to /usr/postgres, so the
# contents are ./opengeo-8.4/*

pkg_name=opengeosuite.tar
staging_dir=/tmp/solarisinst/
pwd=`pwd`

pgsql_binaries=http://data.opengeo.org/solaris/opengeo-pgsql-20110217.tar.gz
pgsql_smf_script=smf/postgres_og
pgsql_smf_manifest=smf/postgresql_og.xml.template
pgsql_installer=scripts/install-opengeo-postgis.sh

geoserver_war=http://dl.dropbox.com/u/1934092/suite-2.4.3-solaris/geoserver.war
geoexplorer_war=http://dl.dropbox.com/u/1934092/suite-2.4.3-solaris/geoexplorer.war
dashboard_war=http://dl.dropbox.com/u/1934092/suite-2.4.3-solaris/dashboard.war
geoeditor_war=http://dl.dropbox.com/u/1934092/suite-2.4.3-solaris/geoeditor.war

geoserver_config=scripts/geoserver.web.xml
geoexplorer_config=scripts/geoexplorer.web.xml

webapps_installer=scripts/install-opengeo-webapps.sh
suite_installer=scripts/install-opengeo-suite.sh

# Set up the staging area
if [ -d $staging_dir ]; then
  rm -rf $staging_dir
fi
mkdir $staging_dir
mkdir $staging_dir/resources

# Get the PgSQL binaries
curl $pgsql_binaries > $staging_dir/resources/opengeo-pgsql.tar.gz

# Copy the text bits into place
cp -v $pgsql_smf_script $staging_dir/resources
cp -v $pgsql_smf_manifest $staging_dir/resources
cp -v $pgsql_smf_installer $staging_dir

# Get the Suite WebApp WARs
curl $geoserver_war > $staging_dir/resources/geoserver.war
curl $geoexplorer_war > $staging_dir/resources/geoexplorer.war
curl $dashboard_war > $staging_dir/resources/dashboard.war
curl $geoeditor_war > $staging_dir/resources/geoeditor.war

read -p "WARs down?"

# Copy and then zip template config web.xml files into WARs
# (To keep client/version-specific templates independently of the core WARs)
mkdir $staging_dir/WEB-INF
cp -v $geoserver_config > $staging_dir/WEB-INF/web.xml
pushd $staging_dir && zip -fmrD ../resources/geoserver.war WEB-INF/web.xml && popd
cp -v $explorer_config > $staging_dir/WEB-INF/web.xml
pushd $staging_dir && zip -fmrD ../resources/geoexplorer.war WEB-INF/web.xml && popd

### UNSAFE ??? ###
rm -R $staging_dir/WEB-INF
### UNSAFE ??? ###

read -p "WARS updated and WEB-INF gone?"

# Tar up the result
pushd $staging_dir
tar cvf $pkg_name * 
gzip -9 $pkg_name
mv -v $pkg_name.gz $pwd

# Done
exit
