#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
use t::APISIX 'no_plan';

repeat_each(1);
no_long_string();
no_root_location();
no_shuffle();
log_level("info");

run_tests;

__DATA__

=== TEST 1: set upstream(id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                ngx.HTTP_PUT,
                [[{
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin",
                    "desc": "new upstream"
                }]],
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8080": 1
                            },
                            "type": "roundrobin",
                            "desc": "new upstream"
                        },
                        "key": "/apisix/upstreams/1"
                    },
                    "action": "set"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 2: get upstream(id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_GET,
                 nil,
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8080": 1
                            },
                            "type": "roundrobin",
                            "desc": "new upstream"
                        },
                        "key": "/apisix/upstreams/1"
                    },
                    "action": "get"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 3: delete upstream(id: 1)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, message = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_DELETE,
                 nil,
                 [[{
                    "action": "delete"
                }]]
                )
            ngx.say("[delete] code: ", code, " message: ", message)
        }
    }
--- request
GET /t
--- response_body
[delete] code: 200 message: passed
--- no_error_log
[error]



=== TEST 4: delete upstream(id: not_found)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code = t('/apisix/admin/upstreams/not_found',
                 ngx.HTTP_DELETE,
                 nil,
                 [[{
                    "action": "delete"
                }]]
                )

            ngx.say("[delete] code: ", code)
        }
    }
--- request
GET /t
--- response_body
[delete] code: 404
--- no_error_log
[error]



=== TEST 5: push upstream + delete
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, message, res = t('/apisix/admin/upstreams',
                 ngx.HTTP_POST,
                 [[{
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]],
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8080": 1
                            },
                            "type": "roundrobin"
                        }
                    },
                    "action": "create"
                }]]
                )

            if code ~= 200 then
                ngx.status = code
                ngx.say(message)
                return
            end

            ngx.say("[push] code: ", code, " message: ", message)

            local id = string.sub(res.node.key, #"/apisix/upstreams/" + 1)
            code, message = t('/apisix/admin/upstreams/' .. id,
                 ngx.HTTP_DELETE,
                 nil,
                 [[{
                    "action": "delete"
                }]]
                )
            ngx.say("[delete] code: ", code, " message: ", message)
        }
    }
--- request
GET /t
--- response_body
[push] code: 200 message: passed
[delete] code: 200 message: passed
--- no_error_log
[error]



=== TEST 6: empty nodes
--- config
    location /t {
        content_by_lua_block {
            local core = require("apisix.core")
            local t = require("lib.test_admin").test
            local code, message, res = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "nodes": {},
                    "type": "roundrobin"
                }]]
                )

            if code ~= 200 then
                ngx.status = code
                ngx.print(message)
                return
            end

            ngx.say("[push] code: ", code, " message: ", message)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"nodes\" validation failed: expect object to have at least 1 properties"}



=== TEST 7: invalid upstream id in uri
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/invalid_id',
                 ngx.HTTP_PUT,
                 [[{
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]]
                )

            ngx.exit(code)
        }
    }
--- request
GET /t
--- error_code: 400
--- no_error_log
[error]



=== TEST 8: different id
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "id": 3,
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"wrong upstream id"}
--- no_error_log
[error]



=== TEST 9: id in the rule
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_PUT,
                 [[{
                    "id": "1",
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]],
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8080": 1
                            },
                            "type": "roundrobin"
                        },
                        "key": "/apisix/upstreams/1"
                    },
                    "action": "set"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 10: integer id less than 1
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_PUT,
                 [[{
                    "id": -100,
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"id\" validation failed: object matches none of the alternatives"}
--- no_error_log
[error]



=== TEST 11: invalid upstream id: string value
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_PUT,
                 [[{
                    "id": "invalid_id",
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"id\" validation failed: object matches none of the alternatives"}
--- no_error_log
[error]



=== TEST 12: no additional properties is valid
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_PUT,
                 [[{
                    "id": 1,
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin",
                    "invalid_property": "/index.html"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: additional properties forbidden, found invalid_property"}
--- no_error_log
[error]



=== TEST 13: set upstream(type: chash)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "key": "remote_addr",
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "chash"
                }]],
                [[{
                    "node": {
                        "value": {
                            "key": "remote_addr",
                            "nodes": {
                                "127.0.0.1:8080": 1
                            },
                            "type": "chash"
                        },
                        "key": "/apisix/upstreams/1"
                    },
                    "action": "set"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 14: invalid type
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_PUT,
                 [[{
                    "id": 1,
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "invalid_type"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"type\" validation failed: matches non of the enum values"}
--- no_error_log
[error]



=== TEST 15: invalid weight of node
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_PUT,
                 [[{
                    "id": 1,
                    "nodes": {
                        "127.0.0.1:8080": "1"
                    },
                    "type": "chash"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"nodes\" validation failed: failed to validate 127.0.0.1:8080 (matching \".*\"): wrong type: expected integer, got string"}
--- no_error_log
[error]



=== TEST 16: invalid weight of node
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_PUT,
                 [[{
                    "id": 1,
                    "nodes": {
                        "127.0.0.1:8080": -100
                    },
                    "type": "chash"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"nodes\" validation failed: failed to validate 127.0.0.1:8080 (matching \".*\"): expected -100 to be greater than 0"}
--- no_error_log
[error]



=== TEST 17: set upstream (missing key)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "chash"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"missing key"}
--- no_error_log
[error]



=== TEST 18: wrong upstream id, do not need it
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_POST,
                 [[{
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"wrong upstream id, do not need it"}
--- no_error_log
[error]



=== TEST 19: wrong upstream id, do not need it
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams',
                 ngx.HTTP_POST,
                 [[{
                    "id": 1,
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"wrong upstream id, do not need it"}
--- no_error_log
[error]



=== TEST 20: patch upstream(whole)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1/',
                ngx.HTTP_PATCH,
                [[{
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "roundrobin",
                    "desc": "new upstream"
                }]],
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8080": 1
                            },
                            "type": "roundrobin",
                            "desc": "new upstream"
                        },
                        "key": "/apisix/upstreams/1"
                    },
                    "action": "set"
                }]]
            )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 21: patch upstream(new desc)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1/desc',
                ngx.HTTP_PATCH,
                '"new 21 upstream"',
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8080": 1
                            },
                            "type": "roundrobin",
                            "desc": "new 21 upstream"
                        },
                        "key": "/apisix/upstreams/1"
                    },
                    "action": "set"
                }]]
            )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 22: patch upstream(new nodes)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1/nodes',
                ngx.HTTP_PATCH,
                [[{
                    "127.0.0.1:8081": 3,
                    "127.0.0.1:8082": 4
                }]],
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8081": 3,
                                "127.0.0.1:8082": 4
                            },
                            "type": "roundrobin",
                            "desc": "new 21 upstream"
                        }
                    }
                }]]
            )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 23: patch upstream(weight is 0)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1/nodes',
                ngx.HTTP_PATCH,
                [[{
                    "127.0.0.1:8081": 0,
                    "127.0.0.1:8082": 4
                }]],
                [[{
                    "node": {
                        "value": {
                            "nodes": {
                                "127.0.0.1:8081": 0,
                                "127.0.0.1:8082": 4
                            },
                            "type": "roundrobin",
                            "desc": "new 21 upstream"
                        }
                    }
                }]]
            )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 24: set upstream(type: chash)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "key": "server_name",
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "chash"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 25:  wrong upstream key
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                ngx.HTTP_PUT,
                [[{
                    "nodes": {
                        "127.0.0.1:8080": 1,
                        "127.0.0.1:8081": 2
                    },
                    "type": "chash",
                    "key": "not_support",
                    "desc": "new upstream"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"key\" validation failed: failed to match pattern \"^((uri|server_name|server_addr|request_uri|remote_port|remote_addr|query_string|host|hostname)|arg_[0-9a-zA-z_-]+)$\" with \"not_support\""}
--- no_error_log
[error]



=== TEST 24: set upstream with args(type: chash)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "key": "arg_device_id",
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "chash",
                    "desc": "new chash upstream"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 24: set upstream(type: chash)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "key": "server_name",
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "chash"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]



=== TEST 25:  wrong upstream key
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                ngx.HTTP_PUT,
                [[{
                    "nodes": {
                        "127.0.0.1:8080": 1,
                        "127.0.0.1:8081": 2
                    },
                    "type": "chash",
                    "key": "not_support",
                    "desc": "new upstream"
                }]]
                )

            ngx.status = code
            ngx.print(body)
        }
    }
--- request
GET /t
--- error_code: 400
--- response_body
{"error_msg":"invalid configuration: property \"key\" validation failed: failed to match pattern \"^((uri|server_name|server_addr|request_uri|remote_port|remote_addr|query_string|host|hostname)|arg_[0-9a-zA-z_-]+)$\" with \"not_support\""}
--- no_error_log
[error]



=== TEST 24: set upstream with args(type: chash)
--- config
    location /t {
        content_by_lua_block {
            local t = require("lib.test_admin").test
            local code, body = t('/apisix/admin/upstreams/1',
                 ngx.HTTP_PUT,
                 [[{
                    "key": "arg_device_id",
                    "nodes": {
                        "127.0.0.1:8080": 1
                    },
                    "type": "chash",
                    "desc": "new chash upstream"
                }]]
                )

            ngx.status = code
            ngx.say(body)
        }
    }
--- request
GET /t
--- response_body
passed
--- no_error_log
[error]
