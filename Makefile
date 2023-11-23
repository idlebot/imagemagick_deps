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
		curl -LO https://download.imagemagick.org/archive/delegates/ghostscript-9.55.0.tar.gz && \
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

imagemagick: libgs libjpeg libpng libtiff