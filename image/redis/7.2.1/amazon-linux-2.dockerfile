# Docker image to use. Parallel stage
FROM sloopstash/base:v1.1.1 AS install_system_packages

# Install system packages.
# tcl might already exists in amazon linux 2 - but executing it still.
RUN yum install -y tcl

#--------------------------------------------------------------------------------

# User above stage is base. This could have been written in above stage only.
# Dependant stage
From install_system_packages AS install_redis

# Download and extract Redis.
WORKDIR /tmp
RUN set -x \
  && wget http://download.redis.io/releases/redis-7.2.1.tar.gz --quiet \
  && tar xvzf redis-7.2.1.tar.gz > /dev/null

# Compile and install Redis.
WORKDIR redis-7.2.1
RUN set -x \
  && make distclean \
  && make \
  && make install

#----------------------------------------------------------------------------------

# Parallel stage
FROM sloopstash/base:v1.1.1 AS create_redis_directories

# Create Redis directories.
RUN set -x \
  && mkdir /opt/redis \
  && mkdir /opt/redis/data \
  && mkdir /opt/redis/log \
  && mkdir /opt/redis/conf \
  && mkdir /opt/redis/script \
  && mkdir /opt/redis/system \
  && touch /opt/redis/system/server.pid \
  && touch /opt/redis/system/supervisor.ini

#------------------------------------------------------------------------------------

# Convergence/final stage
FROM sloopstash/base:v1.1.1 AS finalize_redis_oci_image

# Here we are copying only redis-sever and redis-cli so reduced size is obtained. We do not copy redis-sentinel etc

COPY --from=install_redis /usr/local/bin/redis-server /usr/local/bin/redis-server
COPY --from=install_redis /usr/local/bin/redis-cli /usr/local/bin/redis-cli
COPY --from=create_redis_directories /opt/redis /opt/redis

# about supervisor will be learnt more in container session.
RUN set -x \
  && ln -s /opt/redis/system/supervisor.ini /etc/supervisord.d/redis.ini \
  && history -c

# Set default work directory.
WORKDIR /opt/redis