# docker-drupal

Build docker images for Drupal 6, 7, 10.1, 10.2 and 10.3-rc with support for drush

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

ENV DRUPAL_VERSION 10.1.8
ENV DRUPAL_VERSION 10.2.5
ENV DRUPAL_VERSION 6.59
ENV DRUPAL_VERSION 7.100
ENV DRUPAL_VERSION 9.5.11
