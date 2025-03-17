# Dev Docs

## Start the images

### start Redis

```sh
docker run --name redis -p 6379:6379 -e ALLOW_EMPTY_PASSWORD=yes -d bitnami/redis:latest
```

### start Kong

Use export the environment variable for the folder containing the handler

```sh
export path_to_folder_containing_handler="."
```

```sh
docker run --add-host=host.docker.internal:host-gateway -d --name kong-redis \
  -e "KONG_DATABASE=off" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
  -e "KONG_PLUGINS=bundled,response-cache" \
  -e "KONG_ERROR_DEFAULT_TYPE=application/json" \
  -p 8000:8000 \
  -p 8443:8443 \
  -p 8001:8001 \
  -p 8444:8444 \
  -v $path_to_folder_containing_handler:/usr/local/share/lua/5.1/kong/plugins/response-cache \
  kong/kong
```
