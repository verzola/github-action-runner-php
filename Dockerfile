# base
FROM php:7.3

ENV DEBIAN_FRONTEND noninteractive

# set the github runner version
ARG RUNNER_VERSION="2.273.4"

# update the base packages
RUN apt-get update -y

# add a non-sudo user
RUN useradd -m docker

# install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
RUN apt-get install -y curl \
        jq \
        build-essential \
	libssl-dev \
	libffi-dev \
	git \
	build-essential \
	unzip \
	gnupg \
	libjpeg62-turbo-dev \
	libjpeg62-turbo \
	libpng-dev \
	libpng16-16 \
	libxpm-dev \
	libxpm4 \
	libfreetype6-dev \
	libfreetype6 \
	libzip-dev \
	libbz2-dev

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/

# install php extensions
RUN docker-php-ext-install bcmath \
        bz2 \
        calendar \
        dba \
        exif \
        ftp \
        gd \
        gettext \
        gmp \
        intl \
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
        xmlrpc \
        xsl \
        zip

RUN docker-php-ext-enable bcmath \
        bz2 \
        calendar \
        dba \
        enchant \
        exif \
        ftp \
        gd \
        gettext \
        gmp \
        intl \
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
        xmlrpc \
        xsl \
        zip


# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
        && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# copy over the start.sh script
COPY start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# install composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/ \
    && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer \
    && /usr/local/bin/composer global require hirak/prestissimo


# install nodejs and yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install nodejs yarn

# cleanup apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
