docker run --name nginx-modsecurity \
  --restart=always \
  --net=host \
  -v $PWD/data/nginx/conf.d:/etc/nginx/conf.d:rw \
  -p 80:80 -p 443:443 -d \
  alexohneander/nginx-waf
