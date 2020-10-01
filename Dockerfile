# base
FROM php:7.3

ENV DEBIAN_FRONTEND noninteractive

# set the github runner version
ARG RUNNER_VERSION="2.273.4"

# update the base packages
RUN apt-get update -y

# add a non-sudo user
RUN useradd -m docker

# install packages
RUN additionalPackages=" \
	curl \
	jq \
	build-essential \
        apt-transport-https \
        git \
	unzip \
        msmtp-mta \
        openssh-client \
        rsync \
    " \
    buildDeps=" \
        freetds-dev \
        libbz2-dev \
        libc-client-dev \
        libenchant-dev \
        libfreetype6-dev \
        libgmp3-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libldap2-dev \
        libmcrypt-dev \
        libpq-dev \
        libpspell-dev \
        librabbitmq-dev \
        libsasl2-dev \
        libsnmp-dev \
        libssl-dev \
        libtidy-dev \
        libxml2-dev \
        libxpm-dev \
        libxslt1-dev \
        zlib1g-dev \
    " \
    && runDeps=" \
        libc-client2007e \
        libenchant1c2a \
        libfreetype6 \
        libicu57 \
        libjpeg62-turbo \
        libmcrypt4 \
        libpng-dev \
        libzip-dev \
        libpng16-16 \
        libpq5 \
        libsybdb5 \
        libx11-6 \
        libxpm4 \
        libxslt1.1 \
        snmp \
        gnupg \
        openssh-client \
        rsync \
    " \
    && phpModules=" \
        bcmath \
        bz2 \
        calendar \
        dba \
        enchant \
        exif \
        ftp \
        gd \
        gettext \
        gmp \
        imap \
        intl \
        ldap \
        mbstring \
        mysqli \
        opcache \
        pcntl \
        pdo \
        pdo_dblib \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        pspell \
        shmop \
        snmp \
        soap \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        tidy \
        wddx \
        xmlrpc \
        xsl \
        zip \
    " \
    && echo "deb http://security.debian.org/ stretch/updates main contrib non-free" > /etc/apt/sources.list.d/additional.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends $additionalPackages $buildDeps $runDeps \
    && docker-php-source extract \
    && cd /usr/src/php/ext/ \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap_r.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap_r.a /usr/lib/libldap_r.a \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure ldap --with-ldap-sasl \
    && docker-php-ext-install $phpModules \
    && printf "\n" \
    && for ext in $phpModules; do \
           rm -f /usr/local/etc/php/conf.d/docker-php-ext-$ext.ini; \
       done \
    && docker-php-source delete \
    && docker-php-ext-enable $phpModules

# Install pecl modules
RUN pecl install amqp \
    && pecl install igbinary \
    && pecl install mongodb \
    && pecl install redis \
    && pecl install ast \
    && docker-php-ext-enable mongodb redis ast amqp

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
        && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# install composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/ \
    && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer \
    && /usr/local/bin/composer global require hirak/prestissimo


# install nodejs and yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install nodejs yarn -y

# cleanup apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# copy over the start.sh script
COPY start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
