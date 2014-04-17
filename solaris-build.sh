#!/bin/bash
#
# This script is for building out the binaries of the Suite needed
# for the further packaging scripts in this repository.
#

###############################################################
# Install Solaris

# Add non-root user
  useradd -d /export/home/user -k /etc/skel -m user

# For user, edit .profile and .cshrc
# Add 'gcc' to path
  export PATH=${PATH}:/usr/sfw/bin
  
# Add 'ar' to path
  export PATH=${PATH}:/usr/ccs/bin

# Alias for gmake to make
  cd /usr/swf/bin
  ln -s gmake make

# Add install location
  mkdir /usr/postgres/opengeo-8.4
  chown user:other /usr/postgres/opengeo-8.4

###############################################################
# Build readline
  wget ftp://ftp.sunfreeware.com/pub/freeware/SOURCES/readline-5.2.tar.gz

  # 32 bit
  CC="gcc" ./configure --prefix=/usr/postgres/opengeo-8.4
  make clean all
  make install

  # 64 bit
  CC="gcc -m64" ./configure \
    --libdir=/usr/postgres/opengeo-8.4/lib/64 \
    --infodir=/usr/postgres/opengeo-8.4/info/ \
    --mandir=/usr/postgres/opengeo-8.4/man/ \
    --includedir=/usr/postgres/opengeo-8.4/include/64
    
  make clean all
  make install

###############################################################
# Build PROJ
  wget http://download.osgeo.org/proj/proj-4.7.0.tar.gz
  wget http://download.osgeo.org/proj/proj-datumgrid-1.5.zip

  CC="gcc" ./configure --prefix=/usr/postgres/opengeo-8.4
  make clean all
  make install

  CC="gcc -m64" ./configure \
    --prefix=/usr/postgres/opengeo-8.4 \
    --libdir=/usr/postgres/opengeo-8.4/lib/64 \
    --includedir=/usr/postgres/opengeo-8.4/include/64 \
    --bindir=/usr/postgres/opengeo-8.4/bin/64 

  make clean all
  make install


###############################################################
# Build GEOS
  wget http://download.osgeo.org/geos/geos-3.3.1.tar.bz2

  CC="gcc" CXX="g++" ./configure --prefix=/usr/postgres/opengeo-8.4
  make clean all
  make DESTDIR=/export/home/pramsey/Build/ install
    
  CC="gcc -m64" CXX="g++ -m64" ./configure \
    --prefix=/usr/postgres/opengeo-8.4 \
    --libdir=/usr/postgres/opengeo-8.4/lib/64 \
    --bindir=/usr/postgres/opengeo-8.4/bin/64 \
    --includedir=/usr/postgres/opengeo-8.4/include/64 
  make clean all
  make install


###############################################################
# Make libreadline.so visible systemwide or the PostgreSQL
# configure will fail to find it. 
# for 32-bit
# cd /usr/lib
# ln -s /usr/postgres/opengeo-8.4/lib/libreadline.so.5 libreadline.so.5
# ln -s /usr/postgres/opengeo-8.4/lib/libreadline.so.5 libreadline.so

# for 64-bit
# cd /usr/lib/64
# ln -s /usr/postgres/opengeo-8.4/lib/64/libreadline.so.5 libreadline.so.5
# ln -s /usr/postgres/opengeo-8.4/lib/64/libreadline.so.5 libreadline.so


###############################################################
# Add readline to environment
  export LD_LIBRARY_PATH_32=/usr/postgres/opengeo-8.6/lib
  export LD_LIBRARY_PATH_64=/usr/postgres/opengeo-8.6/lib/64

###############################################################
# Build PostgreSQL (32)
  CC="gcc" CXX="g++" ./configure \
    --prefix=/usr/postgres/opengeo-8.4 \
    --with-system-tzdata=/usr/share/lib/zoneinfo \
    --localstatedir=/var/postgres/opengeo-8.4 \
    --sharedstatedir=/var/postgres/opengeo-8.4 \
    --with-pam \
    --with-openssl \
    --with-libxml \
    --with-libxslt \
    --enable-nls \
    --with-includes="/usr/sfw/include /usr/postgres/opengeo-8.4/include" \
    --with-libraries="/usr/sfw/lib /usr/postgres/opengeo-8.4/lib" 

  make clean all
  make install
  cd contrib
  make clean all
  make install

###############################################################
# Build PostgreSQL (64)
  CC="gcc -m64" CXX="g++ -m64" ./configure \
    --prefix=/usr/postgres/opengeo-8.4 \
    --exec-prefix=/usr/postgres/opengeo-8.4 \
    --bindir=/usr/postgres/opengeo-8.4/bin/64 \
    --libexecdir=/usr/postgres/opengeo-8.4/bin/64 \
    --sbindir=/usr/postgres/opengeo-8.4/bin/64 \
    --datadir=/usr/postgres/opengeo-8.4/share \
    --sysconfdir=/usr/postgres/opengeo-8.4/etc \
    --mandir=/usr/postgres/opengeo-8.4/man \
    --libdir=/usr/postgres/opengeo-8.4/lib/64 \
    --includedir=/usr/postgres/opengeo-8.4/include/64 \
    --with-docdir=/usr/postgres/opengeo-8.4/doc \
    --sharedstatedir=/var/postgres/opengeo-8.4 \
    --localstatedir=/var/postgres/opengeo-8.4 \
    --with-system-tzdata=/usr/share/lib/zoneinfo \
    --with-pam \
    --with-openssl \
    --with-libxml \
    --with-libxslt \
    --enable-nls \
    --with-includes="/usr/sfw/include /usr/postgres/opengeo-8.4/include/64" \
    --with-libraries="/usr/sfw/lib/64 /usr/postgres/opengeo-8.4/lib/64" 

    make clean all
    make install
    cd contrib
    make clean all
    make install

###############################################################
# Build PostGIS (64)
  wget http://postgis.refractions.net/download/postgis-1.5.3.tar.gz
  CC="gcc -m64" CXX="g++ -m64" ./configure \
    --with-pgconfig=/usr/postgres/opengeo-8.4/bin/64/pg_config \
    --with-geosconfig=/usr/postgres/opengeo-8.4/bin/64/geos-config \
    --with-projdir=/usr/postgres/opengeo-8.4 \
    --with-xml2config=/usr/bin/xml2-config 

    make clean all
    make install
  
###############################################################
# Build PostGIS (32)
  wget http://postgis.refractions.net/download/postgis-1.5.3.tar.gz
  CC="gcc" CXX="g++" ./configure \
    --with-pgconfig=/usr/postgres/opengeo-8.4/bin/pg_config \
    --with-geosconfig=/usr/postgres/opengeo-8.4/bin/geos-config \
    --with-projdir=/usr/postgres/opengeo-8.4 \
    --with-xml2config=/usr/bin/xml2-config 

    make clean all
    make install

###############################################################
# Reset RPATH to $ORIGIN/../../lib/64 to allow relocation of
# binaries

# Get rpath
wget http://blogs.sun.com/ali/resource/rpath.tgz

# 32 bit lib
find /usr/postgres/opengeo-8.4/bin -type f -exec ./rpath {} /lib:/usr/lib:/usr/sfw/lib:\$ORIGIN/../lib ';'

# 32 bit bin
find /usr/postgres/opengeo-8.4/lib -type f -exec ./rpath {} /lib:/usr/lib:/usr/sfw/lib:\$ORIGIN/../lib ';'

# 64 bit lib
find /usr/postgres/opengeo-8.4/lib/64 -type f -exec ./rpath {} /lib/64:/usr/lib/64:/usr/sfw/lib/64:\$ORIGIN/../../lib/64 ';'

# 64 bit bin
find /usr/postgres/opengeo-8.4/bin/64 -type f -exec ./rpath {} /lib/64:/usr/lib/64:/usr/sfw/lib/64:\$ORIGIN/../../lib/64 ';'



###############################################################
# Initialization

cd /usr/postgres/opengeo-8.4/etc/smf
Copy postgres_og84 to /lib/svc/method
Copy postgresql_og84.xml to /var/svn/manifest/application/database
cd /var/svn/manifest/application/database
/usr/sbin/svccfg import postgresql_og84.xml
svcs postgresql_og84
/usr/sbin/svcadm enable postgresql_og84:default_64bit

###############################################################
# Template PostGIS

add /usr/postgres/opengeo-8.4/bin/64 to your PATH
createdb -U postgres template_postgis
createlang -U postgres -d template_postgis plpgsql
psql -U postgres -f /usr/postgres/opengeo-8.4/share/contrib/postgis-1.5/postgis.sql -d template_postgis
psql -U postgres -f /usr/postgres/opengeo-8.4/share/contrib/postgis-1.5/spatial_ref_sys.sql -d template_postgis
psql -U postgres -d template_postgis -c "update pg_database set datistemplate = true where datname = 'template_postgis'"

###############################################################
# Install Script Notes


# Check kernel parameters
prctl -i project user.postgres
if $? != 0 then we need to add a user.postgres project

# Read shmmax size
prctl -n project.max-shm-memory $$ | grep priv | perl -pe 's/.* (\d+)\w+ .*/$1/'
# Read shmmax units
prctl -n project.max-shm-memory $$ | grep priv | perl -pe 's/.* \d+(\w+) .*/$1/'
# calculate 75% of size
expr $a * 4 / 3

install-opengeo-postgis \
/binary/install/path \
/database/path /
[/install/log/path]

# where to put the binaries?
# where to put the database instance files?
# where to put the install log?



if [ $curl -eq 1 ]; then

# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
cd curl-7.23.1
CC="gcc" CXX="g++" ./configure \
   --prefix=$PREFIX \
  && make clean all install
cd ..

# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
cd curl-7.23.1
CC="gcc -m64" CXX="g++ -m64" ./configure \
   --prefix=$PREFIX \
   --exec-prefix=$PREFIX \
   --bindir=$PREFIX/bin/64 \
   --libexecdir=$PREFIX/bin/64 \
   --sbindir=$PREFIX/bin/64 \
   --datadir=$PREFIX/share \
   --includedir=$PREFIX/include/64  \
   --sysconfdir=$PREFIX/etc \
   --mandir=$PREFIX/man \
   --libdir=$PREFIX/lib/64 \
  && make clean all install
cd ..

fi

#########################################################################
# Proj
#

if [ $proj -eq 1 ]; then

# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
cd proj-${proj_version}
CC="gcc" ./configure --prefix=$PREFIX \
&& make clean all \
&& make install
cd ..

# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
cd proj-${proj_version}
CC="gcc -m64" ./configure \
  --prefix=$PREFIX \
  --libdir=$PREFIX/lib/64 \
  --includedir=$PREFIX/include/64 \
  --bindir=$PREFIX/bin/64 \
&& make clean all \
&& make install
cd ..

fi

#########################################################################
# GEOS
#

if [ $geos -eq 1 ]; then

# 32 BIT
cd geos-${geos_version}
export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc" CXX="g++" ./configure --prefix=$PREFIX \
&& make clean all \
&& make install
cd ..
    
# 64 BIT
cd geos-${geos_version}
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" CXX="g++ -m64" ./configure \
  --prefix=$PREFIX \
  --libdir=$PREFIX/lib/64 \
  --bindir=$PREFIX/bin/64 \
  --includedir=$PREFIX/include/64 \
&& make clean all \
&& make install
cd ..

fi



#########################################################################
# PostgreSQL
#

if [ $pgsql -eq 1 ]; then

export LD_LIBRARY_PATH_32=/usr/postgres/opengeo-8.4/lib
export LD_LIBRARY_PATH_64=/usr/postgres/opengeo-8.4/lib/64

# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
cd postgresql-${pgsql_version}
  CC="gcc" CXX="g++" ./configure \
    --prefix=$PREFIX \
    --with-system-tzdata=/usr/share/lib/zoneinfo \
    --localstatedir=/var/postgres/opengeo-8.4 \
    --sharedstatedir=/var/postgres/opengeo-8.4 \
    --with-pam \
    --with-openssl \
    --with-libxml \
    --with-libxslt \
    --enable-nls \
    --with-includes="/usr/sfw/include $PREFIX/include" \
    --with-libraries="/usr/sfw/lib $PREFIX/lib" 

  make clean all \
  && make install \
  && cd contrib \
  && make clean all \
  && make install \
  && cd ..
cd ..

# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
cd postgresql-${pgsql_version}
  CC="gcc -m64" CXX="g++ -m64" ./configure \
    --prefix=$PREFIX \
    --exec-prefix=$PREFIX \
    --bindir=$PREFIX/bin/64 \
    --libexecdir=$PREFIX/bin/64 \
    --sbindir=$PREFIX/bin/64 \
    --datadir=$PREFIX/share \
    --sysconfdir=$PREFIX/etc \
    --mandir=$PREFIX/man \
    --libdir=$PREFIX/lib/64 \
    --includedir=$PREFIX/include/64 \
    --with-docdir=$PREFIX/doc \
    --sharedstatedir=/var/postgres/opengeo-8.4 \
    --localstatedir=/var/postgres/opengeo-8.4 \
    --with-system-tzdata=/usr/share/lib/zoneinfo \
    --with-pam \
    --with-openssl \
    --with-libxml \
    --with-libxslt \
    --enable-nls \
    --with-includes="/usr/sfw/include $PREFIX/include/64" \
    --with-libraries="/usr/sfw/lib/64 $PREFIX/lib/64" 

  make clean all \
  && make install \
  && cd contrib \
  && make clean all \
  && make install \
  && cd ..
cd ..

fi


###############################################################
# GDAL

if [ $gdal -eq 1 ]; then

# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
cd gdal-${gdal_version}
  CC="gcc" CXX="g++" ./configure \
   --prefix=$PREFIX \
   --with-expat-inc=/usr/sfw/include \
   --with-expat-lib="-L/usr/sfw/lib" \
   --with-geos=$PREFIX/bin/geos-config \
   --with-pg=$PREFIX/bin/pg_config 

#patch GDALmake.opt < ../build-gdal.patch
make clean all install
cd ..

# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
cd gdal-${gdal_version}
  CC="gcc -m64" LDFLAGS="-m64 -L/usr/sfw/lib/64" CXX="g++ -m64" ./configure \
   --prefix=$PREFIX \
   --exec-prefix=$PREFIX \
   --bindir=$PREFIX/bin/64 \
   --libexecdir=$PREFIX/bin/64 \
   --sbindir=$PREFIX/bin/64 \
   --datadir=$PREFIX/share \
   --sysconfdir=$PREFIX/etc \
   --mandir=$PREFIX/man \
   --libdir=$PREFIX/lib/64 \
   --with-expat-inc=/usr/sfw/include \
   --with-expat-lib="-L/usr/sfw/lib/64" \
   --with-curl=$PREFIX/bin/64/curl-config \
   --with-geos=$PREFIX/bin/64/geos-config \
   --with-pg=$PREFIX/bin/64/pg_config 

#patch GDALmake.opt < ../build-gdal.patch
make clean all install
cd ..

fi



###############################################################
# PostGIS 

if [ $postgis -eq 1 ]; then

# 32 BIT
#export LD_OPTIONS=-R\$ORIGIN/../lib
#cd postgis-${postgis_version}
#  CC="gcc" CXX="g++" ./configure \
#    --with-pgconfig=$PREFIX/bin/pg_config \
#    --with-geosconfig=$PREFIX/bin/geos-config \
#    --with-projdir=$PREFIX \
#    --with-xml2config=/usr/bin/xml2-config 
#    make clean all \
#    && make install
#cd ..

# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
cd postgis-${postgis_version}
  CC="gcc -m64" CXX="g++ -m64" ./configure \
    --with-pgconfig=$PREFIX/bin/64/pg_config \
    --with-geosconfig=$PREFIX/bin/64/geos-config \
    --with-gdalconfig=$PREFIX/bin/64/gdal-config \
    --with-projdir=$PREFIX \
    --with-xml2config=/usr/bin/xml2-config 

    make clean all \
    && make install
cd ..
  
fi
