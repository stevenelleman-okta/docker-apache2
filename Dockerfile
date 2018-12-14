FROM gliderlabs/alpine:latest

# Enviroment variables you can override
ENV HTTPD_SERVER_ADMIN you@example.com
ENV HTTPD_LOG_LEVEL warn

ENV HTTPD_VERSION 2.4.35
ENV HTTPD_HASH 2607c6fdd4d12ac3f583127629291e9432b247b782396a563bec5678aae69b56 *httpd-2.4.35.tar.bz2
ENV APR_VERSION 1.6.5
ENV APR_HASH a67ca9fcf9c4ff59bce7f428a323c8b5e18667fdea7b0ebad47d194371b0a105 *apr-1.6.5.tar.bz2
ENV APRUTIL_VERSION 1.6.1
ENV APRUTIL_HASH d3e12f7b6ad12687572a3a39475545a072608f4ba03a6ce8a3778f607dd0035b  apr-util-1.6.1.tar.bz2

ENV DEV_PACKAGES autoconf clang make wget build-base file musl-dev libressl-dev pcre-dev curl-dev sqlite-dev luajit-dev perl expat-dev
ENV RUNTIME_PACKAGES pcre libressl curl sqlite luajit

RUN mkdir /build
RUN echo -e "http://nl.alpinelinux.org/alpine/v3.5/main\nhttp://nl.alpinelinux.org/alpine/v3.5/community" > /etc/apk/repositories
RUN apk --update add ${DEV_PACKAGES} ${RUNTIME_PACKAGES}

ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

ENV PKG_CONFIG_PATH /opt/lib/pkgconfig:/usr/lib/pkgconfig

WORKDIR /build
RUN wget http://archive.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.bz2
# RUN wget http://www.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.bz2
RUN wget http://www.apache.org/dist//apr/apr-${APR_VERSION}.tar.bz2
RUN wget http://www.us.apache.org/dist//apr/apr-util-${APRUTIL_VERSION}.tar.bz2
RUN echo "${HTTPD_HASH}" >> /build/sha256.sum
RUN echo "${APR_HASH}" >> /build/sha256.sum
RUN echo "${APRUTIL_HASH}" >> /build/sha256.sum
RUN sha256sum -c /build/sha256.sum

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
COPY ssl-vhost.conf /opt/conf/ssl-vhost.conf

ENTRYPOINT ["/opt/bin/httpd", "-DFOREGROUND"]

