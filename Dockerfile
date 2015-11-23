FROM gliderlabs/alpine:latest

# Enviroment variables you can override
ENV HTTPD_SERVER_ADMIN you@example.com
ENV HTTPD_LOG_LEVEL warn

ENV HTTPD_VERSION 2.4.17
ENV HTTPD_HASH cf4dfee11132cde836022f196611a8b7 *httpd-2.4.17.tar.bz2
ENV APR_VERSION 1.5.2
ENV APR_HASH 4e9769f3349fe11fc0a5e1b224c236aa *apr-1.5.2.tar.bz2
ENV APRUTIL_VERSION 1.5.4
ENV APRUTIL_HASH 2202b18f269ad606d70e1864857ed93c *apr-util-1.5.4.tar.bz2


ENV DEV_PACKAGES autoconf clang make wget build-base file musl-dev openssl-dev pcre-dev curl-dev jansson-dev sqlite-dev luajit-dev
ENV RUNTIME_PACKAGES pcre openssl curl jansson sqlite luajit

RUN mkdir /build
RUN apk --update add ${DEV_PACKAGES} ${RUNTIME_PACKAGES}

ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

WORKDIR /build
RUN wget http://www.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.bz2
RUN wget http://www.apache.org/dist//apr/apr-${APR_VERSION}.tar.bz2
RUN wget http://www.us.apache.org/dist//apr/apr-util-${APRUTIL_VERSION}.tar.bz2
RUN echo "${HTTPD_HASH}" >> /build/md5.sum
RUN echo "${APR_HASH}" >> /build/md5.sum
RUN echo "${APRUTIL_HASH}" >> /build/md5.sum
RUN md5sum -c /build/md5.sum

RUN tar -xjf apr-${APR_VERSION}.tar.bz2
RUN tar -xjf apr-util-${APRUTIL_VERSION}.tar.bz2
RUN tar -xjf httpd-${HTTPD_VERSION}.tar.bz2

WORKDIR /build/apr-${APR_VERSION}
RUN ./configure --prefix=/opt --enable-nonportable-atomics --enable-threads
RUN make -j 2
RUN make install

WORKDIR /build/apr-util-${APRUTIL_VERSION}
RUN ./configure --prefix=/opt --with-apr=/opt --with-crypto --with-openssl=/usr --with-sqlite3=/usr
RUN make -j 2
RUN make install

WORKDIR /build/httpd-${HTTPD_VERSION}
RUN ./configure \
	--prefix=/opt \
	--with-apr=/opt \
	--with-apr-util=/opt \
	--enable-so \
	--enable-mods-shared=all \
	--enable-ssl=shared \
	--enable-pie \
	--enable-luajit \
	--with-pcre=/usr \
	--with-ssl=/usr \
	--with-mpm=event
RUN make -j 2
RUN make install

WORKDIR /
RUN mkdir -p /logs /conf /modules.conf.d
RUN rm -rf /build
RUN apk del ${DEV_PACKAGES}

VOLUME /logs
VOLUME /conf

COPY httpd.conf /opt/conf/httpd.conf

ENTRYPOINT ["/opt/bin/httpd", "-DFOREGROUND"]
