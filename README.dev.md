# Dev docs

## Starting the docker container

```sh
  docker run -d --name kong-cache \
    -e "KONG_DATABASE=off" \
    -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
    -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
    -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
    -e "KONG_PLUGINS=bundled,response-cache" \
    -e "KONG_ERROR_DEFAULT_TYPE=application/json" \
    -e "KONG_PLUGIN_PRIORITY_JWT_OIDC_VALIDATE=1060" \
    -e 'KONG_TRACING_INSTRUMENTATIONS=all' \
    -e 'KONG_TRACING_SAMPLING_RATE=1' \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 8444:8444 \
    -v path_containing_the_handler:/usr/local/share/lua/5.1/kong/plugins/response-cache \
    --add-host=host.docker.internal:host-gateway \
    kong-cache
```
