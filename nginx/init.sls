nginx:
  pkg.installed

/etc/nginx/conf.d/java-app.conf:
  file.managed:
    - source: salt://nginx/java-app.conf

nginx.service:
  service.running:
    - watch:
      - file: /etc/nginx/conf.d/java-app.conf
