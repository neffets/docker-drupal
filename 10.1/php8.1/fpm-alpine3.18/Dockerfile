#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:8.1-fpm-alpine3.18

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

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/
ENV PATH=/usr/local/bin:${PATH}
# 2023-12-06: https://www.drupal.org/project/drupal/releases/10.1.7
ENV DRUPAL_VERSION 10.1.7
ENV DRUPAL_MD5 c89d2e56737da5542a811913bd28de43
ENV DRUSH_VERSION 11.4.0

WORKDIR /opt/drupal
RUN set -eux; \
	export COMPOSER_HOME="$(mktemp -d)"; \
	composer create-project --no-interaction "drupal/recommended-project:$DRUPAL_VERSION" ./; \
	composer install; \
	COMPOSER_MEMORY_LIMIT=-1 composer require drupal/core-recommended:=$DRUPAL_VERSION drupal/core-composer-scaffold:=$DRUPAL_VERSION drupal/core-project-message:=$DRUPAL_VERSION; \
	COMPOSER_MEMORY_LIMIT=-1 composer require --update-with-all-dependencies drush/drush 11.4.0; \
	COMPOSER_MEMORY_LIMIT=-1 composer require michelf/php-markdown; \
	composer update; \
	chown -R www-data:www-data web/sites web/modules web/themes; \
	rmdir /var/www/html; \
	ln -sf /opt/drupal/web /var/www/html; \
	# delete composer cache
	rm -rf "$COMPOSER_HOME"

ENV PATH=${PATH}:/opt/drupal/vendor/bin

# vim:set ft=dockerfile: