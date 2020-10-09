const fs = require("fs");
const path = require("path");

// ETL ////////////////////////////////////////////////////////////////////////////
let etl_main = {
  startConditions: {
    etl: 1,
    lua: 1
  },
  rules: [
    [["etl"], "\\/\\*[^*]*\\*+([^\\/][^*]*\\*+)*\\/", "/*return 'COMMENT_BLOCK'*/"],
    [["etl"], "\\/\\/[^\\r\\n]*", "/*return 'COMMENT_LINE'*/"],
    [["lua"], "--\\[\\[(.|\\r\\n|\\r|\\n)*\\]\\]", "/*return 'COMMENT_BLOCK'*/"],
    [["lua"], "--[^\\n]*", "/*return 'COMMENT_LINE'*/"],
    [["*"], "\\\"([^\\\\\\n\"]|\\\\.)*\\\"", "return 'STRING_TRIPLE'"],
    [["*"], "'([^\\\\\\n']|\\\\.)*'", "return 'STRING_SINGLE'"],
    ["local", "return 'LOCAL'"],
    ["require", "return 'REQUIRE'"],
    ["[a-zA-Z_][a-zA-Z0-9_]*", "return 'ID'"],
    ["<%lua", "this.pushState('lua'); return 'BLOCK_BEGIN_LUA'"],
    ["<%", "this.pushState('etl'); return 'BLOCK_BEGIN_ETL'"],
    [["lua", "etl"], "%>", "this.popState(); return 'BLOCK_END'"],
    ["=", "return '='"],
    ["\\(", "return '('"],
    ["\\)", "return ')'"],
    [["*"], "\\r\\n", "/*return 'NEWLINE'*/"],
    [["*"], "\\n", "/*return 'NEWLINE'*/"],
    [["*"], ".", "/*return 'ANY_OTHER'*/"],
  ],
}

let bnf_main = {
  
  etl: [
    ["etl_element", "$$ = newList($etl_element)"],
    ["etl etl_element", "$$ = joinList($etl, $etl_element)"]
  ],

  etl_element: [
    ["LOCAL ID = REQUIRE ( str )", "$$ = newUsing($str, $ID, @1.startOffset, @7.endOffset)"],
    ["block", "$$ = $block"],
  ],

  block: [
    ["BLOCK_BEGIN_LUA block_body BLOCK_END", "$$ = newBlock('block_lua', @1.startOffset+5, @3.endOffset-2);"],
    ["BLOCK_BEGIN_LUA BLOCK_END", "$$ = newBlock('block_lua', @1.startOffset+5, @2.endOffset-2);"],
    ["BLOCK_BEGIN_ETL block_body BLOCK_END", "$$ = newBlock('block_etx', @1.startOffset+2, @3.endOffset-2);"],
    ["BLOCK_BEGIN_ETL BLOCK_END", "$$ = newBlock('block_etx', @1.startOffset+2, @2.endOffset-2);"],
  ],

  block_body: [
    ["str", ""],
    ["block_body str", ""]
  ],

  str: [
    ["STRING_TRIPLE", "$$ = $1"],
    ["STRING_SINGLE", "$$ = $1"],
  ],
}

let include_main = `

    function newBlock(type, from, to) {
      return { kind: type, from: from, to: to };
    }

    function newUsing(str, id, from, to) {
      return { kind: 'using', ref: eval(str), pkg: id, from: from, to: to };
    }

    function newList(item) {
      return item ? [item] : [];
    }

    function joinList(list, item) {
      if(list && item) {
        list.push(item);
      }
      return list;
    }

`


/* ETL

  build
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etl.g -o sdk/parser/etlParser.js --loc

  语法验证
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etl.g --validate

  不包含语法时的词法检查
  node sdk/parser/build.js && syntax-cli --lex sdk/parser/build/etl_lex.g --tokenize -f test/parsertest/etlTest.etl --loc

  包含语法时的词法检查
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etl.g --tokenize -f test/parsertest/etlTest.etl --loc

  语法分析
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etl.g -o sdk/parser/etlParser.js --loc && syntax-cli -m slr1 -g sdk/parser/build/etl.g -f test/parsertest/etlTest.etl --loc
*/





// segtype ////////////////////////////////////////////////////////////////////////////
let lex_segtype = {
  rules: [
    ["uint", "return 'UINT'" ],
    ["int", "return 'INT'" ],
    ["float", "return 'FLOAT'"],
    ["double", "return 'DOUBLE'"],
    ["string", "return 'STRING'"],
    ["(6[0-4])|([1-5][0-9])|([1-9])", "return 'LEN'"],
    [">", "return '>'"],
    ["<", "return '<'"],
    ["!", "return '!'"],
    ["&", "return '&'"],
    ["=", "return '='"],
    ["\\s+", ""],
  ],
}

let bnf_segtype = {

  segtype: [
    ["basetype", "$$ = $basetype;"],
    ["basetype byteorder", "$basetype.order = $byteorder; $$=$basetype;"],
    ["strtype", "$$ = $strtype;"],
    ["strtype byteorder", "$strtype.order = $byteorder; $$=$strtype;"],
    ["basetype encode", "$basetype.encode = $encode; $$=$basetype;"],
    ["basetype byteorder encode", "$basetype.encode = $encode; $basetype.order = $byteorder; $$=$basetype;"],
    ["basetype encode byteorder", "$basetype.encode = $encode; $basetype.order = $byteorder; $$=$basetype;"],
  ],

  basetype: [
    ["INT LEN", "$$ = {type: 'integer', bitcount: eval($LEN), signed: true}"],
    ["UINT LEN", "$$ = {type: 'integer', bitcount: eval($LEN), signed: false}"],
    ["FLOAT", "$$ = {type: 'float'}"],
    ["DOUBLE", "$$ = {type: 'double'}"],
  ],

  strtype: [
    ["STRING", "$$ = {type: 'string'}"],
  ],

  byteorder: [
    [">", "$$ = 'bigorder'"],
    ["<", "$$ = 'smallorder'"],
  ],

  encode: [
    ["&", "$$ = 'complement'"],
    ["!", "$$ = 'inversion'"],
    ["=", "$$ = 'primitive'"],
  ]
}

/* segment

  build
  node sdk/core/parser/build.js && syntax-cli -m slr1 -g sdk/core/parser/build/segtype.g -o sdk/core/parser/segParser.js --loc

  语法验证
  node sdk/core/parser/build.js && syntax-cli -m slr1 -g sdk/core/parser/build/segtype.g --validate

  不包含语法时的词法检查
  node sdk/core/parser/build.js && syntax-cli --lex sdk/core/parser/build/segtype_lex.g --tokenize -p "int8"

  包含语法时的词法检查
  node sdk/core/parser/build.js && syntax-cli -m slr1 -g sdk/core/parser/build/segtype.g --tokenize -p "double>"

  语法分析
  node sdk/core/parser/build.js && syntax-cli -m slr1 -g sdk/core/parser/build/segtype.g -o sdk/core/parser/segParser.js && syntax-cli -m slr1 -g sdk/core/parser/build/segtype.g -p "string>"
*/



// ETX ////////////////////////////////////////////////////////////////////////////
let lex_etx = {
  startConditions: {
    protocol: 1,
    device: 1,
    topology: 1,
  },
  rules: [
    [["*"], "\\/\\*[^*]*\\*+([^\\/][^*]*\\*+)*\\/", "/*return 'COMMENT_BLOCK'*/" ],
    [["*"], "\\/\\/[^\\r\\n]*", "/*return 'COMMENT_LINE'*/"],
    [["*"], "\\\"([^\\\\\\n\"]|\\\\.)*\\\"", "return 'STRING_TRIPLE'"],
    [["*"], "'([^\\\\\\n']|\\\\.)*'", "return 'STRING_SINGLE'"],
    [["*"], "%[0-9A-Fa-f\\s]*%", "return 'STRING_HEX'"],
    [["*"], "\\s+", "/* return 'WHITESPACE' */"],
    [["*"], "\\n", "/* return 'NEWLINE' */"],
    [["*"], "\\bbitlr\\b", "return 'BITLR' "],
    [["*"], "\\bbitrl\\b", "return 'BITRL' "],

    [["*"], "\\bprotocol\\b", "if(this.getCurrentState()!=='INITIAL') this.popState(); this.pushState('protocol'); return 'PROTOCOL';"],
    [["protocol"], "\\bsegments\\b", "return 'SEGMENTS'"],
    [["protocol"], "\\bsegment\\b", "return 'SEGMENT'"],
    [["protocol"], "\\boneof\\b", "return 'ONEOF'"],

    [["*"], "\\bdevice\\b", "if(this.getCurrentState()!=='INITIAL') this.popState(); this.pushState('device'); return 'DEVICE';"],
    [["device"], "\\b(udp|tcp_server|tcp_client|serial_ttl|serial_232|serial_422|serial_485|serial_usb|can|di|do|ad|da)\\b", "return 'INTFTYPE'"],

    [["*"], "\\btopology\\b", "if(this.getCurrentState()!=='INITIAL') this.popState(); this.pushState('topology'); return 'TOPOLOGY';"],
    [["topology"], "\\blinking\\b", "return 'LINKING'"],
    [["topology"], "\\bmapping\\b", "return 'MAPPING'"],
    [["topology"], "\\bbinding\\b", "return 'BINDING'"],
    [["topology"], "\\buut\\b", "return 'UUT'"],
    [["topology"], "\\betest\\b", "return 'ETEST'"],
    
    [["*"], "true", "return 'TRUE'"],
    [["*"], "false", "return 'FALSE'"],
    [["*"], "and", "return 'AND'"],
    [["*"], "or", "return 'OR'"], 
    [["*"], "not", "return 'NOT'"],
    [["*"], "0[xX][0-9a-fA-F]+", "return 'NUMBER_HEX'"],
    [["*"], "[0-9]+(?:\\.[0-9]+)?", "return 'NUMBER'"],
    [["*"], "[a-zA-Z_$][a-zA-Z0-9_]*", "return 'ID'"],
    [["*"], "~=", "return 'NOT_EQ'"],
    [["*"], "==", "return 'EQ_EQ'"],
    [["*"], ">=", "return 'GT_EQ'"], 
    [["*"], "<=", "return 'LT_EQ'"], 
    [["*"], "{", "return '{'"],
    [["*"], "}", "return '}'"],
    [["*"], "]", "return ']'"],
    [["*"], "\\[", "return '['"],
    [["*"], ",", "return ','"],
    [["*"], "\\:", "return ':'"],
    [["*"], "\\.", "return 'DOT'"],
    [["*"], "\\+", "return '+'"],
    [["*"], "-", "return '-'"],
    [["*"], "\\*", "return '*'"],
    [["*"], "\\/", "return '/'"],
    [["*"], "\\(", "return '('"],
    [["*"], "\\)", "return ')'"],
    [["*"], ">", "return '>'"], 
    [["*"], "<", "return '<'"],
  ],
}

let bnf_etx = {
  top_element_list: [
    ["top_element", "$$ = newList($top_element);"],
    ["top_element_list top_element", "$$ = joinList($top_element_list, $top_element);"]
  ],

  top_element: [
    ["BITLR PROTOCOL ID { }", "let res = newElement('protocol', $ID, 'seglist', null, @ID); res.bittype = 'lr'; $$ = res; "],
    ["BITRL PROTOCOL ID { }", "let res = newElement('protocol', $ID, 'seglist', null, @ID); res.bittype = 'rl'; $$ = res; "],
    ["PROTOCOL ID { }", "$$ = newElement('protocol', $ID, 'seglist', null, @ID);"],
    ["BITLR PROTOCOL ID { protocol_element_list }", "let res = newElement('protocol', $ID, 'seglist', $protocol_element_list, @ID); res.bittype = 'lr'; $$ = res; "],
    ["BITRL PROTOCOL ID { protocol_element_list }", "let res = newElement('protocol', $ID, 'seglist', $protocol_element_list, @ID); res.bittype = 'rl'; $$ = res; "],
    ["PROTOCOL ID { protocol_element_list }", "$$ = newElement('protocol', $ID,'seglist', $protocol_element_list, @ID);"],
    ["DEVICE ID { }", "$$ = {kind: 'device', name: $ID, value: null};"],
    ["DEVICE ID { device_element_list }", "$$ = {kind: 'device', name: $ID, value: $device_element_list};"],
    ["TOPOLOGY ID { }", "$$ = {kind: 'topology', name: $ID, value: null};"],
    ["TOPOLOGY ID { topology_element_list }", "$$ = {kind: 'topology', name: $ID, value: $topology_element_list};"],
  ],

  // protocol
  protocol_element_list: [
    ["protocol_element", "$$ = newList($protocol_element);"],
    ["protocol_element_list protocol_element", "$$ = joinList($protocol_element_list, $protocol_element)"]
  ],

  protocol_element: [
    ["SEGMENT ID object_like", "$$ = newElement('segment', $ID, 'props', $object_like, @ID);"],
    ["SEGMENT ID [ exp ] object_like", "$$ = newElement('segment', $ID, 'props', $object_like, @ID, $exp);"],
    ["segments", "$$ = $segments;"],
    ["branch", "$$ = $branch;"],
  ],

  segments: [
    ["SEGMENTS ID { }", "$$ = newProtSeggroup($ID, null, @ID);"],
    ["SEGMENTS ID { protocol_element_list }", "$$ = newProtSeggroup($ID, $protocol_element_list, @ID);"],
    ["SEGMENTS ID [ exp ] { protocol_element_list }", "$$ = newProtSeggroup($ID, $protocol_element_list, @ID, $exp);"],
  ],

  branch: [
    ["ONEOF ( exp ) { }", "$$ = newProtBranch('oneof', $exp, null, @exp);"],
    ["ONEOF ( exp ) { protocol_element_list }", "$$ = newProtBranch('oneof', $exp, $protocol_element_list, @exp);"],
  ],

  // device
  device_element_list: [
    ["device_element", "$$ = newList($device_element);"],
    ["device_element_list device_element", "$$ = joinList($device_element_list, $device_element);"]
  ],

  device_element: [
    ["INTFTYPE ID object_like", "$$ = {kind: 'connector', name: $ID, type: $INTFTYPE, config: $object_like};"],
  ],

  //topology
  topology_element_list: [
    ["topology_element", "$$ = $topology_element;"],
    ["topology_element_list topology_element", "$$ = $topology_element_list.concat($topology_element);"]
  ],

  topology_element: [
    ["LINKING : { }", "$$ = [];"],
    ["LINKING : { topology_linking_elements }", "$$ = $topology_linking_elements;"],
    ["MAPPING : { }", "$$ = [];"],
    ["MAPPING : { topology_mapping_elements }", "$$ = $topology_mapping_elements"],
    ["BINDING : { }", "$$ = [];"],
    ["BINDING : { topology_bindinging_elements }", "$$ = $topology_bindinging_elements;"],
  ],

  topology_linking_elements: [
    ["topology_linking_element", "$$ = newList($topology_linking_element);"],
    ["topology_linking_elements , topology_linking_element", "$$ = joinList($topology_linking_elements, $topology_linking_element);"],
    ["topology_linking_elements ,", "$$ = $topology_linking_elements;"],
  ],

  topology_linking_element: [
    ["ID : [ ]", "$$ = null;"],
    ["ID : [ topology_dev_intfs ]", "$$ = { kind: 'linking', name: $ID, value: $topology_dev_intfs };"],
  ],

  topology_mapping_elements: [
    ["topology_mapping_element", "$$ = newList($topology_mapping_element);"],
    ["topology_mapping_elements , topology_mapping_element", "$$ = joinList($topology_mapping_elements, $topology_mapping_element);"],
    ["topology_mapping_elements ,", "$$ = $topology_mapping_elements;"],
  ],

  topology_mapping_element: [
    ["UUT : [ ]", "$$ = null;"],
    ["UUT : [ topology_devs ]", "$$ = {kind: 'uut', value: $topology_devs};"],
    ["ETEST : [ ]", "$$ = null;"],
    ["ETEST : [ topology_devs ]", "$$ = {kind: 'etest', value: $topology_devs};"],
  ],

  topology_bindinging_elements: [
    ["topology_bindinging_element", "$$ = newList($topology_bindinging_element);"],
    ["topology_bindinging_elements , topology_bindinging_element", "$$ = joinList($topology_bindinging_elements, $topology_bindinging_element);"],
    ["topology_bindinging_elements ,", "$$ = $topology_bindinging_elements;"],
  ],

  topology_bindinging_element: [
    ["topology_dev_intf : STRING_TRIPLE", "$topology_dev_intf.kind = 'binding'; $topology_dev_intf.bind = eval($STRING_TRIPLE); $$ = $topology_dev_intf;"],
    ["topology_dev_intf : STRING_SINGLE", "$topology_dev_intf.kind = 'binding'; $topology_dev_intf.bind = eval($STRING_SINGLE); $$ = $topology_dev_intf;"],
  ],

  topology_dev_intfs: [
    ["topology_dev_intf", "$$ = newList($topology_dev_intf)"],
    ["topology_dev_intfs , topology_dev_intf", "$$ = joinList($topology_dev_intfs, $topology_dev_intf);"],
    ["topology_dev_intfs ,", "$$ = $topology_dev_intfs"],
  ],

  topology_dev_intf: [
    ["ID DOT ID", "$$ = { kind: 'dev_connector', device: $1, connector: $3};"]
  ],

  topology_devs: [
      ["ID", "$$ = newList($ID);"],
      ["topology_devs , ID", "$$ = joinList($topology_devs, $ID);"],
      ["topology_devs ,", "$$ = $topology_devs;"],
  ],


  // common
  object_like: [
    ["{ }", "$$ = newList(null);"],
    ["{ property_list }", "$$ = $property_list;"],
  ],

  property_list: [
    ["property_setting", "$$ = newList($property_setting);"],
    ["property_list , property_setting", "$$ = joinList($property_list, $property_setting);"],
    ["property_list ,", "$$ = $property_list;"],
  ],

  property_setting: [
    ["ID : exp", "$$ = newProp($ID, $exp, @ID, @exp);"]
  ],

  exp: [
    ["literal", "$$ = $literal;"],
    ["object_like", "$$ = $object_like;"],
    ["NOT exp", "$$ = {kind: 'not', exp: $exp};"],
    ["- exp", "$$ = {kind: 'uminus', exp: $exp};", { "prec": "UMINUS" }],
    ["exp NOT_EQ exp", "$$ = {kind: 'not_eq', left: $1, right: $3};"],
    ["exp EQ_EQ exp", "$$ = {kind: 'eq_eq', left: $1, right: $3};"],
    ["exp GT_EQ exp", "$$ = {kind: 'gt_eq', left: $1, right: $3};"],
    ["exp LT_EQ exp", "$$ = {kind: 'lt_eq', left: $1, right: $3};"],
    ["exp > exp", "$$ = {kind: 'gt', left: $1, right: $3};"],
    ["exp < exp", "$$ = {kind: 'lt', left: $1, right: $3};"],
    ["exp + exp", "$$ = {kind: 'add', left: $1, right: $3};"],
    ["exp - exp", "$$ = {kind: 'subtract', left: $1, right: $3};"],
    ["exp * exp", "$$ = {kind: 'multiply', left: $1, right: $3};"],
    ["exp / exp", "$$ = {kind: 'divide', left: $1, right: $3};"],
    ["exp AND exp", "$$ = {kind: 'and', left: $1, right: $3};"],
    ["exp OR exp", "$$ = {kind: 'or', left: $1, right: $3};"],
    ["( exp )", "$$ = $exp;"],
    ["[ ]", "$$ = newKindList('array', null);"],
    ["[ arrlist ]", "$$ = $arrlist;"],
    ["gfn_call", "$$ = $gfn_call;"],
  ],

  gfn_call: [
    ["ID ( )", "$$ = { kind: $ID };"],
    ["ID ( paramlist )", "$$ = {kind: $ID, params: $paramlist};"],
  ],

  paramlist: [
    ["exp", "$$ = newList($exp);"],
    ["paramlist , exp", "$$ = joinList($paramlist, $exp);"],
    ["paramlist ,", "$$ = $paramlist;"],
  ],


  arrlist: [
    ["exp", "$$ = newKindList('array', $exp);"],
    ["arrlist , exp", "$$ = joinKindList($arrlist, $exp);"],
    ["arrlist ,", "$$ = $arrlist;"],
  ],

  literal: [
    ["NUMBER", "$$ = {kind: 'number', value: eval(yytext)};"],
    ["NUMBER_HEX", "$$ = {kind: 'number', value: eval(yytext)};"],
    ["str", "$$ = $str;"],
    ["pid", "$$ = $pid;"],
    ["TRUE", "$$ = {kind: 'bool', value: true};"],
    ["FALSE", "$$ = {kind: 'bool', value: false};"],
  ],

  pid: [
    ["ID", "$$ = newKindList('pid', $1);"],
    ["pid DOT ID", "$$ = joinKindList($pid, $ID);"]
  ],

  str: [
    ["STRING_TRIPLE", "$$ = {kind: 'string', value: eval(yytext)};"],
    ["STRING_SINGLE", "$$ = {kind: 'string', value: eval(yytext)};"],
    ["STRING_HEX", "$$ = {kind: 'strhex',  value: yytext.replace(/%/g, '')};"],
  ],

}

let include_etx = `

    function newList(item) {
      if(item) {
        return [item];
      } else {
        return [];
      }
    }

    function joinList(list, item) {
      if(list && item) {
        list.push(item);
      }
      return list;
    }

    function newKindList(kind, item) {
      if(item) {
        return {kind: kind, list: [item]};
      } else {
        return {kind: kind, list: []};
      }
    }

    function joinKindList(list, item) {
      if(list && list.list && item) {
        list.list.push(item);
      }
      return list;
    }

    function newProp(id, exp, id_loc, exp_loc) {
      return {
        kind: 'prop',
        name: id,
        value: exp,
        name_from: id_loc.startOffset,
        name_to: id_loc.endOffset,
        name_line: id_loc.startLine,
        value_from: exp_loc.startOffset,
        value_to: exp_loc.endOffset,
        value_line: exp_loc.startLine,
      }
    }

    function newProtBranch(kind, exp, seglist, exp_loc) {
      return {
        kind: kind,
        exp: exp,
        seglist: seglist,
        exp_from: exp_loc.startOffset,
        exp_to: exp_loc.endOffset,
        exp_line: exp_loc.startLine,
      }
    }

    function newProtSeggroup(name, seglist, name_loc, repeated) {
      let res = {
        kind: 'seggroup',
        name: name,
        seglist: seglist,
        name_from: name_loc.startOffset,
        name_to: name_loc.endOffset,
        name_line: name_loc.startLine,
      }
      if(repeated) {
        res.repeated = repeated;
      }
      return res;
    }

    function newElement(kind, name, body_name, body, name_loc, repeated) {
      let res = {
        kind: kind,
        name: name,
        name_from: name_loc.startOffset,
        name_to: name_loc.endOffset,
        name_line: name_loc.startLine,
      }
      res[body_name] = body;
      if(repeated) {
        res.repeated = repeated;
      }
      return res;
    }


`

let operators = [
  ["left", "AND", "OR"],
  ["left", ">", "<", "GT_EQ", "LT_EQ", "EQ_EQ", "NOT_EQ"],
  ["left", "+", "-"],
  ["left", "*", "/"],
  ["left", "UMINUS", "NOT"],
];

/* ETX

  build
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etx.g -o sdk/parser/etxParser.js --loc

  语法验证
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etx.g --validate

  不包含语法时的词法检查
  node sdk/parser/build.js && syntax-cli --lex sdk/parser/build/etx_lex.g --tokenize -f test/proj_dev_temp/etxTest.etx --loc

  包含语法时的词法检查
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etx.g --tokenize -f test/proj_dev_temp/etxTest.etx --loc

  语法分析
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/etx.g -o sdk/parser/etxParser.js --loc && syntax-cli -m slr1 -g sdk/parser/build/etx.g -f test/proj_dev_temp/device/device.etl --loc

*/

fs.writeFileSync(path.join(__dirname, 'build/etl_lex.g'), JSON.stringify(etl_main, null, 4));
fs.writeFileSync(path.join(__dirname, 'build/etl.g'), JSON.stringify({lex: etl_main, bnf: bnf_main, moduleInclude: include_main}, null, 4));
fs.writeFileSync(path.join(__dirname, 'build/etx_lex.g'), JSON.stringify(lex_etx, null, 4));
fs.writeFileSync(path.join(__dirname, 'build/etx.g'), JSON.stringify({lex: lex_etx, operators: operators, bnf: bnf_etx, moduleInclude: include_etx}, null, 4));
fs.writeFileSync(path.join(__dirname, 'build/segtype_lex.g'), JSON.stringify(lex_segtype, null, 4));
fs.writeFileSync(path.join(__dirname, 'build/segtype.g'), JSON.stringify({lex: lex_segtype, bnf: bnf_segtype}, null, 4));


let bnf_exp = { 
  exp: bnf_etx.exp,
  gfn_call:bnf_etx.gfn_call,
  paramlist: bnf_etx.paramlist,
  arrlist:bnf_etx.arrlist,
  literal: bnf_etx.literal,
  pid: bnf_etx.pid,
  str: bnf_etx.str,
  object_like: bnf_etx.object_like,
  property_list: bnf_etx.property_list,
  property_setting: bnf_etx.property_setting,
};
fs.writeFileSync(path.join(__dirname, 'build/exp.g'), JSON.stringify({lex: lex_etx, operators: operators, bnf: bnf_exp, moduleInclude: include_etx}, null, 4));

/* exp

  build
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/exp.g -o sdk/parser/expParser.js --loc

  语法验证
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/exp.g --validate


  包含语法时的词法检查
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/exp.g --tokenize -p "this.a+1" --loc

  语法分析
  node sdk/parser/build.js && syntax-cli -m slr1 -g sdk/parser/build/exp.g -o sdk/parser/expParser.js --loc && syntax-cli -m slr1 -g sdk/parser/build/exp.g -p "this.a*18+22" --loc

*/
