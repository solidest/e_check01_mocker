{
    "startConditions": {
        "etl": 1,
        "lua": 1
    },
    "rules": [
        [
            [
                "etl"
            ],
            "\\/\\*[^*]*\\*+([^\\/][^*]*\\*+)*\\/",
            "/*return 'COMMENT_BLOCK'*/"
        ],
        [
            [
                "etl"
            ],
            "\\/\\/[^\\r\\n]*",
            "/*return 'COMMENT_LINE'*/"
        ],
        [
            [
                "lua"
            ],
            "--\\[\\[(.|\\r\\n|\\r|\\n)*\\]\\]",
            "/*return 'COMMENT_BLOCK'*/"
        ],
        [
            [
                "lua"
            ],
            "--[^\\n]*",
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
            "local",
            "return 'LOCAL'"
        ],
        [
            "require",
            "return 'REQUIRE'"
        ],
        [
            "[a-zA-Z_][a-zA-Z0-9_]*",
            "return 'ID'"
        ],
        [
            "<%lua",
            "this.pushState('lua'); return 'BLOCK_BEGIN_LUA'"
        ],
        [
            "<%",
            "this.pushState('etl'); return 'BLOCK_BEGIN_ETL'"
        ],
        [
            [
                "lua",
                "etl"
            ],
            "%>",
            "this.popState(); return 'BLOCK_END'"
        ],
        [
            "=",
            "return '='"
        ],
        [
            "\\(",
            "return '('"
        ],
        [
            "\\)",
            "return ')'"
        ],
        [
            [
                "*"
            ],
            "\\r\\n",
            "/*return 'NEWLINE'*/"
        ],
        [
            [
                "*"
            ],
            "\\n",
            "/*return 'NEWLINE'*/"
        ],
        [
            [
                "*"
            ],
            ".",
            "/*return 'ANY_OTHER'*/"
        ]
    ]
}