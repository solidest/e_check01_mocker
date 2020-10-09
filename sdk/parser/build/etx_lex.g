{
    "startConditions": {
        "protocol": 1,
        "device": 1,
        "topology": 1
    },
    "rules": [
        [
            [
                "*"
            ],
            "\\/\\*[^*]*\\*+([^\\/][^*]*\\*+)*\\/",
            "/*return 'COMMENT_BLOCK'*/"
        ],
        [
            [
                "*"
            ],
            "\\/\\/[^\\r\\n]*",
            "/*return 'COMMENT_LINE'*/"
        ],
        [
            [
                "*"
            ],
            "\\\"([^\\\\\\n\"]|\\\\.)*\\\"",
            "return 'STRING_TRIPLE'"
        ],
        [
            [
                "*"
            ],
            "'([^\\\\\\n']|\\\\.)*'",
            "return 'STRING_SINGLE'"
        ],
        [
            [
                "*"
            ],
            "%[0-9A-Fa-f\\s]*%",
            "return 'STRING_HEX'"
        ],
        [
            [
                "*"
            ],
            "\\s+",
            "/* return 'WHITESPACE' */"
        ],
        [
            [
                "*"
            ],
            "\\n",
            "/* return 'NEWLINE' */"
        ],
        [
            [
                "*"
            ],
            "\\bbitlr\\b",
            "return 'BITLR' "
        ],
        [
            [
                "*"
            ],
            "\\bbitrl\\b",
            "return 'BITRL' "
        ],
        [
            [
                "*"
            ],
            "\\bprotocol\\b",
            "if(this.getCurrentState()!=='INITIAL') this.popState(); this.pushState('protocol'); return 'PROTOCOL';"
        ],
        [
            [
                "protocol"
            ],
            "\\bsegments\\b",
            "return 'SEGMENTS'"
        ],
        [
            [
                "protocol"
            ],
            "\\bsegment\\b",
            "return 'SEGMENT'"
        ],
        [
            [
                "protocol"
            ],
            "\\boneof\\b",
            "return 'ONEOF'"
        ],
        [
            [
                "*"
            ],
            "\\bdevice\\b",
            "if(this.getCurrentState()!=='INITIAL') this.popState(); this.pushState('device'); return 'DEVICE';"
        ],
        [
            [
                "device"
            ],
            "\\b(udp|tcp_server|tcp_client|serial_ttl|serial_232|serial_422|serial_485|serial_usb|can|di|do|ad|da)\\b",
            "return 'INTFTYPE'"
        ],
        [
            [
                "*"
            ],
            "\\btopology\\b",
            "if(this.getCurrentState()!=='INITIAL') this.popState(); this.pushState('topology'); return 'TOPOLOGY';"
        ],
        [
            [
                "topology"
            ],
            "\\blinking\\b",
            "return 'LINKING'"
        ],
        [
            [
                "topology"
            ],
            "\\bmapping\\b",
            "return 'MAPPING'"
        ],
        [
            [
                "topology"
            ],
            "\\bbinding\\b",
            "return 'BINDING'"
        ],
        [
            [
                "topology"
            ],
            "\\buut\\b",
            "return 'UUT'"
        ],
        [
            [
                "topology"
            ],
            "\\betest\\b",
            "return 'ETEST'"
        ],
        [
            [
                "*"
            ],
            "true",
            "return 'TRUE'"
        ],
        [
            [
                "*"
            ],
            "false",
            "return 'FALSE'"
        ],
        [
            [
                "*"
            ],
            "and",
            "return 'AND'"
        ],
        [
            [
                "*"
            ],
            "or",
            "return 'OR'"
        ],
        [
            [
                "*"
            ],
            "not",
            "return 'NOT'"
        ],
        [
            [
                "*"
            ],
            "0[xX][0-9a-fA-F]+",
            "return 'NUMBER_HEX'"
        ],
        [
            [
                "*"
            ],
            "[0-9]+(?:\\.[0-9]+)?",
            "return 'NUMBER'"
        ],
        [
            [
                "*"
            ],
            "[a-zA-Z_$][a-zA-Z0-9_]*",
            "return 'ID'"
        ],
        [
            [
                "*"
            ],
            "~=",
            "return 'NOT_EQ'"
        ],
        [
            [
                "*"
            ],
            "==",
            "return 'EQ_EQ'"
        ],
        [
            [
                "*"
            ],
            ">=",
            "return 'GT_EQ'"
        ],
        [
            [
                "*"
            ],
            "<=",
            "return 'LT_EQ'"
        ],
        [
            [
                "*"
            ],
            "{",
            "return '{'"
        ],
        [
            [
                "*"
            ],
            "}",
            "return '}'"
        ],
        [
            [
                "*"
            ],
            "]",
            "return ']'"
        ],
        [
            [
                "*"
            ],
            "\\[",
            "return '['"
        ],
        [
            [
                "*"
            ],
            ",",
            "return ','"
        ],
        [
            [
                "*"
            ],
            "\\:",
            "return ':'"
        ],
        [
            [
                "*"
            ],
            "\\.",
            "return 'DOT'"
        ],
        [
            [
                "*"
            ],
            "\\+",
            "return '+'"
        ],
        [
            [
                "*"
            ],
            "-",
            "return '-'"
        ],
        [
            [
                "*"
            ],
            "\\*",
            "return '*'"
        ],
        [
            [
                "*"
            ],
            "\\/",
            "return '/'"
        ],
        [
            [
                "*"
            ],
            "\\(",
            "return '('"
        ],
        [
            [
                "*"
            ],
            "\\)",
            "return ')'"
        ],
        [
            [
                "*"
            ],
            ">",
            "return '>'"
        ],
        [
            [
                "*"
            ],
            "<",
            "return '<'"
        ]
    ]
}