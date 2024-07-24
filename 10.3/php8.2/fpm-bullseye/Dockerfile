#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:8.2-fpm-bullseye

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
# 2024-07-04: https://www.drupal.org/project/drupal/releases/10.3.1
ENV DRUPAL_VERSION 10.3.1
ENV DRUPAL_MD5 48dc4e58c9bb3cccda5df979a31de25a
ENV DRUSH_VERSION 12.4.3
ENV DRUPAL_COMPOSER_MODULES ""

# https://github.com/docker-library/drupal/pull/259
# https://github.com/moby/buildkit/issues/4503
# https://github.com/composer/composer/issues/11839
# https://github.com/composer/composer/issues/11854
# https://github.com/composer/composer/blob/94fe2945456df51e122a492b8d14ac4b54c1d2ce/src/Composer/Console/Application.php#L217-L218
ENV COMPOSER_ALLOW_SUPERUSER 1

WORKDIR /opt/drupal
#CMD ["apache2-foreground"]
# PRE Routines before official start
COPY ./apache2-pre-start-drupal /usr/local/bin/apache2-pre-start-drupal
CMD ["apache2-pre-start-drupal"]
# Contrib-Modules via docker-compose DRUPAL_COMPOSER_MODULES

RUN set -eux; \
	export COMPOSER_HOME="$(mktemp -d)"; \
	composer create-project --no-interaction "drupal/recommended-project:$DRUPAL_VERSION" ./; \
	chown -R www-data:www-data web/sites web/modules web/themes; \
	rmdir /var/www/html; \
	ln -sf /opt/drupal/web /var/www/html; \
	# delete composer cache
	rm -rf "$COMPOSER_HOME"

ENV PATH=${PATH}:/opt/drupal/vendor/bin

# vim:set ft=dockerfile:
