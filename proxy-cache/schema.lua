local typedefs = require "kong.db.schema.typedefs"

return {
    name = "response-cache",
    fields = {
        { protocols = typedefs.protocols },
        {
            config = {
                type = "record",
                fields = {
                    {
                        redis = {
                            type = "record",
                            fields = {
                                -- most of the filds go directly to the redis module
                                -- https://github.com/ledgetech/lua-resty-redis-connector?tab=readme-ov-file#default-parameters
                                { host = { type = "string", required = false } },
                                { sentinel_master_name = { type = "string", required = false } },
                                { sentinel_role = { type = "string", required = false, default = "master" } },
                                {
                                    sentinel_addresses = {
                                        type = "array",
                                        elements = { type = "string" },
                                        required = false
                                    }
                                },
                                {
                                    port = {
                                        type = "number",
                                        default = 6379,
                                        between = { 0, 65534 },
                                        required = true
                                    }
                                },
                                {
                                    circuit_breaker = {
                                        type = "record",
                                        fields = {
                                            {
                                                enabled = {
                                                    type = "boolean",
                                                    required = true,
                                                    default = true
                                                }
                                            },
                                            {
                                                fails_threshold = {
                                                    type = "number",
                                                    default = 10,
                                                    between = { 1, 1000 }
                                                }
                                            },
                                            {
                                                ttl = {
                                                    type = "number",
                                                    default = 60,
                                                    between = { 1, 24 * 60 * 60 }
                                                }
                                            }
                                        }
                                    }
                                },
                                {
                                    ssl = {
                                        type = "record",
                                        fields = {
                                            {
                                                enabled = {
                                                    type = "boolean",
                                                    required = true
                                                }
                                            },
                                            {
                                                verify = {
                                                    type = "boolean",
                                                    required = true
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
                                                    default = 200,
                                                    between = { 1, 5000 }
                                                }
                                            },
                                            {
                                                read = {
                                                    type = "number",
                                                    default = 100,
                                                    between = { 1, 5000 }
                                                }
                                            },
                                            {
                                                send = {
                                                    type = "number",
                                                    default = 100,
                                                    between = { 1, 5000 }
                                                }
                                            }
                                        }
                                    }
                                },
                                { password = { type = "string", required = false } },
                                { username = { type = "string", required = false } },
                                { database = { type = "number", required = true, default = 0 } },
                                { max_idle_timeout = { type = "number", required = true, default = 20000 } },
                                { pool_size = { type = "number", required = true, default = 1000 } }
                            }
                        }
                    },
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
                            description =
                            "Caching related diagnostic headers that should be included in cached responses",
                            type = "record",
                            fields = {
                                { ["Age"] = { type = "boolean", default = true } },
                                { ["X-Cache-Status"] = { type = "boolean", default = true } },
                                { ["X-Cache-Key"] = { type = "boolean", default = true } },
                            },
                        }
                    },
                },
            }
        },
    },

    entity_checks = {
        {

        }
    },
}
