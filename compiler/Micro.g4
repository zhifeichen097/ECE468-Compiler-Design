grammar Micro;
@members {
      	public Tree tree = new Tree();
      	public int block = 0;
      	public java.util.LinkedList<Integer> if_label = new java.util.LinkedList<Integer>();
      	public IRList ir_list = new IRList();  
      	public AbstractSyntaxTree abs;
      	public int reg_number = -1; 
	public int old_node_index = 0;
	public IRNode new_node, extra_node;
	public java.util.LinkedList<Integer> old_node_stack = new java.util.LinkedList<Integer>();
	public java.util.LinkedList<AbstractSyntaxTree> abs_stack = new java.util.LinkedList<AbstractSyntaxTree>();
	public String tempString = IRNode.getTempPrefix();
	public int links;
	public Function function;
}
keyword: KEYWORD;
KEYWORD
       : 'prog'
       | 'begin'
       | 'end'
       | 'func'
       | 'read'
       | 'write'
       | 'if'
       | 'else'
       | 'endif'
       | 'do'
       | 'while'
       | 'endwhile'
       | 'continue'
       | 'break'
       | 'return'
       | 'int'
       | 'void'
       | 'str'
       | 'float'
       | 'true'
       | 'false'
	   ;

IDENTIFIER
      : [A-Za-z][A-Za-z0-9]*;


INTLITERAL
      : [0-9]+; 

FLOATLITERAL
      : [0-9]*'.'[0-9]+; 
      
STRINGLITERAL 
      : '"'(~'"')*'"';      

COMMENT
      : ('#'(~'\n')*'\n') -> skip; 

WS
      : (' ' | '\t' | '\n' | '\r' )+ -> skip;

OPERATOR
    : ':='
    	| '+' 
	| '-' 
	| '*' 
	| '/' 
	| '='
	| '=='
	| '!=' 
	| '<' 
	| '>' 
	| '(' 
	| ')' 
	| ';' 
	| ',' 
	| '<=' 
	| '>=' 
	; 

// program 


program: 'prog' id 'begin' pgm_body 'end' {};
id:  IDENTIFIER;
pgm_body: decl 
	{ir_list.addAll(ir_list.callMainList());}
	func_declarations;
decl: string_decl{links++;} decl | var_decl decl | ;

//Global String Declaration
str_literal: STRINGLITERAL;
string_decl: 'str' id '=' str_literal ';'
{
Symbol symbol = new Symbol($id.text, "str", $str_literal.text);
 ir_list.addLast(new IRNode("str", $id.text, null, $str_literal.text));
  tree.current_scope.add_symbol(symbol); 
};


//Variable Declaration
var_decl: var_type id_list ';'
{
  String[] strList = $id_list.text.split(",");
  for (String id : strList){
    links++;
    Symbol symbol = new Symbol(id, $var_type.text, "0");
    if (tree.chkRoot()){
//System.out.println("not GET INTO ADD LOCAL");
ir_list.addLast(new IRNode("var", null, null, id));
	}
   else{
//System.out.println("GET INTO ADD LOCAL");
function.addLocal(symbol);
}
    tree.current_scope.add_symbol(symbol);
    
  }
}
;
var_type: 'float' | 'int' ;
any_type: var_type | 'void';
id_list: id id_tail;
id_tail: ',' id id_tail | ;

//Function Parameter List
param_decl_list: param_decl param_decl_tail | ;
param_decl: var_type id
{
  Symbol symbol = new Symbol($id.text, $var_type.text, "0");
  tree.current_scope.add_symbol(symbol);
  function.addParameter($id.text, $var_type.text);
}
;
param_decl_tail: ',' param_decl param_decl_tail | ;

//Function Declarations
func_declarations: func_decl func_declarations | ;

func_decl: 'func' any_type id 
{
  tree.enterScope($id.text, 0);
  function = new Function();
  tree.current_scope.add_function(function);
  ir_list.addLast(IRNode.LabelNode($id.text));
  ir_list.getLast().start = true;
}

'(' param_decl_list {function.addParameterValues();} ')' 'begin' func_body 'end'
{
  if(!ir_list.getLast().opcode.equals("RET")){
  ir_list.addLast(IRNode.ReturnNode());}


  ir_list.getLast().end = true;
  tree.exitScope();
}
;

func_body: {links = 0;}
  decl{
    ir_list.addLast(new IRNode("LINK", null, null, Integer.toString(links)));
  }
stmt_list;

//Statement List
stmt_list: stmt stmt_list | ;
stmt: base_stmt | if_stmt | loop_stmt;
base_stmt: assign_stmt | read_stmt | write_stmt | control_stmt;

//Basic Statements
assign_stmt: assign_expr ';' ;
//assign_expr: id '=' expr ;
assign_expr: id {abs = new AbstractSyntaxTree(tree.current_scope.getSymbol($id.text), function.register_num, tree.current_scope);}
'=' expr {abs.end();ir_list.addAll(abs.ir_list); function.register_num = abs.getTempCount();}
;

//read_stmt: 'read' '(' id_list ')' ';' ;
//write_stmt: 'write' '(' id_list ')' ';';


read_stmt: 'read' '(' id_list ')' ';'
{
  String[] idList = $id_list.text.split(",");
  String opcode = null;
  for (String id : idList){
    String idd = id;
    Symbol symbol = function.getLocal(id);
    if(symbol == null){
	symbol = tree.current_scope.getSymbol(id);}
    else{
        idd = symbol.value;}

    if (symbol.type.equals("int")){opcode = "READI";}
    else if (symbol.type.equals("float")){opcode = "READF";}
    IRNode ir_node = new IRNode(opcode, null, null, idd);
    ir_list.addLast(ir_node); 
  }
}
;
write_stmt: 'write' '(' id_list ')' ';'
{
  String[] idList = $id_list.text.split(",");
  String opcode = null;
  for (String id : idList){
    String idd = id;
    Symbol symbol = function.getLocal(id);
    if(symbol == null){
	symbol = tree.current_scope.getSymbol(id);}
    else{
        idd = symbol.value;}
    if (symbol.type.equals("int")){opcode = "WRITEI";}
    else if (symbol.type.equals("float")){opcode = "WRITEF";}
    else if (symbol.type.equals("str")){opcode = "WRITES";}
    IRNode ir_node = new IRNode(opcode, idd, null, null);
    ir_list.addLast(ir_node); 
  }
}
;
return_stmt : 
  'return' {abs = new AbstractSyntaxTree(function.register_num, tree.current_scope);}
  expr{
    abs.setType($expr.text); abs.return_stmt = true; abs.end(); ir_list.addAll(abs.ir_list); function.register_num = abs.getTempCount();
    ir_list.addLast(new IRNode("STORE"+abs.type, tempString+function.register_num, null, function.getReturnValue())); // Store latest temp on stack as return value
    ir_list.addLast(IRNode.ReturnNode());
  }
 ';'
;

//Expressions
expr: expr_prefix factor;
expr_prefix: expr_prefix factor addop | ;
factor: factor_prefix postfix_expr;
factor_prefix: factor_prefix postfix_expr mulop | ;
postfix_expr: primary | call_expr;

call_expr:
{ir_list.addLast(IRNode.PushNode());}
 id '(' 
{abs_stack.push(abs); function.register_num = abs.getTempCount();}

expr_list 
{abs = abs_stack.pop();}
')'{
  ir_list.addAll(ir_list.callFunction($id.text)); //push r, jsr, pop r
  // Pop parameters
  for(int i=0; i< tree.getNumParam($id.text); i++){ir_list.addLast(IRNode.PopNode());}
  // pop and add ret value to abs
  String ret_value = tempString + Integer.toString(++function.register_num);
  ir_list.addLast(IRNode.PopNode(ret_value));
  abs.setTempCount(function.register_num);
  abs.add_operand(ret_value);
}
;


expr_list: 
{ abs = new AbstractSyntaxTree(function.register_num, tree.current_scope); abs.func_call = true;} 
  expr { abs.setType($expr.text); abs.end(); ir_list.addAll(abs.ir_list); function.register_num = abs.getTempCount();
         ir_list.addLast(IRNode.PushNode(abs.root.value)); // push the parameter!
         }
 expr_list_tail | ;






expr_list_tail: ',' 
 {abs = new AbstractSyntaxTree(function.register_num, tree.current_scope); abs.func_call = true;}
         expr { abs.setType($expr.text); abs.end(); ir_list.addAll(abs.ir_list); function.register_num = abs.getTempCount();
                ir_list.addLast(IRNode.PushNode(abs.root.value));
              } 
 expr_list_tail |;







primary: '('   {abs.open_expr();}
  expr ')'     {abs.close_expr();} | 
  id           {abs.add_operand($id.text);}| 
  INTLITERAL   {abs.add_operand($INTLITERAL.text);}| 
  FLOATLITERAL {abs.add_operand($FLOATLITERAL.text);}
  ;
addop: '+'{abs.add_operator("+");} | 
       '-'{abs.add_operator("-");}
       ;
mulop: '*'{abs.add_operator("*");} | 
       '/'{abs.add_operator("/");}
;

//Complex Statements and Condition

////////IF////
if_stmt: 'if'
{tree.enterScope("BLOCK", ++block);
if_label.push(tree.getCurrentExit());}


 '(' cond ')' {ir_list.addLast(new_node); old_node_index = ir_list.size()-1; old_node_stack.push(old_node_index);}

decl 



stmt_list {ir_list.addLast(IRNode.JumpNode(if_label.getFirst()));}




else_part 'endif' {ir_list.addLast(IRNode.LabelNode(if_label.pop()));


     //   old_node_stack.pop();

tree.exitScope();};

///////ELSE////
else_part: 'else'
{tree.enterScope("BLOCK",++block);

ir_list.replace(old_node_stack.pop(), "label"+ tree.getCurrentEnter()); 
ir_list.addLast(IRNode.LabelNode(tree.getCurrentEnter()));}

decl stmt_list
{ir_list.addLast(IRNode.JumpNode(if_label.getFirst())); 
tree.exitScope();}

 | {old_node_stack.pop();} ;


cond:
 	{abs = new AbstractSyntaxTree(function.register_num, tree.current_scope);} 
 expr
	{new_node = new IRNode(null, null, null, null); 
 	 abs.setType($expr.text); abs.lhs_cond = true; abs.end(); ir_list.addAll(abs.ir_list); function.register_num = abs.getTempCount();
       new_node.op1 = abs.root.value;} 

compop{new_node.opcode+=abs.type;}  
{abs = new AbstractSyntaxTree(function.register_num, tree.current_scope);}


expr 
	{abs.setType($expr.text);  abs.rhs_cond = true;abs.end();ir_list.addAll(abs.ir_list); function.register_num = abs.getTempCount();
       new_node.op2 = abs.root.value; 
       new_node.result = "label"+ if_label.getFirst();
      } 

| 'true' | 'false';



compop: '<' {new_node.opcode = "GE";}  | '>' {new_node.opcode = "LE";} | '=='  {new_node.opcode = "NE";} | '!=' {new_node.opcode = "EQ";}  | '<=' {new_node.opcode = "GT";}| '>='{new_node.opcode = "LT";};



////WHILE 
while_stmt: 'while' 
{tree.enterScope("BLOCK", ++block);
ir_list.addLast(IRNode.LabelNode(tree.getCurrentEnter()));
if_label.push(tree.getCurrentExit());}

'(' cond ')'{

ir_list.addLast(new_node);
old_node_index = ir_list.size()-1;
old_node_stack.push(old_node_index);
 
}


decl stmt_list 'endwhile' {

ir_list.addLast(IRNode.JumpNode(tree.getCurrentEnter()));
ir_list.addLast(IRNode.LabelNode(if_label.pop()));

tree.exitScope();};



//ECE468 ONLY
//control_stmt: return_stmt
//loop_stmt: while_stmt

//ECE573 ONLY
control_stmt: return_stmt | 'continue' ';' | 'break' ';';
loop_stmt: while_stmt | for_stmt;
iter_var: id;
start_expr: expr;
end_expr: expr;
incr_expr: expr;
for_stmt: 'for' iter_var 'in' 'range' '(' start_expr ',' end_expr ',' incr_expr ')' decl stmt_list 'endfor'; 









