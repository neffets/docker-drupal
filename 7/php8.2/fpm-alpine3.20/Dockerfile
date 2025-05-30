#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:8.2-fpm-alpine3.20

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
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini ; \
	{ \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stdout'; \
		echo 'expose_php = Off'; \
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

# 2024-11-20: https://www.drupal.org/project/drupal/releases/7.102
ENV DRUPAL_VERSION 7.102
ENV DRUPAL_MD5 3e97344b47cc87b0f51fc2048f38ee0b
ENV DRUSH_VERSION 8.3.2
ENV DRUPAL_COMPOSER_MODULES ""
ENV DRUPAL_URL https://ftp.drupal.org/files/projects/drupal-7.102.tar.gz
ENV DRUPAL_MD5 3e97344b47cc87b0f51fc2048f38ee0b
COPY --from=composer:1 /usr/bin/composer /usr/local/bin/
ENV PATH=/usr/local/bin:${PATH}

RUN set -eux; \
	curl -fSL "$DRUPAL_URL" -o drupal.tar.gz; \
	echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -; \
	tar -xz --strip-components=1 -f drupal.tar.gz; \
	rm drupal.tar.gz; \
	COMPOSER_MEMORY_LIMIT=-1 composer require --update-with-all-dependencies --dev drush/drush 8.3.2; \
	COMPOSER_MEMORY_LIMIT=-1 composer require michelf/php-markdown; \
	COMPOSER_MEMORY_LIMIT=-1 composer install; \
	chown -R www-data:www-data sites modules themes
ENV PATH=${PATH}:/var/www/html/vendor/bin

# vim:set ft=dockerfile:
