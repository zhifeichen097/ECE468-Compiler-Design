import java.util.*;
import java.lang.*;

class AbstractSyntaxTree{
    public boolean return_stmt;
    public boolean func_call;
    public boolean rhs_cond;
    public boolean lhs_cond;
    
    public ExpressionNode root;
    public LinkedList operator_stack;
    public LinkedList expression_stack;
    public IRList ir_list;
    public Symbol lhs;
    private Integer temp_count;
    public String type;
    public SymbolNode table;
    public String input;
    




    
    
    private static final Map<String, Integer> precedence_map = Collections.unmodifiableMap(
											   new HashMap<String, Integer>() {{
												   put("open", 0);
												   put("+", 1);
												   put("-", 1);
												   put("*", 2);
												   put("/", 2);
											       }});
    
    public AbstractSyntaxTree(Symbol lhs, int reg_number, SymbolNode table){
	this.lhs = lhs;
	operator_stack = new LinkedList();
	expression_stack = new LinkedList();
	ir_list = new IRList();
	root = null;
	temp_count = new Integer(reg_number);
	if (lhs.type.equals("float")){type = "F";}
	else{type ="I";}//(lhs.type.equals("int")) {type = "I";}
	//else {type ="S";}
	this.table = table;
	return_stmt = false;
        func_call=false ;
	rhs_cond = false;
	lhs_cond = false;
	}

    public AbstractSyntaxTree(int reg_number, SymbolNode table){
		this.lhs = null;
		operator_stack = new LinkedList();
		expression_stack = new LinkedList();
		ir_list = new IRList();
		root = null;
		temp_count = new Integer(reg_number);
		this.table = table;
		return_stmt = false;
		func_call=false ;
		rhs_cond = false;
		lhs_cond = false;
}





    
    public void setType(String input ){
	// check if symbol involved
	//	System.out.println(input);
	if (input == null){System.out.println("no input!");}
	if (input.contains(".")){type = "F"; return;}
	for (String str : input.split(" ")){
	    if (table.getSymbol(str) != null){
		type = (table.getSymbol(str).type.substring(0,1)).toUpperCase(); return;
	    }
	    type = "I";
	}
}
    public void setTempCount(int count){
	temp_count = count;
}
    
    public void add_operand(String operand){
	ExpressionNode node = new ExpressionNode(operand);
	expression_stack.push(node);}
    
    public void add_operator(String operation){
	if (!operator_stack.isEmpty()){
	    while(getPrecedence(operation) <= getPrecedence((String)operator_stack.getFirst()) ){
		build_node_from_stack();
		if(operator_stack.isEmpty()){break;}
	    }
        }
        operator_stack.push(operation);
    }
    
    private void build_node_from_stack(){
	String operator = (String)operator_stack.pop();
	ExpressionNode op2 = (ExpressionNode) expression_stack.pop();
        ExpressionNode op1 = (ExpressionNode) expression_stack.pop();
        ExpressionNode node = new ExpressionNode(operator, op1, op2);
        expression_stack.push(node);
	}
    
    public void open_expr(){
		operator_stack.push("open");
	}
    
    public void close_expr(){ // (
	       
	while (!operator_stack.getFirst().equals("open")){
	    build_node_from_stack();
	    if(operator_stack.isEmpty()){break;}
	}
        operator_stack.pop();
    }
    
    public void end(){
	while(!operator_stack.isEmpty()){
	    build_node_from_stack();}
	updateRoot();
	post_order(root);
	//	ir_list.addLast(new IRNode("STORE"+type, root.value, null, lhs.name));
	//	table.addTempReg(lhs.name, getTempCount());
	if (lhs == null){
			// Store the constant in a Temp for comparison! :-)
			if ( (!root.value.contains("!T")) && (table.getSymbol(root.value) == null) ){
			    if(!func_call){
				 if(lhs_cond){
						if(root.value.contains("$"))
			       	  {return;}
				        }

			                 ir_list.addLast(new IRNode("STORE"+type.toUpperCase(), root.value, null, getNewTemp()));
			    //	System.out.println(type);
			                 if (rhs_cond){
				            root.value = getLatestTemp();
			                 }
				    }
			    }
			return;
	}

		// check if rhs is just a symbol (can't assign directly!)!
		if (table.getSymbol(root.value) != null ){
			ir_list.addLast(new IRNode("STORE"+type.toUpperCase(), root.value, null, getNewTemp()) );			
			table.addTempReg(root.value, getTempCount());
			ir_list.addLast(new IRNode("STORE"+type.toUpperCase(), getLatestTemp(), null, lhs.name));
		}
		// else just assign it to lhs
		else{
		    if(table.getLocal(lhs.name) != null){
			ir_list.addLast(new IRNode("STORE"+type.toUpperCase(),root.value,null,table.getLocal(lhs.name).value));}
		    else{
			ir_list.addLast(new IRNode("STORE"+type.toUpperCase(), root.value, null, lhs.name));
			table.addTempReg(lhs.name, getTempCount());
		}
		}
    }                           
    
    private void updateRoot(){
	if (!expression_stack.isEmpty()){
	    root = (ExpressionNode) expression_stack.pop();
	}
    }
    private int getPrecedence(String operator){
		return precedence_map.get(operator).intValue();
    }

    // Li bian shu
    public int getTempCount(){return temp_count.intValue();}
    private String getLatestTemp(){return ("!T" + temp_count.toString());}
    private String getNewTemp(){
	temp_count+=1;
	return getLatestTemp();
	}
    
    private IRNode createIRNode(ExpressionNode node){
	if (node.value.equals("+")){return new IRNode("ADD"+type, node.op1.value, node.op2.value, getNewTemp());} // add
	else if (node.value.equals("-")){return new IRNode("SUB"+type, node.op1.value, node.op2.value, getNewTemp());} // sub
	else if (node.value.equals("*")){return new IRNode("MULT"+type, node.op1.value, node.op2.value, getNewTemp());} // mul
	else if (node.value.equals("/")){return new IRNode("DIV"+type, node.op1.value, node.op2.value, getNewTemp());} // div	
	else {
	    if (node.value.contains("$")){return null;}
		
	    if (table.getParam(node.value) != null){ // is a symbol
		node.value = table.getParam(node.value).value;
		return null;}
            if(table.getLocal(node.value) != null){
		node.value = table.getLocal(node.value).value;
		return null;
	    }
            if (table.getSymbol(node.value) != null){
		    if(table.getTempReg(node.value)){
			return null;
		    }
 
		    else{
			getNewTemp();
			table.addTempReg(node.value, getTempCount());
			return new IRNode("STORE"+type, node.value, null, getLatestTemp());
		} 
	    }
	    else{ // is a literal
		return new IRNode("STORE"+type, node.value, null, getNewTemp()); // store temp
	    }
	}
	}
    private void Merge(ExpressionNode node, String replacment_value){
	node.op1 = null;
	node.op2 = null;
	node.value = replacment_value;
    }
    private void post_order(ExpressionNode node){
	if (node.op1 != null){
	    post_order(node.op1);
	}
	if (node.op2 != null){
	    post_order(node.op2);
	}
	
	IRNode newIR = createIRNode(node);
		if (newIR != null){
		    ir_list.addLast(newIR);
		    Merge(node, getLatestTemp());
		}
    }
  
    
}
