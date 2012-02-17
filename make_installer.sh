#!/bin/bash

# This script takes the parts from the git repo, combines them with
# downloaded binarieas and tars them all up into a tasty treat.

# pgsql_binaries will have been tar'ed up relative to /usr/postgres, so the
# contents are ./opengeo-8.4/*

pkg_name=opengeosuite.tar
staging_dir=/tmp/solarisinst/
pwd=`pwd`

pgsql_binaries=http://data.opengeo.org/solaris/opengeo-pgsql-20110203.tar.gz
pgsql_smf_script=smf/postgres_og
pgsql_smf_manifest=smf/postgresql_og.xml.template
pgsql_installer=scripts/install-opengeo-postgis.sh

#geoserver_binaries=http://data.opengeo.org/solaris/geoserver-something.war
# sfsmith to do

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

# Get the GeoServer binaries
#curl $

# Tar up the result
pushd $staging_dir
tar cvf $pkg_name * 
gzip -9 $pkg_name
mv -v $pkg_name.gz $pwd

# Done
exit
