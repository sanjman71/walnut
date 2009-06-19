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

  location ~* \.(ico|css|js|gif|jp?g|png)(\?[0-9]+)?$ {
    expires max;
    break;
  }

  # This rewrites all the requests to the maintenance.html page if it exists in the doc root.
  # This is for capistrano's disable web task.
  error_page   500 502 504  /500.html;
  error_page   503 /system/maintenance.html;
  location /system/maintenance.html {
    # Allow requests
  }

  location / {
    if (-f $document_root/system/maintenance.html) {
      return 503;
    }
  }

}
