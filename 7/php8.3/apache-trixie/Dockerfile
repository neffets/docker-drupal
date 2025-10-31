#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:8.3-apache-trixie

# install the PHP extensions we need
RUN set -eux; \
	\
	if command -v a2enmod; then \
# https://github.com/drupal/drupal/blob/d91d8d0a6d3ffe5f0b6dde8c2fbe81404843edc5/.htaccess (references both mod_expires and mod_rewrite explicitly)
		a2enmod expires rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libwebp-dev \
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
		--with-webp \
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
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini ; \
	{ \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'expose_php = Off'; \
		echo 'sendmail_path="/usr/bin/msmtp --file /etc/msmtprc -t -i"'; \
		echo 'display_errors="stderr"'; \
		echo 'upload_max_filesize = "3M"'; \
		echo 'post_max_size = "20M"'; \
	} > /usr/local/etc/php/conf.d/php-overwrite.ini; \
	{ \
		echo 'host example.com'; \
		echo 'from server@localhost'; \
		echo 'maildomain example.com'; \
		echo 'syslog off'; \
	} > /etc/msmtprc

# https://www.drupal.org/node/3298550
# Drupal now recommends sites enable PHP output buffering by default, if PHP is run as a server module
# e.g. with Apache's mod_php
RUN { \
		echo 'output_buffering=true'; \
	} > /usr/local/etc/php/conf.d/docker-php-drupal-recommended.ini

# 2024-12-04: https://www.drupal.org/project/drupal/releases/7.103
ENV DRUPAL_VERSION=7.103
ENV DRUPAL_MD5=9330ed0dd9926e82b06afb9cf236d5f6
ENV DRUSH_VERSION=10.6.1
ENV DRUPAL_COMPOSER_MODULES=""
ENV DRUPAL_URL=https://ftp.drupal.org/files/projects/drupal-7.103.tar.gz
ENV DRUPAL_MD5=9330ed0dd9926e82b06afb9cf236d5f6
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/
ENV PATH=/usr/local/bin:${PATH}

RUN set -eux; \
	curl -fSL "$DRUPAL_URL" -o drupal.tar.gz; \
	echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -; \
	tar -xz --strip-components=1 -f drupal.tar.gz; \
	rm drupal.tar.gz; \
	COMPOSER_MEMORY_LIMIT=-1 composer require --update-with-all-dependencies --dev drush/drush 10.6.1; \
	COMPOSER_MEMORY_LIMIT=-1 composer require michelf/php-markdown; \
	COMPOSER_MEMORY_LIMIT=-1 composer install; \
	chown -R www-data:www-data sites modules themes
ENV PATH=${PATH}:/var/www/html/vendor/bin

# vim:set ft=dockerfile:
