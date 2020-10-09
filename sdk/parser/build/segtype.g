{
    "lex": {
        "rules": [
            [
                "uint",
                "return 'UINT'"
            ],
            [
                "int",
                "return 'INT'"
            ],
            [
                "float",
                "return 'FLOAT'"
            ],
            [
                "double",
                "return 'DOUBLE'"
            ],
            [
                "string",
                "return 'STRING'"
            ],
            [
                "(6[0-4])|([1-5][0-9])|([1-9])",
                "return 'LEN'"
            ],
            [
                ">",
                "return '>'"
            ],
            [
                "<",
                "return '<'"
            ],
            [
                "!",
                "return '!'"
            ],
            [
                "&",
                "return '&'"
            ],
            [
                "=",
                "return '='"
            ],
            [
                "\\s+",
                ""
            ]
        ]
    },
    "bnf": {
        "segtype": [
            [
                "basetype",
                "$$ = $basetype;"
            ],
            [
                "basetype byteorder",
                "$basetype.order = $byteorder; $$=$basetype;"
            ],
            [
                "strtype",
                "$$ = $strtype;"
            ],
            [
                "strtype byteorder",
                "$strtype.order = $byteorder; $$=$strtype;"
            ],
            [
                "basetype encode",
                "$basetype.encode = $encode; $$=$basetype;"
            ],
            [
                "basetype byteorder encode",
                "$basetype.encode = $encode; $basetype.order = $byteorder; $$=$basetype;"
            ],
            [
                "basetype encode byteorder",
                "$basetype.encode = $encode; $basetype.order = $byteorder; $$=$basetype;"
            ]
        ],
        "basetype": [
            [
                "INT LEN",
                "$$ = {type: 'integer', bitcount: eval($LEN), signed: true}"
            ],
            [
                "UINT LEN",
                "$$ = {type: 'integer', bitcount: eval($LEN), signed: false}"
            ],
            [
                "FLOAT",
                "$$ = {type: 'float'}"
            ],
            [
                "DOUBLE",
                "$$ = {type: 'double'}"
            ]
        ],
        "strtype": [
            [
                "STRING",
                "$$ = {type: 'string'}"
            ]
        ],
        "byteorder": [
            [
                ">",
                "$$ = 'bigorder'"
            ],
            [
                "<",
                "$$ = 'smallorder'"
            ]
        ],
        "encode": [
            [
                "&",
                "$$ = 'complement'"
            ],
            [
                "!",
                "$$ = 'inversion'"
            ],
            [
                "=",
                "$$ = 'primitive'"
            ]
        ]
    }
}