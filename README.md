# docker-drupal

Build docker images for Drupal 6, 7, 10.6, 11.3 and 11.4 with support for drush
Deprecated: <=10.5, <=11.2

* extra support for drush
* extra support for older drupal-6 (version 6.38), included d6lts patches
* extra support for apache with drupal in a subdir (drupal-6 only!)

@see too https://github.com/docker-library/drupal
Maintained by: [the Docker Community](https://github.com/docker-library/drupal) (*not* the Drupal Community or the Drupal Security Team)

## Support for contributed Modules

*DRUPAL_COMPOSER_MODULES*
You can use the environment varibale to add further contrib modules per composer.
e.g.
DRUPAL_COMPOSER_MODULES="drupal/ctools drupal/iframe"

**Folgende Versionen werden aktuell gebaut**

ENV DRUPAL_VERSION=10.6.20
ENV DRUPAL_VERSION=11.2.14
ENV DRUPAL_VERSION=11.3.20
ENV DRUPAL_VERSION=11.4.11
ENV DRUPAL_VERSION=11.5.0-beta1
ENV DRUPAL_VERSION=12.0.0-beta2
ENV DRUPAL_VERSION=6.60
ENV DRUPAL_VERSION=6.62
ENV DRUPAL_VERSION=7.103
ENV DRUPAL_VERSION=9.5.11
