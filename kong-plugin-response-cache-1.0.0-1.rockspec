package = "kong-plugin-response-cache"
version = "1.0.0-1"
source = {
   url = "git+ssh://git@github.com/DanielRailean/kong-plugin-response-cache.git",
   tag = "1.0.0"
}
description = {
   detailed = "A Proxy Caching plugin for Kong",
   homepage = "https://github.com/DanielRailean/kong-plugin-response-cache",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.response-cache.access"] = "response-cache/access.lua",
      ["kong.plugins.response-cache.body_filter"] = "response-cache/body_filter.lua",
      ["kong.plugins.response-cache.cache"] = "response-cache/cache.lua",
      ["kong.plugins.response-cache.encoder"] = "response-cache/encoder.lua",
      ["kong.plugins.response-cache.handler"] = "response-cache/handler.lua",
      ["kong.plugins.response-cache.header_filter"] = "response-cache/header_filter.lua",
      ["kong.plugins.response-cache.schema"] = "response-cache/schema.lua",
      ["kong.plugins.response-cache.storage"] = "response-cache/storage.lua",
      ["kong.plugins.response-cache.validators"] = "response-cache/validators.lua"
   },
   dependencies = {
      "lua-resty-redis-connector == 0.11.0-0"
   }
}
