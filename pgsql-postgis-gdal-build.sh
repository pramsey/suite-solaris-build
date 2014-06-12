###############################################################
# Install Solaris

# Starting from Solaris 10u10 vanilla install

###############################################################
# Run the following AS ROOT

# Export the PGVER
export PGVER=9.3
export BUILDUSER=pramsey

# Add non-root user
useradd \
  -d /export/home/$BUILDUSER \
  -k /etc/skel \
  -s /bin/bash \
  -m $BUILDUSER

# Add install location
mkdir /usr/postgres/opengeo-${PGVER}
chown $BUILDUSER:other /usr/postgres/opengeo-${PGVER}

# Set up OpenCSW
# http://www.opencsw.org/manual/for-administrators/getting-started.html
pkgadd -d http://get.opencsw.org/now

# For development...
# install Git/Autotools/Gdb using OpenCSW
/opt/csw/bin/pkgutil -y -i git 
/opt/csw/bin/pkgutil -y -i automake autoconf libtool 
/opt/csw/bin/pkgutil -y -i gdb

# Alias for gmake to make
cd /usr/swf/bin
ln -s gmake make

###############################################################
# Run the following AS BUILDUSER

# As user, edit .bash_profile
# Add 'gcc' to path, 'ar' to path, csw to path
PATH=${PATH}:/usr/sfw/bin
PATH=${PATH}:/usr/ccs/bin
PATH=${PATH}:/opt/csw/bin
export PATH

# Export the PGVER
export PGVER=9.3

# Add build location
mkdir $HOME/Code
cd $HOME/Code

###############################################################
# Build readline

READLINE=readline-5.2

cd $HOME/Code
wget http://ftp.gnu.org/gnu/readline/$READLINE.tar.gz
gtar xvfz $READLINE.tar.gz
cd $READLINE

# 32 bit
export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" ./configure --prefix=/usr/postgres/opengeo-${PGVER} \
&& make clean all \
&& make install

# 64 bit
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" ./configure \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --infodir=/usr/postgres/opengeo-${PGVER}/info/ \
  --mandir=/usr/postgres/opengeo-${PGVER}/man/ \
  --includedir=/usr/postgres/opengeo-${PGVER}/include/64 \
&& make clean all \
&& make install

###############################################################
# Build PROJ
cd $HOME/Code
wget http://download.osgeo.org/proj/proj-4.8.0.tar.gz
wget http://download.osgeo.org/proj/proj-datumgrid-1.5.zip

gtar xvfz proj-4.8.0.tar.gz
cd proj-4.8.0/nad
unzip ../../proj-datumgrid-1.5.zip
cd ..

export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" ./configure --prefix=/usr/postgres/opengeo-${PGVER} \
&& make clean all \
&& make install

export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --includedir=/usr/postgres/opengeo-${PGVER}/include/64 \
  --bindir=/usr/postgres/opengeo-${PGVER}/bin/64 \
&& make clean all \
&& make install


###############################################################
# Build GEOS
cd $HOME/Code
wget http://download.osgeo.org/geos/geos-3.4.2.tar.bz2
gtar xvfj geos-3.4.2.tar.bz2
cd geos-3.4.2

export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" CXX="g++" ./configure --prefix=/usr/postgres/opengeo-${PGVER} \
&& make clean all \
&& make install
  
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" CXX="g++ -m64" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --bindir=/usr/postgres/opengeo-${PGVER}/bin/64 \
  --includedir=/usr/postgres/opengeo-${PGVER}/include/64 \
&& make clean all \
&& make install


###############################################################
# Make libreadline.so visible systemwide or the PostgreSQL
# configure will fail to find it. 
# for 32-bit
# Run AS ROOT
cd /usr/lib
ln -s /usr/postgres/opengeo-${PGVER}/lib/libreadline.so.5 libreadline.so.5
ln -s /usr/postgres/opengeo-${PGVER}/lib/libreadline.so.5 libreadline.so

# for 64-bit
cd /usr/lib/64
ln -s /usr/postgres/opengeo-${PGVER}/lib/64/libreadline.so.5 libreadline.so.5
ln -s /usr/postgres/opengeo-${PGVER}/lib/64/libreadline.so.5 libreadline.so


###############################################################
# Add readline to build user environment
export LD_LIBRARY_PATH_32=/usr/postgres/opengeo-${PGVER}/lib
export LD_LIBRARY_PATH_64=/usr/postgres/opengeo-${PGVER}/lib/64

###############################################################
# Get PostgreSQL
export PGVERFULL=9.3.4
cd $HOME/Code
wget http://ftp.postgresql.org/pub/source/v${PGVER}.4/postgresql-$PGVERFULL.tar.bz2
gtar xvfj postgresql-$PGVERFULL.tar.bz2
cd postgresql-$PGVERFULL

###############################################################
# Build PostgreSQL (32)

export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" CXX="g++" LIBS="-lrt -lstdc++" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --with-system-tzdata=/usr/share/lib/zoneinfo \
  --localstatedir=/var/postgres/opengeo-${PGVER} \
  --sharedstatedir=/var/postgres/opengeo-${PGVER} \
  --with-pam \
  --with-openssl \
  --with-libxml \
  --enable-nls \
  --with-libxslt \
  --with-includes="/usr/sfw/include /usr/postgres/opengeo-${PGVER}/include" \
  --with-libraries="/usr/sfw/lib /usr/postgres/opengeo-${PGVER}/lib" \
&& make clean all \
&& make install \
&& cd contrib \
&& make clean all \
&& make install \
&& cd ..

###############################################################
# Build PostgreSQL (64)

# the LIBS line adds librt for threading support and 
# libstdc++ so that the postgres process can properly catch
# exceptions tossed by libgeos (just like in the old days)

export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" CXX="g++ -m64" LIBS="-lrt -lstdc++" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --exec-prefix=/usr/postgres/opengeo-${PGVER} \
  --bindir=/usr/postgres/opengeo-${PGVER}/bin/64 \
  --libexecdir=/usr/postgres/opengeo-${PGVER}/bin/64 \
  --sbindir=/usr/postgres/opengeo-${PGVER}/bin/64 \
  --datadir=/usr/postgres/opengeo-${PGVER}/share \
  --sysconfdir=/usr/postgres/opengeo-${PGVER}/etc \
  --mandir=/usr/postgres/opengeo-${PGVER}/man \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --includedir=/usr/postgres/opengeo-${PGVER}/include/64 \
  --docdir=/usr/postgres/opengeo-${PGVER}/doc \
  --sharedstatedir=/var/postgres/opengeo-${PGVER} \
  --localstatedir=/var/postgres/opengeo-${PGVER} \
  --with-system-tzdata=/usr/share/lib/zoneinfo \
  --with-pam \
  --with-openssl \
  --with-libxml \
  --with-libxslt \
  --enable-nls \
  --with-includes="/usr/sfw/include /usr/postgres/opengeo-${PGVER}/include/64" \
  --with-libraries="/usr/sfw/lib/64 /usr/postgres/opengeo-${PGVER}/lib/64" \
&& make clean all \
&& make install \
&& cd contrib \
&& make clean all \
&& make install \
&& cd ..

###############################################################
# Build CURL

cd $HOME/Code
wget http://curl.haxx.se/download/curl-7.37.0.tar.gz
gtar xvfz curl-7.37.0.tar.gz
cd curl-7.37.0

# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" CXX="g++ -m32" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
&& make clean all install

# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" CXX="g++ -m64" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --exec-prefix=/usr/postgres/opengeo-${PGVER} \
  --bindir=/usr/postgres/opengeo-${PGVER}/bin \
  --libexecdir=/usr/postgres/opengeo-${PGVER}/bin \
  --sbindir=/usr/postgres/opengeo-${PGVER}/bin \
  --datadir=/usr/postgres/opengeo-${PGVER}/share \
  --sysconfdir=/usr/postgres/opengeo-${PGVER}/etc \
  --mandir=/usr/postgres/opengeo-${PGVER}/man \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib \
&& make clean all install


###############################################################
# Build GDAL 

cd $HOME/Code
wget http://download.osgeo.org/gdal/1.10.1/gdal-1.10.1.tar.gz
gtar xvfz gdal-1.10.1.tar.gz
cd gdal-1.10.1

# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" CXX="g++ -m32" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --with-expat-include=/usr/sfw/include \
  --with-expat-lib="-L/usr/sfw/lib" \
  --with-curl=/usr/postgres/opengeo-${PGVER}/bin/curl-config \
  --with-geos=/usr/postgres/opengeo-${PGVER}/bin/geos-config \
  --with-pg=/usr/postgres/opengeo-${PGVER}/bin/pg_config 

# STOP, manually edit GDALmake.opt, uncomment SHELL variable
make clean all install

# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" CXX="g++ -m64" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --exec-prefix=/usr/postgres/opengeo-${PGVER} \
  --bindir=/usr/postgres/opengeo-${PGVER}/bin/64 \
  --libexecdir=/usr/postgres/opengeo-${PGVER}/bin/64 \
  --sbindir=/usr/postgres/opengeo-${PGVER}/bin/64 \
  --datadir=/usr/postgres/opengeo-${PGVER}/share \
  --sysconfdir=/usr/postgres/opengeo-${PGVER}/etc \
  --mandir=/usr/postgres/opengeo-${PGVER}/man \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --with-expat-inc=/usr/sfw/include \
  --with-expat-lib="-L/usr/sfw/lib/64" \
  --with-curl=/usr/postgres/opengeo-${PGVER}/bin/64/curl-config \
  --with-geos=/usr/postgres/opengeo-${PGVER}/bin/64/geos-config \
  --with-pg=/usr/postgres/opengeo-${PGVER}/bin/64/pg_config 

# STOP, manually edit GDALmake.opt, uncomment SHELL variable
# STOP, manually edit GDALmake.opt change /usr/sfw/lib to /usr/sfw/lib/64
make clean all install

###############################################################
# Build JSON-C

cd $HOME/Code
wget --no-check-certificate https://github.com/json-c/json-c/archive/json-c-0.11-20130402.tar.gz
gtar xvfz json-c-0.11-20130402.tar.gz
cd json-c-json-c-0.11-20130402

# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" ./configure --prefix=/usr/postgres/opengeo-${PGVER} \
&& make clean all \
&& make install

# 64 bit
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" ./configure \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --infodir=/usr/postgres/opengeo-${PGVER}/info/ \
  --mandir=/usr/postgres/opengeo-${PGVER}/man/ \
  --includedir=/usr/postgres/opengeo-${PGVER}/include/64 \
&& make clean all \
&& make install


###############################################################
# Get PostGIS

cd $HOME/Code
wget http://download.osgeo.org/postgis/source/postgis-2.1.3.tar.gz
gtar xvfz postgis-2.1.3.tar.gz
cd postgis-2.1.3

###############################################################
# Patch PostGIS
# We have to patch PostGIS to build, up oh. 
# - Solaris missing the isfinite() function is a problem
#   (worse, it seems to have a header macro for it, but 
#   doesn't have a library symbol for it, huh?)
# - Solaris layout of 64bit libraries requires configure to be
#   patched to find them in their ./64/ sub directories rather
#   than under a common prefix
  
# 32 BIT
export LD_OPTIONS=-R\$ORIGIN/../lib
CC="gcc -m32" CXX="g++ -m32" LDFLAGS="-lm" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --with-pgconfig=/usr/postgres/opengeo-${PGVER}/bin/pg_config \
  --with-geosconfig=/usr/postgres/opengeo-${PGVER}/bin/geos-config \
  --with-gdalconfig=/usr/postgres/opengeo-${PGVER}/bin/gdal-config \
  --with-projdir=/usr/postgres/opengeo-${PGVER} \
  --with-jsondir=/usr/postgres/opengeo-${PGVER} \
  --with-xml2config=/usr/bin/xml2-config \
  && make clean all \
  && make install
  
# 64 BIT
export LD_OPTIONS=-R\$ORIGIN/../../lib/64
CC="gcc -m64" CXX="g++ -m64" LDFLAGS="-lm" ./configure \
  --prefix=/usr/postgres/opengeo-${PGVER} \
  --libdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --includedir=/usr/postgres/opengeo-${PGVER}/include/64 \
  --with-pgconfig=/usr/postgres/opengeo-${PGVER}/bin/64/pg_config \
  --with-geosconfig=/usr/postgres/opengeo-${PGVER}/bin/64/geos-config \
  --with-gdalconfig=/usr/postgres/opengeo-${PGVER}/bin/64/gdal-config \
  --with-projincludedir=/usr/postgres/opengeo-${PGVER}/include/64 \
  --with-projlibdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --with-jsonincludedir=/usr/postgres/opengeo-${PGVER}/include/64 \
  --with-jsonlibdir=/usr/postgres/opengeo-${PGVER}/lib/64 \
  --with-xml2config=/usr/bin/xml2-config \
  && make clean all \
  && make install
  

###############################################################
# STOP HERE
# below is historical information
###############################################################




###############################################################
# Reset RPATH to $ORIGIN/../../lib/64 to allow relocation of
# binaries
#
# NOTE NOTE NOTE!!!
# with LD_OPTIONS, this should not be needed anymore
# Also, this only works for Solaris 10u10 and up
# For older versions, use the crle system-wide setting of 
# library search paths at the bottom of these directions

# Get rpath
wget http://blogs.sun.com/ali/resource/rpath.tgz
# untar and build it

# 32 bit lib
find /usr/postgres/opengeo-${PGVER}/lib -type f -exec ./rpath {} /lib:/usr/lib:/usr/sfw/lib:\$ORIGIN ';'

# 32 bit bin
find /usr/postgres/opengeo-${PGVER}/bin -type f -exec ./rpath {} /lib:/usr/lib:/usr/sfw/lib:\$ORIGIN/../lib ';'

# 64 bit lib
find /usr/postgres/opengeo-${PGVER}/lib/64 -type f -exec ./rpath {} /lib/64:/usr/lib/64:/usr/sfw/lib/64:\$ORIGIN ';'

# 64 bit bin
find /usr/postgres/opengeo-${PGVER}/bin/64 -type f -exec ./rpath {} /lib/64:/usr/lib/64:/usr/sfw/lib/64:\$ORIGIN/../../lib/64 ';'


###############################################################
# Initialization

cd /usr/postgres/opengeo-${PGVER}/etc/smf
# Copy postgres_og84 to /lib/svc/method
# Copy postgresql_og84.xml to /var/svn/manifest/application/database
cd /var/svn/manifest/application/database
/usr/sbin/svccfg import postgresql_og84.xml
svcs postgresql_og84
/usr/sbin/svcadm enable postgresql_og84:default_64bit

###############################################################
# Template PostGIS

add /usr/postgres/opengeo-${PGVER}/bin/64 to your PATH
createdb -U postgres template_postgis
createlang -U postgres -d template_postgis plpgsql
psql -U postgres -f /usr/postgres/opengeo-${PGVER}/share/contrib/postgis-1.5/postgis.sql -d template_postgis
psql -U postgres -f /usr/postgres/opengeo-${PGVER}/share/contrib/postgis-1.5/spatial_ref_sys.sql -d template_postgis
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


###############################################################
# CRLE
# can be used to set the library paths system-wide. 
# For Solaris 10u10 and up, use the rpath re-write trick
# above.

crle -u -l /usr/postgres/opengeo-${PGVER}/lib
crle -64 -u -l /usr/postgres/opengeo-${PGVER}/lib/64


