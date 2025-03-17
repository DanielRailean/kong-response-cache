# Kong Response Cache - `kong-proxy-cache-advanced` enterprise alternative

## Disclaimers

The plugin is based and improves on the [existing Kong Proxy cache plugin](https://github.com/Kong/kong/tree/master/kong/plugins/proxy-cache), which unfortunately only supports the memory strategy in the free tier.

Changes compared to the [default Kong Proxy Cache](https://github.com/Kong/kong/tree/master/kong/plugins/proxy-cache):

- Added `redis.lua` inside `strategies` folder
- Added `'redis'` as a strategy type on line 9 in `init.lua`
- Modified `schema.lua` to include Redis configuration parameters.
