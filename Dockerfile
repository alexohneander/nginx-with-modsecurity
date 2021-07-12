FROM debian:bullseye-slim

RUN apt update && apt upgrade -y
RUN apt install -y apt-utils autoconf nginx automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev

# clone & compile ModSecurity from git
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
RUN cd ModSecurity && \
      git submodule init && \
      git submodule update && \
      ./build.sh && \
      ./configure && \
       make && \
       make install && \
       cd ..

# clone & compile nginx-connector from git
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

# Download NGINX and compile it with ModSecurity
RUN wget http://nginx.org/download/nginx-1.18.0.tar.gz && \
      tar zxvf nginx-1.18.0.tar.gz

RUN cd nginx-1.18.0 && \
      ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
      make modules && \
      mkdir /etc/nginx/modules/ && \
      cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/ && \
      cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/ngx_http_modsecurity_module.so && \
      cd ..

# Copy Custom NGINX conf
COPY nginx.conf /etc/nginx/nginx.conf

# Configure and Enable ModSecurity
RUN mkdir /etc/nginx/modsec && \
      wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended && \
      mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf && \
      cp ModSecurity/unicode.mapping /etc/nginx/modsec && \
      sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

# Copy ModSecurity Rule Set
COPY main.conf /etc/nginx/modsec/main.conf

# Download and install CoreRuleSet
RUN mkdir /opt/rules && cd /opt/rules && \
      wget https://github.com/coreruleset/coreruleset/archive/v3.3.2.tar.gz && \
      tar -xvzf v3.3.2.tar.gz && \
      ln -s coreruleset-3.3.2 /opt/rules/crs && \
      cp crs/crs-setup.conf.example crs/crs-setup.conf && \
      cd /

# Test Site
RUN cp /var/www/html/index.nginx-debian.html /var/www/html/index.html

COPY crs-setup.conf /opt/rules/crs/crs-setup.conf

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]