# Redirect walnutplaces.com to www.walnutplaces.com
server {
  listen          80;
  server_name     walnutplaces.com;
  rewrite ^/(.*)  http://www.walnutplaces.com/$1 permanent;
}

server {
  listen      80;
  server_name *.walnutplaces.com;

  # passenger options
  passenger_enabled on;    	
  rails_env production;

  access_log  /usr/apps/walnut/current/log/access.log;
  error_log   /usr/apps/walnut/current/log/error.log;

  root        /usr/apps/walnut/current/public/;
}
