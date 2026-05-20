FROM nginx:alpine

RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf

RUN echo '<h1>DispatchIQ placeholder — Phase 3 compute layer healthy</h1>' > /usr/share/nginx/html/index.html

EXPOSE 8080
