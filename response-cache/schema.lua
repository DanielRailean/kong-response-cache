local strategies = require "kong.plugins.response-cache.strategies_init"
local typedefs = require "kong.db.schema.typedefs"
local ngx = ngx


local function check_shdict(name)
  if not ngx.shared[name] then
    return false, "missing shared dict '" .. name .. "'"
  end

  return true
end

return {
  name = "response-cache",
  fields = {
    { protocols = typedefs.protocols },
    {
      config = {
        type = "record",
        fields = {
          {
            response_code = {
              description = "Upstream response status code considered cacheable.",
              type = "array",
              default = { 200, 301, 404 },
              elements = { type = "integer", between = { 100, 900 } },
              len_min = 1,
              required = true,
            }
          },
          {
            request_method = {
              description = "Downstream request methods considered cacheable.",
              type = "array",
              default = { "GET", "HEAD" },
              elements = {
                type = "string",
                one_of = { "HEAD", "GET", "POST", "PATCH", "PUT" },
              },
              required = true
            }
          },
          {
            content_type = {
              description =
              "Upstream response content types considered cacheable. The plugin performs an **exact match** against each specified value.",
              type = "array",
              default = { "text/plain", "application/json" },
              elements = { type = "string" },
              required = true,
            }
          },
          {
            cache_ttl = {
              description = "TTL, in seconds, of cache entities.",
              type = "integer",
              default = 300,
              gt = 0,
            }
          },
          {
            strategy = {
              description = "The backing data store in which to hold cache entities.",
              type = "string",
              one_of = strategies.STRATEGY_TYPES,
              required = true,
            }
          },
          {
            cache_control = {
              description = "When enabled, respect the Cache-Control behaviors defined in RFC7234.",
              type = "boolean",
              default = false,
              required = true,
            }
          },
          {
            ignore_uri_case = {
              type = "boolean",
              default = false,
              required = false,
            }
          },
          {
            storage_ttl = {
              description =
              "Number of seconds to keep resources in the storage backend. This value is independent of `cache_ttl` or resource TTLs defined by Cache-Control behaviors.",
              type =
              "integer",
            }
          },
          {
            memory = {
              type = "record",
              fields = {
                {
                  dictionary_name = {
                    description =
                    "The name of the shared dictionary in which to hold cache entities when the memory strategy is selected. Note that this dictionary currently must be defined manually in the Kong Nginx template.",
                    type = "string",
                    required = true,
                    default = "kong_db_cache",
                  }
                },
              },
            }
          },
          {
            vary_query_params = {
              description =
              "Relevant query parameters considered for the cache key. If undefined, all params are taken into consideration.",
              type = "array",
              elements = { type = "string" },
            }
          },
          {
            vary_headers = {
              description =
              "Relevant headers considered for the cache key. If undefined, none of the headers are taken into consideration.",
              type = "array",
              elements = { type = "string" },
            }
          },
          {
            response_headers = {
              description = "Caching related diagnostic headers that should be included in cached responses",
              type = "record",
              fields = {
                { age = { type = "boolean", default = true } },
                { ["X-Cache-Status"] = { type = "boolean", default = true } },
                { ["X-Cache-Key"] = { type = "boolean", default = true } },
              },
            }
          },
          -- present in proxy cache advanced, might be added later
          -- {
          --   bypass_on_err = {
          --     description = "When enabled, the request will be served by the upstream if caching fails.",
          --     type = "boolean",
          --     default = true,
          --     required = true,
          --   }
          -- },
          {
            redis =
            -- the base for the config is fetched from
            -- https://github.com/Kong/kong/blob/master/kong/tools/redis/schema.lua
            {
              type = "record",
              description = "Redis configuration",
              fields = {
                { host = typedefs.host },
                { port = typedefs.port({ default = 6379 }), },
                {
                  log_level = {
                    description = "log level for non error messages",
                    type = "string",
                    required = true,
                    default = "debug"
                  }
                },
                {
                  -- value is in ms
                  idle_timeout_ms = {
                    type = "number",
                    required = true,
                    -- defaults to 30s
                    default = 30 * 1000,
                    -- between 1s and 5m
                    between = { 1, 5 * 60 * 1000 }
                  }
                },
                {
                  pool_size = {
                    type = "number",
                    required = true,
                    default = 128,
                    between = { 1, 2048 }
                  }
                },
                {
                  tls = {
                    type = "record",
                    fields = {
                      {
                        enabled = {
                          type = "boolean",
                          required = false
                        }
                      },
                      {
                        verify = {
                          type = "boolean",
                          required = false
                        }
                      },
                      {
                        server_name = {
                          type = "string",
                          required = false
                        }
                      }
                    }
                  }
                },
                {
                  timeout = {
                    type = "record",
                    fields = {
                      {
                        connect = {
                          type = "number",
                          default = 50,
                          required = true,
                          between = { 1, 5000 }
                        }
                      },
                      {
                        read = {
                          type = "number",
                          default = 50,
                          required = true,
                          between = { 1, 5000 }
                        }
                      },
                      {
                        send = {
                          type = "number",
                          default = 50,
                          required = true,
                          between = { 1, 5000 }
                        }
                      }
                    }
                  }
                },
                {
                  username = {
                    description =
                    "Username to use for Redis connections. If undefined, ACL authentication won't be performed. This requires Redis v6.0.0+. To be compatible with Redis v5.x.y, you can set it to `default`.",
                    type = "string",
                    referenceable = true
                  }
                },
                {
                  password = {
                    description =
                    "Password to use for Redis connections. If undefined, no AUTH commands are sent to Redis.",
                    type = "string",
                    encrypted = true,
                    referenceable = true,
                    len_min = 0
                  }
                },
                {
                  database = {
                    description = "Database to use for the Redis connection when using the `redis` strategy",
                    type = "integer",
                    default = 0
                  }
                },
                -- to be readded later
                -- {
                --   circuit_breaker = {
                --     type = "record",
                --     fields = {
                --       {
                --         enabled = {
                --           type = "boolean",
                --           required = true,
                --           default = true
                --         }
                --       },
                --       {
                --         fails_threshold = {
                --           type = "number",
                --           default = 10,
                --           between = { 1, 1000 }
                --         }
                --       },
                --       {
                --         ttl = {
                --           type = "number",
                --           default = 60,
                --           between = { 1, 24 * 60 * 60 }
                --         }
                --       }
                --     }
                --   }
                -- },
              }
            }
          },
        },
      }
    },
  },

  entity_checks = {
    {
      custom_entity_check = {
        field_sources = { "config" },
        fn = function(entity)
          local config = entity.config

          if config.strategy == "memory" then
            local ok, err = check_shdict(config.memory.dictionary_name)
            if not ok then
              return nil, err
            end
          end

          return true
        end
      }
    },
  },
}
