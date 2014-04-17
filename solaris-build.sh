#!/bin/bash
#
# This script is for building out the binaries of the Suite needed
# for the further packaging scripts in this repository.
#

PREFIX=/usr/postgres/opengeo-9.2-build

set -e

readline=0
curl=0
proj=0
geos=0
pgsql=0
gdal=1
postgis=0

geos_version=3.3.9
proj_version=4.7.0
pgsql_version=9.2.4
postgis_version=2.0.4
gdal_version=1.9.2

#########################################################################
# Readline
#

if [ $readline -eq 1 ]; then

# 32 bit
export LD_OPTIONS=-R\$ORIGIN/../lib
cd readline-5.2
CC="gcc" ./configure --prefix=$PREFIX 
make clean all 
make install
cd ..

# 64 bit
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
cd readline-5.2
CC="gcc -m64" ./configure \
  --libdir=$PREFIX/lib/64 \
  --infodir=$PREFIX/info/ \
  --mandir=$PREFIX/man/ \
  --includedir=$PREFIX/include/64 
make clean all 
make install
cd ..

fi

#########################################################################
# CuRL
#

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
