FROM ubuntu:18.04

RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends apt-utils \
    curl \
    # Install git
    git \
    # Install apache
    apache2 \
    # Install php 7.2
    php7.2 \
    libapache2-mod-php7.2 \
    php7.2-cli \
    php7.2-json \
    php7.2-curl \
    php7.2-fpm \
    php7.2-gd \
    php7.2-ldap \
    php7.2-mbstring \
    php7.2-mysql \
    php7.2-soap \
    php7.2-sqlite3 \
    php7.2-xml \
    php7.2-zip \
    php7.2-intl \
    # Install tools
    openssl \
    nano \
    mysql-client \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable apache mods.
RUN a2enmod php7.2
RUN a2enmod rewrite

# Update the PHP.ini file, enable <? ?>
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.2/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.2/apache2/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Set ServerName
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Expose apache.
EXPOSE 80

# Update the default apache site with the config we created.
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND

# ---- Magento Installation ----

# Environment variables
ENV MAGENTO_VERSION 2.3.2
ENV INSTALL_DIR /var/www/html
ENV COMPOSER_HOME /var/www/.composer/

# Composer download
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Copy Magento Authentication file
COPY ./auth.json $COMPOSER_HOME

# Required files
RUN requirements="libpng-dev libmcrypt-dev libmcrypt4 libcurl3-dev libfreetype6 libjpeg-turbo8 libjpeg-turbo8-dev libfreetype6-dev libicu-dev libxslt1-dev unzip" \
    && apt-get update \
    && apt-get install -y $requirements \
    && rm -rf /var/lib/apt/lists/* \
    && requirementsToRemove="libpng-dev libmcrypt-dev libcurl3-dev libfreetype6-dev libjpeg-turbo8-dev" \
    && apt-get purge --auto-remove -y $requirementsToRemove

RUN chsh -s /bin/bash www-data

# Download Magento 
RUN cd /tmp && \ 
    curl https://codeload.github.com/magento/magento2/tar.gz/$MAGENTO_VERSION -o $MAGENTO_VERSION.tar.gz && \
    tar xvf $MAGENTO_VERSION.tar.gz && \
    mv magento2-$MAGENTO_VERSION/* magento2-$MAGENTO_VERSION/.htaccess $INSTALL_DIR

# More requirements for Magento installation
RUN apt-get update && apt-get install php-bcmath php-soap -y

# Give user www-data the access to act
RUN chown -R www-data:www-data /var/www
RUN su www-data -c "cd $INSTALL_DIR && composer install"
RUN su www-data -c "cd $INSTALL_DIR && composer config repositories.magento composer https://repo.magento.com/"  

# Rights for bin/magento
RUN cd $INSTALL_DIR \
    && find . -type d -exec chmod 770 {} \; \
    && find . -type f -exec chmod 660 {} \; \
    && chmod u+x bin/magento



# ----- Enter your database information -----
# Environmental variables for Magento
ENV MYSQL_HOST *YOUR_DATABASE_HOST*
ENV MYSQL_USER *YOUR_DATABASE_USER*
ENV MYSQL_PASSWORD *YOUR_DATABASE_PASSWORD*
ENV MYSQL_DATABASE *YOUR_DATABASE_NAME*

ENV MAGENTO_LANGUAGE en_US
ENV MAGENTO_TIMEZONE America/New_York
ENV MAGENTO_DEFAULT_CURRENCY CAD
ENV MAGENTO_URL http://localhost:8086/
ENV MAGENTO_BACKEND_FRONTNAME admin

ENV MAGENTO_ADMIN_FIRSTNAME Admin
ENV MAGENTO_ADMIN_LASTNAME User
ENV MAGENTO_ADMIN_EMAIL admin@admin.com
ENV MAGENTO_ADMIN_USERNAME admin
ENV MAGENTO_ADMIN_PASSWORD admin123

# Command to install Magento
# more info: https://devdocs.magento.com/guides/v2.3/install-gde/install/cli/install-cli-install.html
RUN cd $INSTALL_DIR && php bin/magento setup:install --base-url=http://localhost:8086/  --backend-frontname=admin --db-host=mg-db.cwdtwykr2kw1.us-east-1.rds.amazonaws.com:3306 --db-name=mgdb --db-user=admin --db-password=Magento#12 --admin-firstname=Magento --admin-lastname=User --admin-email=root@example.com --admin-user=admin --admin-password=admin123 --language=en_US --currency=USD --timezone=America/New_York --use-rewrites=1

# Give permissions and compile Magento code
RUN cd $INSTALL_DIR \
    && chown -R www-data:www-data ${INSTALL_DIR} \
    && chmod 777 -R var \
    && chmod 777 -R generated \
    && chmod 777 -R app/etc \
    && rm -rf var/cache/* var/page_cache/* var/generation/* \
    && php bin/magento setup:di:compile;

# Increase memory limit to 1024mb
# RUN cd /etc/php/7.2/apache2/
# RUN sed -i 's/memory_limit = .*/memory_limit = 1024M/' php.ini  

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR $INSTALL_DIR
