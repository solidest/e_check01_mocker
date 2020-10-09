{
    "lex": {
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
    },
    "operators": [
        [
            "left",
            "AND",
            "OR"
        ],
        [
            "left",
            ">",
            "<",
            "GT_EQ",
            "LT_EQ",
            "EQ_EQ",
            "NOT_EQ"
        ],
        [
            "left",
            "+",
            "-"
        ],
        [
            "left",
            "*",
            "/"
        ],
        [
            "left",
            "UMINUS",
            "NOT"
        ]
    ],
    "bnf": {
        "exp": [
            [
                "literal",
                "$$ = $literal;"
            ],
            [
                "object_like",
                "$$ = $object_like;"
            ],
            [
                "NOT exp",
                "$$ = {kind: 'not', exp: $exp};"
            ],
            [
                "- exp",
                "$$ = {kind: 'uminus', exp: $exp};",
                {
                    "prec": "UMINUS"
                }
            ],
            [
                "exp NOT_EQ exp",
                "$$ = {kind: 'not_eq', left: $1, right: $3};"
            ],
            [
                "exp EQ_EQ exp",
                "$$ = {kind: 'eq_eq', left: $1, right: $3};"
            ],
            [
                "exp GT_EQ exp",
                "$$ = {kind: 'gt_eq', left: $1, right: $3};"
            ],
            [
                "exp LT_EQ exp",
                "$$ = {kind: 'lt_eq', left: $1, right: $3};"
            ],
            [
                "exp > exp",
                "$$ = {kind: 'gt', left: $1, right: $3};"
            ],
            [
                "exp < exp",
                "$$ = {kind: 'lt', left: $1, right: $3};"
            ],
            [
                "exp + exp",
                "$$ = {kind: 'add', left: $1, right: $3};"
            ],
            [
                "exp - exp",
                "$$ = {kind: 'subtract', left: $1, right: $3};"
            ],
            [
                "exp * exp",
                "$$ = {kind: 'multiply', left: $1, right: $3};"
            ],
            [
                "exp / exp",
                "$$ = {kind: 'divide', left: $1, right: $3};"
            ],
            [
                "exp AND exp",
                "$$ = {kind: 'and', left: $1, right: $3};"
            ],
            [
                "exp OR exp",
                "$$ = {kind: 'or', left: $1, right: $3};"
            ],
            [
                "( exp )",
                "$$ = $exp;"
            ],
            [
                "[ ]",
                "$$ = newKindList('array', null);"
            ],
            [
                "[ arrlist ]",
                "$$ = $arrlist;"
            ],
            [
                "gfn_call",
                "$$ = $gfn_call;"
            ]
        ],
        "gfn_call": [
            [
                "ID ( )",
                "$$ = { kind: $ID };"
            ],
            [
                "ID ( paramlist )",
                "$$ = {kind: $ID, params: $paramlist};"
            ]
        ],
        "paramlist": [
            [
                "exp",
                "$$ = newList($exp);"
            ],
            [
                "paramlist , exp",
                "$$ = joinList($paramlist, $exp);"
            ],
            [
                "paramlist ,",
                "$$ = $paramlist;"
            ]
        ],
        "arrlist": [
            [
                "exp",
                "$$ = newKindList('array', $exp);"
            ],
            [
                "arrlist , exp",
                "$$ = joinKindList($arrlist, $exp);"
            ],
            [
                "arrlist ,",
                "$$ = $arrlist;"
            ]
        ],
        "literal": [
            [
                "NUMBER",
                "$$ = {kind: 'number', value: eval(yytext)};"
            ],
            [
                "NUMBER_HEX",
                "$$ = {kind: 'number', value: eval(yytext)};"
            ],
            [
                "str",
                "$$ = $str;"
            ],
            [
                "pid",
                "$$ = $pid;"
            ],
            [
                "TRUE",
                "$$ = {kind: 'bool', value: true};"
            ],
            [
                "FALSE",
                "$$ = {kind: 'bool', value: false};"
            ]
        ],
        "pid": [
            [
                "ID",
                "$$ = newKindList('pid', $1);"
            ],
            [
                "pid DOT ID",
                "$$ = joinKindList($pid, $ID);"
            ]
        ],
        "str": [
            [
                "STRING_TRIPLE",
                "$$ = {kind: 'string', value: eval(yytext)};"
            ],
            [
                "STRING_SINGLE",
                "$$ = {kind: 'string', value: eval(yytext)};"
            ],
            [
                "STRING_HEX",
                "$$ = {kind: 'strhex',  value: yytext.replace(/%/g, '')};"
            ]
        ],
        "object_like": [
            [
                "{ }",
                "$$ = newList(null);"
            ],
            [
                "{ property_list }",
                "$$ = $property_list;"
            ]
        ],
        "property_list": [
            [
                "property_setting",
                "$$ = newList($property_setting);"
            ],
            [
                "property_list , property_setting",
                "$$ = joinList($property_list, $property_setting);"
            ],
            [
                "property_list ,",
                "$$ = $property_list;"
            ]
        ],
        "property_setting": [
            [
                "ID : exp",
                "$$ = newProp($ID, $exp, @ID, @exp);"
            ]
        ]
    },
    "moduleInclude": "\n\n    function newList(item) {\n      if(item) {\n        return [item];\n      } else {\n        return [];\n      }\n    }\n\n    function joinList(list, item) {\n      if(list && item) {\n        list.push(item);\n      }\n      return list;\n    }\n\n    function newKindList(kind, item) {\n      if(item) {\n        return {kind: kind, list: [item]};\n      } else {\n        return {kind: kind, list: []};\n      }\n    }\n\n    function joinKindList(list, item) {\n      if(list && list.list && item) {\n        list.list.push(item);\n      }\n      return list;\n    }\n\n    function newProp(id, exp, id_loc, exp_loc) {\n      return {\n        kind: 'prop',\n        name: id,\n        value: exp,\n        name_from: id_loc.startOffset,\n        name_to: id_loc.endOffset,\n        name_line: id_loc.startLine,\n        value_from: exp_loc.startOffset,\n        value_to: exp_loc.endOffset,\n        value_line: exp_loc.startLine,\n      }\n    }\n\n    function newProtBranch(kind, exp, seglist, exp_loc) {\n      return {\n        kind: kind,\n        exp: exp,\n        seglist: seglist,\n        exp_from: exp_loc.startOffset,\n        exp_to: exp_loc.endOffset,\n        exp_line: exp_loc.startLine,\n      }\n    }\n\n    function newProtSeggroup(name, seglist, name_loc, repeated) {\n      let res = {\n        kind: 'seggroup',\n        name: name,\n        seglist: seglist,\n        name_from: name_loc.startOffset,\n        name_to: name_loc.endOffset,\n        name_line: name_loc.startLine,\n      }\n      if(repeated) {\n        res.repeated = repeated;\n      }\n      return res;\n    }\n\n    function newElement(kind, name, body_name, body, name_loc, repeated) {\n      let res = {\n        kind: kind,\n        name: name,\n        name_from: name_loc.startOffset,\n        name_to: name_loc.endOffset,\n        name_line: name_loc.startLine,\n      }\n      res[body_name] = body;\n      if(repeated) {\n        res.repeated = repeated;\n      }\n      return res;\n    }\n\n\n"
}