# from https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:7.4-apache-buster

# install the PHP extensions we need
RUN set -eux; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
  /bin/echo -e "deb http://archive.debian.org/debian buster main contrib non-free\ndeb http://archive.debian.org/debian-security buster/updates main contrib non-free\ndeb http://archive.debian.org/debian buster-backports main contrib non-free\n" > /etc/apt/sources.list; \
  /bin/cat /etc/apt/sources.list; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libzip-dev \
# sts for mysql-client
		default-libmysqlclient-dev \
		libfontconfig1 \
		libgmp-dev \
		libxext6 \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg=/usr \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
		bcmath \
		gmp \
		mysqli \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	apt-get install -y --no-install-recommends curl tidy default-mysql-client vim git msmtp msmtp-mta libfontconfig1 libxext6 wget unzip zip; \
	rm -rf /var/lib/apt/lists/*

# ADD Variables DRUPAL_SUBDIR, APACHE_UID, APACHE_GID
COPY ./docker-php-entrypoint /usr/local/bin/docker-php-entrypoint

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini ; \
	{ \
		echo 'mbstring.http_input="pass"'; \
		echo 'mbstring.http_output="pass"'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stdout'; \
		echo 'sendmail_path="/usr/bin/msmtp --file /etc/msmtprc -t -i"'; \
		echo 'display_errors="stdout"'; \
		echo 'upload_max_filesize = "3M"'; \
		echo 'post_max_size = "20M"'; \
	} > /usr/local/etc/php/conf.d/php-overwrite.ini; \
	{ \
		echo 'host example.com'; \
		echo 'from server@localhost'; \
		echo 'maildomain example.com'; \
		echo 'syslog off'; \
	} > /etc/msmtprc

COPY --from=composer:1.10 /usr/bin/composer /usr/local/bin/
ENV PATH=/usr/local/bin:${PATH}

WORKDIR /var/www/html

# https://www.drupal.org/node/3060/release
ENV DRUPAL_VERSION=6.60
ENV DRUPAL_MD5=from-git-php74-ready
ENV DRUSH_VERSION=8.4.12

#RUN curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz \
#	&& echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c - \
#	&& tar -xz --strip-components=1 -f drupal.tar.gz \
#	&& rm drupal.tar.gz \
#	&& chown -R www-data:www-data sites modules themes ; \
#	git clone https://git.drupal.org/project/d6lts.git \
#	; patch -p1 < d6lts/common/core/SA-CORE-2018-001.patch \
#	; patch -p1 < d6lts/common/core/SA-CORE-2018-002.patch \
#	; patch -p1 < d6lts/common/core/SA-CORE-2018-002-bugfix1.patch \
#	; patch -p1 < d6lts/common/core/SA-CORE-2018-004.patch \
#	; patch -p1 < d6lts/common/core/SA-CORE-2018-006.patch \
#	; patch -p1 < d6lts/common/core/SA-CORE-2019-002.patch \
#	; patch -p1 < d6lts/common/core/SA-CORE-2019-006.patch \
#	; echo "*** Drupal CORE patched."
##	&& patch -p1 -d sites/all/modules/filefield < d6lts/common/contrib/filefield/SA-CORE-2018-004.patch ; \
##	&& patch -p1 -d sites/all/modules/lightbox2 < d6lts/common/contrib/lightbox2/SA-CONTRIB-2018-064.patch ; \
##	&& patch -p1 -d sites/all/modules/password_policy < d6lts/common/contrib/password_policy/sa-contrib-2018-077.patch \
##	&& patch -p1 -d sites/all/modules/print < d6lts/common/contrib/print/SA-CONTRIB-2018-063.patch ; \
##	&& patch -p1 -d sites/all/modules/session_limit < d6lts/common/contrib/session_limit/SA-CONTRIB-2018-072.patch ; \
##	&& patch -p1 -d sites/all/modules/views < d6lts/common/contrib/views/SA-CONTRIB-2014-054-6.x-2.x.patch ; \
##	&& patch -p1 -d sites/all/modules/views < d6lts/common/contrib/views/SA-CONTRIB-2016-036-6.x-2.x.patch ; \
##	&& patch -p1 -d sites/all/modules/views < d6lts/common/contrib/views/SA-CONTRIB-2017-022.patch ; \
##	&& patch -p1 -d sites/all/modules/views < d6lts/common/contrib/views/SA-CONTRIB-2017-068-6.x-2.x.patch ; \

RUN git clone https://github.com/d6lts/drupal.git ./; \
	COMPOSER_MEMORY_LIMIT=-1 composer require drush/drush ${DRUSH_VERSION}; \
    COMPOSER_MEMORY_LIMIT=-1 composer install; \
	chown -R www-data:www-data sites modules themes

# vim:set ft=dockerfile:
