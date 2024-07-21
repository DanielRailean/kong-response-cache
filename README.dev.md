# Dev docs

## Starting the docker containers

### Start the opentelemetry container (optional)

```sh
docker run --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:1.36
```

### Start the [Redict container](https://redict.io/)

```sh
docker run --name redict -d -p 6379:6379 registry.redict.io/redict
```

### Start Kong Oss Image

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
