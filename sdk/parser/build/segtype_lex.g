{
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
}