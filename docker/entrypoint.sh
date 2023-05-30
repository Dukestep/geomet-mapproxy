# create initial config
echo "Creating initial config for geomet-mapproxy"
geomet-mapproxy config create

# pass in GEOMET_MAPPROXY env variables to /etc/environment so they are available to cron
env | grep ^GEOMET_MAPPROXY >> /etc/environment
# startup cron jobs (builds mapfile at schedule cron settings)
service cron start

# startup geomet-mapproxy
echo "Starting gunicorn for geomet-mapproxy"
# # startup cron jobs (refresh config, delete cache every night at midnight UTC)
# service cron start
# start gunicorn
gunicorn -w 2 -b 0.0.0.0:80 --chdir $BASEDIR/geomet_mapproxy wsgi:application --reload --timeout 900 --access-logfile $GUNICORN_GEOMET_MAPPROXY_ACCESSLOG --error-logfile $GUNICORN_GEOMET_MAPPROXY_ERRORLOG
