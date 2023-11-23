IMAGEMAGICK_VERSION=7.1.1-21

ROOT_DIR=$(shell realpath "$$PWD")

PLATFORM=$(uname -sm | awk '{print tolower($1"-"$2)}')
PACKAGE_PREFIX=imagemagick-$(IMAGEMAGICK_VERSION)
PACKAGE_NAME=imagemagick-$(PLATFORM)-$(IMAGEMAGICK_VERSION).tar.gz

DIST_DIR=$(ROOT_DIR)/dist/$(PACKAGE_PREFIX)
WORK_DIR=$(ROOT_DIR)/work

dirs:
	mkdir -p $(DIST_DIR)
	mkdir -p $(WORK_DIR)

clean:
	rm -rf $(WORK_DIR)
	rm -rf $(DIST_DIR)

objconv: dirs
	pushd $(WORK_DIR) && \
		curl -LO https://github.com/gitGNU/objconv/archive/refs/tags/v2.50.tar.gz && \
		tar zxf *.tar.gz && rm *.tar.gz && \
		pushd objconv*/src && \
		./build.sh && cp objconv $(DIST_DIR) && \
		popd && \
	popd # $(WORK_DIR)

libgs: dirs objconv
	pushd $(WORK_DIR) && \
		curl -LO https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs9550/ghostscript-9.55.0.tar.gz && \
		tar zxf ghostscript*.gz && rm ghostscript*.gz && mv ghostscript* ghostscript && cd ghostscript && \
		CFLAGS="-fPIC" ./configure --prefix=$(DIST_DIR) \
  			--without-tesseract --disable-fontconfig --without-libidn --disable-cups --with-libiconv=no --without-x \
  			--with-drivers="PS,JPEG,PNG,TIFF" && \
		make libgs && \
		mkdir -p $(DIST_DIR)/lib && \
		$(DIST_DIR)/objconv \
			-np:_jpeg_:gs_jpeg_ -np:_jinit_:gs_jinit_ -np:_jcopy_:gs_jcopy_ -np:_jround_:gs_jround_ -np:_jdiv_:gs_jdiv_ \
			-np:jpeg_:gsjpeg_ -np:jinit_:gsjinit_ -np:jcopy_:gsjcopy_ -np:jround_:gsjround_ -np:jdiv_:gsjdiv_ \
			-np:_cms:gs_cms -np:__cms:gs__cms \
			-np:cms:gscms \
			-np:_TIFF:gs_TIFF -np:__TIFF:gs__TIFF -np:_LogL:gs_LogL -np:_uv_:gs_uv_ -np:_XYZ:gs_XYZ \
			-np:TIFF:gsTIFF -np:LogL:gsLogL -np:uv_:gsuv_ -np:XYZ:gsXYZ \
			bin/gs.a $(DIST_DIR)/lib/libgs.a && \
	popd # $(WORK_DIR)

libjpeg: dirs
	pushd $(WORK_DIR) && \
		curl -LO http://www.imagemagick.org/download/delegates/jpegsrc.v9b.tar.gz && \
		tar zxf jpeg*.gz && rm jpeg*.gz && mv jpeg* jpeg && cd jpeg && \
		CFLAGS="-fPIC" ./configure --prefix=$(DIST_DIR) --disable-shared --disable-dependency-tracking && \
		make install && \
	popd # $(WORK_DIR)

libpng: dirs
	pushd $(WORK_DIR) && \
		curl -LO http://www.imagemagick.org/download/delegates/libpng-1.6.31.tar.xz && \
		tar Jxf libpng*.xz && rm libpng*.xz && mv libpng* png && cd png && \
		CFLAGS="-fPIC" ./configure --prefix=$(DIST_DIR) --disable-shared --disable-dependency-tracking && \
		make install && \
	popd # $(WORK_DIR)

libtiff: dirs
	pushd $(WORK_DIR) && \
		curl -LO http://www.imagemagick.org/download/delegates/tiff-4.0.8.tar.gz && \
		tar zxf tiff*.gz && rm tiff*.gz && mv tiff* tiff && cd tiff && \
		CFLAGS="-fPIC" ./configure --prefix=$(DIST_DIR) --disable-shared --disable-dependency-tracking --disable-lzma --disable-jbig && \
		make install && \
	popd # $(WORK_DIR)

liblcms2: dirs
	pushd $(WORK_DIR) && \
		curl -LO http://www.imagemagick.org/download/delegates/lcms2-2.8.tar.gz && \
		tar zxf lcms2*.gz && rm lcms2*.gz && mv lcms* lcms && cd lcms && \
		CFLAGS="-fPIC" ./configure --prefix=$(DIST_DIR) --disable-shared --disable-dependency-tracking && \
		make install && \
	popd # $(WORK_DIR)

zlib: dirs
	pushd $(WORK_DIR) && \
		curl -LO http://www.imagemagick.org/download/delegates/zlib-1.2.11.tar.xz && \
		tar Jxf zlib*.xz && rm zlib*.xz && mv zlib* zlib && cd zlib && \
		CFLAGS="-fPIC" ./configure --prefix=$(DIST_DIR) --static && \
		make install && \
	popd # $(WORK_DIR)

imagemagick: libgs libjpeg libpng libtiff liblcms2 zlib
	pushd $(WORK_DIR) && \
		curl -LO https://github.com/ImageMagick/ImageMagick/archive/refs/tags/$(IMAGEMAGICK_VERSION).tar.gz && \
		tar xzf *.tar.gz && rm *.gz && \
		PKG_CONFIG_PATH= \
		PKG_CONFIG_LIBDIR=$(DIST_DIR)/lib/pkgconfig \
		CFLAGS="-fPIC" \
		$(WORK_DIR)/ImageMagick-$(IMAGEMAGICK_VERSION)/configure \
			--prefix $(DIST_DIR) \
			--without-magick-plus-plus \
			--without-perl \
			--with-utilities=no \
			--with-modules=no \
			--disable-openmp \
			--disable-cipher \
			--disable-dpc \
			--without-x \
			--with-gvc=no \
			--with-fontconfig=no \
			--with-freetype=no \
			--disable-docs \
			--enable-static \
			--disable-shared \
			--enable-delegate-build \
			--disable-installed \
			--enable-zero-configuration \
			--with-gslib=yes \
			--with-jpeg=yes \
			--with-png=yes \
			--with-tiff=yes \
			--with-zlib=yes \
			--with-lcms=yes \
			--with-webp=no \
			--with-djvu=no \
			--with-jbig=no \
			--with-jxl=no \
			--with-bzlib=no \
			--with-lqr=no \
			--with-lzma=no \
			--with-dmr=no \
			--with-heic=no \
			--with-pango=no \
			--with-openexr=no \
			--with-openjp2=no \
			--with-raqm=no \
			--with-raw=no \
			--with-zip=no \
			--with-zstd=no \
			--with-xml=no && \
		make install && \
	popd # $(WORK_DIR)