#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# from https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:7.4-fpm-alpine3.15

# install the PHP extensions we need
RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		freetype-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libwebp-dev \
		libzip-dev \
# postgresql-dev is needed for https://bugs.alpinelinux.org/issues/3642
		postgresql-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg=/usr/include \
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
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .drupal-phpexts-rundeps $runDeps; \
	apk del --no-network .build-deps

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

COPY --from=composer:1 /usr/bin/composer /usr/local/bin/
ENV PATH=/usr/local/bin:${PATH}

# https://www.drupal.org/node/3060/release
ENV DRUPAL_VERSION 7.94
ENV DRUPAL_MD5 dae634ea0da005c5c435cfa9a9c5c322
ENV DRUSH_VERSION 8.3.2

RUN set -eux; \
	curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz; \
	echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -; \
	tar -xz --strip-components=1 -f drupal.tar.gz; \
	rm drupal.tar.gz; \
	COMPOSER_MEMORY_LIMIT=-1 composer require --update-with-all-dependencies --dev drush/drush 8.3.2; \
	COMPOSER_MEMORY_LIMIT=-1 composer require michelf/php-markdown; \
	COMPOSER_MEMORY_LIMIT=-1 composer install; \
	chown -R www-data:www-data sites modules themes
ENV PATH=${PATH}:/var/www/html/vendor/bin

# vim:set ft=dockerfile:
