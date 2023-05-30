FROM ubuntu:focal

ARG GEOMET_MAPPROXY_URL=https://geomet-dev-21-nightly.cmc.ec.gc.ca/geomet-mapproxy

ENV BASEDIR=/data/web/geomet-mapproxy-nightly
ENV DOCKERDIR=${BASEDIR}/docker  \
    GEOMET_MAPPROXY_LOGGING_LOGLEVEL=DEBUG \
    GEOMET_MAPPROXY_LOGGING_LOGFILE=/tmp/geomet-mapproxy-nightly.log \
    CRONTAB=${BASEDIR}/deploy/nightly/cron.d/geomet-mapproxy \
    GEOMET_MAPPROXY_CACHE_DATA=$BASEDIR/cache_data \
    GEOMET_MAPPROXY_CACHE_WMS=https://geomet-dev-21-nightly.cmc.ec.gc.ca/geomet \
    GEOMET_MAPPROXY_CACHE_MAPFILE=/opt/geomet/conf/geomet-en.map \
    GEOMET_MAPPROXY_CACHE_XML=/opt/geomet/conf/geomet-wms-1.3.0-capabilities-en.xml \
    GEOMET_MAPPROXY_URL=$GEOMET_MAPPROXY_URL \
    GEOMET_MAPPROXY_CONFIG=${BASEDIR}/geomet-mapproxy-config.yml \
    GEOMET_MAPPROXY_CACHE_CONFIG=${BASEDIR}/deploy/default/geomet-mapproxy-cache-config.yml \
    GEOMET_MAPPROXY_TMP=/tmp \
    GUNICORN_GEOMET_MAPPROXY_ACCESSLOG=/tmp/gunicorn-geomet-mapproxy-nightly-access.log \
    GUNICORN_GEOMET_MAPPROXY_ERRORLOG=/tmp/gunicorn-geomet-mapproxy-nightly-errors.log

# install system dependencies
RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:gcpp-kalxas/wmo && add-apt-repository ppa:ubuntugis/ubuntugis-unstable && apt update && \
    apt-get install -y python3 python3-pip python3-pil python3-yaml python3-pyproj && \
    # ## other misc dependencies
    apt install -y git cron make && \
    # remove transient packages
    apt clean autoclean && apt autoremove --yes && rm -fr /var/lib/{apt,dpkg,cache,log}/

COPY . $BASEDIR

WORKDIR $BASEDIR

RUN pip3 install -r requirements.txt && \
    # add gunicorn for Docker deploy
    pip3 install gunicorn && \
    # install geomet-mapproxy
    pip install . && \
    # Set up cache data directory
    mkdir -p $GEOMET_MAPPROXY_CACHE_DATA && \
    # Amend permissions to crontab and use crontab command to make file known to the cron daemon
    chmod 0644 $CRONTAB && mv $CRONTAB /etc/cron.d && crontab /etc/cron.d/geomet-mapproxy && \
    # Set 666 permissions on log files
    touch $GEOMET_MAPPROXY_LOGGING_LOGFILE && chmod 0666 $GEOMET_MAPPROXY_LOGGING_LOGFILE && \
    # permission fix (mark as executable)
    chmod +x $DOCKERDIR/entrypoint.sh

ENTRYPOINT [ "sh", "-c", "$DOCKERDIR/entrypoint.sh" ]
