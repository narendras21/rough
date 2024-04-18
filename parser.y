%{
#include <iostream>
#include <string>
#include <cstring>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <map>
#include <vector>
#include <stack>
#include <utility>
#include<bits/stdc++.h>
using namespace std;

extern FILE *yyin;
extern int yylineno;
extern char* yytext;



///////////////////////////////////////////////////////////////////////
//start modifying
///////////////////////////////////////////////////////////////////////
string asm_file = "asm.s";
class quad{
    public:
    string op;
    string arg1;
    string arg2;
    string result;
    string code = "";        // Construct from each node
    string insType = "";     // instruction type
    int rel_jump = 0, abs_jump = 0, ins_line = 0;
    int made_from = 0;
    bool is_target = false;
    
    enum code_code {
        BINARY,
        UNARY,
        ASSIGNMENT,
        CONDITIONAL,
        CAST,
        STORE,
        LOAD,
        FUNC_CALL,
        GOTO,
        BEGIN_FUNC,
        END_FUNC,
        RETURN,
        SHIFT_POINTER,
        PUSH_PARAM,
        POP_PARAM,
        RETURN_VAL
    };

    quad();
    quad(string r, string a1, string o, string a2, string ins){
        this->result = r;
        this->arg1 = a1;
        this->op = o;
        this->arg2 = a2;
        this->insType = ins;
    };     // res = arg1 op arg2
    // void make_code();                                   // Recreate code
    // void make_code_from_binary();                       // r = a1 op a2;
    // void make_code_from_unary();                        // r = op a1;
    // void make_code_from_assignment();                   // r = a1;
    // void make_code_from_conditional();                  // IFTRUE/FALSE a1 GOTO [filled later using check_jump()];
    // void make_code_from_cast();                         // r = (a2) a1;
    // void make_code_from_store();                        // *(r) = a1;
    // void make_code_from_load();                         // r = *(a1);
    // void make_code_from_func_call();                    // callfunc a1;
    // void make_code_from_goto();                         // GOTO a1;
    // void make_code_begin_func();                        // begin_func x;
    // void make_code_end_func();                          // end_func;
    // void make_code_from_return();                       // return a1;
    // void make_code_shift_pointer();                     // shift stack pointer
    // void make_code_push_param();                        // pushparam a1;
    // void make_code_pop_param();                         // r = popparam;
    // void make_code_from_return_val();                   // r = return_value;
    // void check_jump(const int);
};

void construct_subroutine_table(vector<quad> subroutine_ins);

const int stack_offset = 8;
int func_count = 0;
map<string, string> func_name_map;

class instruction{
    public:

    string op = "";
    string arg1 = "";
    string arg2 = "";
    string arg3 = "";
    string code = "";
    string ins_type = "";

    string comment = "";

    // instruction(){}
    instruction(string op = "", string a1 = "", string a2 = "", string a3 = "", string it = "ins", string comment = ""):op(op), arg1(a1), arg2(a2), arg3(a3), ins_type(it), comment(comment){
        
        if(it == "ins") {           // default instructions
            cout<<"Inside default instruction: op = "<<op<<", arg1= "<<a1<<", arg2= "<<a2<<endl;
            if(arg3 == "") {
                code = "\t\t" + op;
                if(arg1 != ""){
                    code += "\t" + arg1;
                } 
                if(arg2 != ""){
                    code += ",\t" + arg2;
                }
            }
            else {

            }
        }
        else if(it == "segment") {  // text segment, global segment
            code = op;
            if(a1 != "") {
                code += "\t" + a1;
            }
        }
        else if(it == "label") {    // jump labels and subroutine labels
            code = arg1 + ":";
        }
        else if(it == "comment") {
            code = "\n\t\t# " + comment;
            return;
        }
        else {                      // other instruction types if used

        }
        if(comment != ""){
            code += "\t\t# " + comment;
        }
        code += "\n";
    }
    // void gen_code();
};




vector<instruction> make_x86_code(quad, int x = 0, int y = 0, int z = 0);
vector< vector<quad> > subroutines;
vector<instruction> code;

bool isVariable(string s);
bool isMainFunction(string s);

void gen_fixed_subroutines();
void gen_text();
void gen_global();
void get_tac_subroutines();
void print_code(string asm_file = "asm.s");

class subroutine_entry{
    public:

    string name = "";
    int offset = 0;         // offset from the base pointer in subroutine

    subroutine_entry(){}
    subroutine_entry(string name, int offset){
        this -> name = name;
        this -> offset = offset;
    }
    // other entries may be added later
};

class subroutine_table{
    public:

    string subroutine_name;
    bool is_main_function = false;
    map<string, subroutine_entry> lookup_table;
    int total_space;
    int number_of_params = 0;

    subroutine_table(){}

    void construct_subroutine_table(vector<quad> subroutine_ins) {
        int pop_cnt = 2;         // 1 8 byte space for the return address + old base pointer
        int local_offset = 8;    // 8 callee saved registers hence, 8 spaces kept free, rsp shall automatically be restored, rbp too
        
        for(quad q : subroutine_ins) {
            if(q.insType == "begin_func" || q.insType == "shift_pointer" || q.insType == "func_call") {   // No nested procedures
                continue; 
            }
            
            if(q.insType == "pop_param") {
                this -> lookup_table[q.result] = subroutine_entry(q.result, stack_offset*pop_cnt);
                pop_cnt++;
            }
            else {
                if(q.insType == "conditional") {
                    if(this -> lookup_table.find(q.arg1) == this -> lookup_table.end() && isVariable(q.arg1)) {
                        this -> lookup_table[q.arg1] = subroutine_entry(q.arg1, -stack_offset*local_offset);
                        local_offset++;
                    }
                }
                else if(q.insType == "goto"){
                    continue;
                }
                else {
                    if(q.arg1 != "" && this -> lookup_table.find(q.arg1) == this -> lookup_table.end() && isVariable(q.arg1)) {
                        this -> lookup_table[q.arg1] = subroutine_entry(q.arg1, -stack_offset*local_offset);
                        local_offset++;
                    }
                    else if(q.arg2 != "" && this -> lookup_table.find(q.arg2) == this -> lookup_table.end() && isVariable(q.arg2)) {
                        this -> lookup_table[q.arg2] = subroutine_entry(q.arg2, -stack_offset*local_offset);
                        local_offset++;
                    }
                    else if(q.result != "" && this -> lookup_table.find(q.result) == this -> lookup_table.end() && isVariable(q.result)) {
                        this -> lookup_table[q.result] = subroutine_entry(q.result, -stack_offset*local_offset);
                        local_offset++;
                    }
                    cout<<" :"<<stack_offset*(local_offset-1)<<endl;
                }
            }
        }

        this -> total_space = stack_offset * local_offset;   // total space occupied by callee saved registers + locals + temporaries
    }
};

vector<subroutine_table* > sub_tables;
void gen_basic_block(vector<quad> BB, subroutine_table*);
void gen_tac_basic_block(vector<quad> subroutine, subroutine_table*);
 void append_ins(instruction ins);


void append_ins(instruction ins);

void get_tac_subroutines();                             // generates all the subroutines from the tac
void gen_tac_basic_block(vector<quad>, subroutine_table*);      // generates all the basic blocks from subroutines

bool isVariable(string s);
bool isMainFunction(string s);
// string get_func_name(string s);          

// void gen_global();                                      // generates code for the global region
void gen_text();                                        // generates code for the text region
void gen_fixed_subroutines();                           // generates some fixed subroutines
void gen_subroutine(vector<quad> subroutine);           // generates code for individual subroutines
    // generates code for basic blocks

bool isVariable(string s) {   // if the first character is a digit/-/+, then it is a constant and not a variable
    // Undefined behaviour when s is ""
    if(s == "") {
        cout << "Empty string is neither constant/variable. Aborting...";
        exit(1);
    }
    return !(s[0] >= '0' && s[0] <= '9') && (s[0] != '-') && (s[0] != '+');
}

bool isMainFunction(string s) {
    string sub = "";
    for(int i = s.length() - 1; i >= 0; i--) {
        if(s[i] == '.') {
            break;
        }
        else {
            sub += s[i];
        }
    }

    return sub == "][gnirtS@niam";
}

// string get_func_name(string s) {
//     if(func_name_map.find(s) == func_name_map.end()) {
//         func_count++;
//         func_name_map[s] = "func" + to_string(func_count);
//     }

//     return func_name_map[s];
// }


void gen_global() {
    // @TODO
    instruction ins;
    ins = instruction(".data", "", "", "", "segment");
    cout<<"Done at line no. 286"<<endl;
    code.push_back(ins);

    ins = instruction("integer_format:", ".asciz", "\"%ld\\n\"", "", "ins");
    code.push_back(ins);

    ins = instruction(".global", "main", "", "", "segment");      // define entry point
    code.push_back(ins);
}

/*a = 3
b = 4
c = 5
d = 6

Location	Operator	arg 1	arg 2	Result
(0)	=	3	-	a
(1)	=	4	-	b
(2)	=	5	-	c
(3)	=	6	-	d
(4)	>	a	b	temp1
(5)	ifTrue	temp1	-	L1
(6)	+	c	d	x
(7)	goto	-	-	L2
(8)	L1	-	-	-
(9)	-	c	d	x
(10)L2	-	-	-
(11)+	a	b	y
(12)+	x	y	temp2
(13)print	temp2	-	-


push_param a1
call_func print 1(arg2)

*/

//quad(result, arg1, op, arg2, insType)
//insType = binary, unary, assignment, conditional, cast, store, load, func_call, goto, begin_func, end_func, return, shift_pointer, push_param, pop_param, return_val
vector<quad>tacQuads = {
    quad("","main", "begin_func", "", "begin_func"),
    quad("a", "3", "=", "", "assignment"),
    quad("b", "4", "=","","assignment"),
    quad("c", "5", "=", "", "assignment"),
    quad("d", "6", "=", "", "assignment"),
    quad("temp1", "a", ">", "b", "binary"),
    quad("", "temp1", "ifTrue", "L1", "conditional"),
    quad("x", "c", "+", "d", "binary"),
    quad("", "", "", "L2", "goto"),
    quad("", "L1", "", "", "label"),
    quad("x", "c", "-", "d", "binary"),
    quad("", "L2", "", "", "label"),
    quad("y", "a", "+", "b", "binary"),
    quad("temp2", "x", "+", "y", "binary"),
    quad("","temp2","","","push_param"),
    quad("","print","","1","func_call"),
    quad("","main", "end_func", "", "end_func"),
};

void append_ins(instruction ins) {
    code.push_back(ins);
}

void get_tac_subroutines() {
    vector<quad> subroutine;

    bool func_started = false;
   
    for(auto q : tacQuads) {
        cout<<q.arg1<<endl;
        if(q.op == "begin_func") {
            func_started = true;
        }

        if(func_started) {
            subroutine.push_back(q);
        }

        if(q.op == "end_func") {
            func_started = false;
            if(subroutine.size()){
                subroutines.push_back(subroutine);
                subroutine.clear();
            }
        }
    }
}

void gen_basic_block(vector<quad> BB, subroutine_table* sub_table) {
    for(quad q : BB) {
        vector<instruction> insts;
        if(q.insType == "conditional"){
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = q.abs_jump;
            insts = make_x86_code(q, x, y);
        }
        else if(q.insType == "goto"){
            insts = make_x86_code(q, q.abs_jump);
        }
        else if(q.insType == "binary"){
            int z = sub_table -> lookup_table[q.result].offset;
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = sub_table -> lookup_table[q.arg2].offset;
            insts = make_x86_code(q, x, y, z);            
        }
        else if(q.insType == "unary"){    // b(y) = op a(x)
            int y = sub_table -> lookup_table[q.result].offset;
            int x = sub_table -> lookup_table[q.arg1].offset;
            insts = make_x86_code(q, x, y);           
        }
        else if(q.insType == "assignment"){   // b(y) = a(x)
            int y = sub_table -> lookup_table[q.result].offset;
            int x = sub_table -> lookup_table[q.arg1].offset;
            insts = make_x86_code(q, x, y);                
        }
        else if(q.insType == "store"){        // *(r(z) + a2) = a1(x)
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = sub_table -> lookup_table[q.arg2].offset;   // always 0 since q.arg2 contains a constant always
            int z = sub_table -> lookup_table[q.result].offset;

            insts = make_x86_code(q, x, y, z);
        }
        else if(q.insType == "load"){         // r(z) = *(a1(x) + a2)
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = sub_table -> lookup_table[q.arg2].offset; // always 0 since q.arg2 contains a constant always
            int z = sub_table -> lookup_table[q.result].offset;

            insts = make_x86_code(q, x, y, z);
        }
        else if(q.insType == "cast"){         // b(y) = (op) a(x)
            int x = sub_table -> lookup_table[q.arg1].offset;
            int y = sub_table -> lookup_table[q.result].offset;
            insts = make_x86_code(q, x, y);
        }
        else if(q.insType == "push_param"){   // push_param a1(x)
            int x = sub_table -> lookup_table[q.arg1].offset;
            sub_table -> number_of_params++;
            insts = make_x86_code(q, x, sub_table -> number_of_params);
        }
        else if(q.insType == "pop_param"){   // r(x) = pop_param
            // no need to do anything really

            insts = make_x86_code(q);
        }
        else if(q.insType == "func_call") {
            insts = make_x86_code(q, sub_table -> number_of_params);
            sub_table -> number_of_params = 0;          // reset variable
        }
        else if(q.insType == "return_va") {
            insts = make_x86_code(q, sub_table -> lookup_table[q.result].offset);
        }
        else if(q.insType == "begin_func") {  // manage callee saved registers
            if(isMainFunction(q.arg1)) {
                sub_table -> is_main_function = true;
            }
            insts = make_x86_code(q, sub_table -> total_space - 8 * stack_offset, sub_table -> is_main_function);        // space of 8 registers is not considered
        }
        else if(q.insType == "end_func") {    // clean up activation record
            // ideally only reaches this place in a void function
            insts = make_x86_code(q, sub_table -> is_main_function, sub_table -> total_space - 8 * stack_offset);
        }
        else if(q.insType == "shift_pointer") {       // no need to do anything really
            insts = make_x86_code(q);
        }
        else if(q.insType == "return") {     // clean up activation record
            insts = make_x86_code(q, sub_table -> total_space - 8 * stack_offset, sub_table -> lookup_table[q.arg1].offset);
        }
        else{
            insts = make_x86_code(q);
        }

        // append all the instructions finally
        for(instruction ins : insts) {
            append_ins(ins);
        }
    }
}


void gen_tac_basic_block(vector<quad> subroutine, subroutine_table* sub_table) {    // generates basic blocks from subroutines
    set<int> leaders;
    vector<quad > BB;

    int base_offset = subroutine[0].ins_line;
    leaders.insert(base_offset);

    for(quad q : subroutine) {
        if(q.insType == "conditional"|| q.insType == "goto") {
            leaders.insert(q.abs_jump);
            leaders.insert(q.ins_line + 1);
        }
        else if(q.insType == "func_call") {
            leaders.insert(q.ins_line);
            leaders.insert(q.ins_line + 1); // call func is made of a singular basic block
        }
    }

    vector<int> ascending_leaders;
    for(int leader : leaders) { 
        ascending_leaders.push_back(leader); 
    }
    
    int prev_leader = ascending_leaders[0];
    for(int i = 1; i < ascending_leaders.size(); i++) {
        BB.clear();
        
        for(int j = prev_leader; j < ascending_leaders[i]; j++) {
            BB.push_back(subroutine[j - base_offset]);
        }
        prev_leader = ascending_leaders[i];

        gen_basic_block(BB, sub_table);
    }

    BB.clear();
    int final_leader = ascending_leaders[ascending_leaders.size() - 1];
    for(int i = final_leader; i - base_offset < subroutine.size(); i++) {
        BB.push_back(subroutine[i - base_offset]);
    }

    gen_basic_block(BB, sub_table);
}

void gen_fixed_subroutines() {
    func_name_map["print"] = "print";
    func_name_map["allocmem"] = "allocmem";
}



void gen_text() {
    instruction ins(".text", "", "", "", "segment");
    code.push_back(ins);

    gen_fixed_subroutines();

    get_tac_subroutines();      // get the subroutines from entire TAC

    for(auto subroutine : subroutines) {
        subroutine_table* sub_table = new subroutine_table();
        sub_table -> construct_subroutine_table(subroutine);

        sub_tables .push_back(sub_table);
        gen_tac_basic_block(subroutine, sub_table);
    }
}



vector<instruction> make_x86_code(quad q, int x, int y, int z){

    vector<instruction> insts;
    instruction ins;

    // if(q.code == ""){
    //     return insts;        
    // }
    // else{
    //     if(q.insType != "shift_pointer" && q.insType != "pop_param"){
    //         ins = instruction("", "", "", "", "comment", q.code.substr(2, q.code.size() - 2));
    //         insts.push_back(ins);
    //     }
    // }

    if(q.is_target) {   // if this is a target, a label needs to be added
        ins = instruction("", "L" + to_string(q.ins_line), "", "", "label");
        insts.push_back(ins);
    }
    if(q.insType == "binary"){            // c(z) = a(x) op b(y)
        // Load value of a into %rax
        if(q.op == "+"){
            cout << "Adding " << q.arg1 << " and " << q.arg2 << endl;
           
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");

            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("add", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("add", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "-"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("sub", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("sub", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "*"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("imul", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("imul", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "/"){
            if(!isVariable(q.arg1)){   // arg1 is a literal
                ins = instruction("movq", "$" + q.arg1, "%rax");
                insts.push_back(ins);
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rax");
                insts.push_back(ins);                
            }
            ins = instruction("cqto");
            insts.push_back(ins);

            if(!isVariable(q.arg2)){  // arg2 is a literal
                ins = instruction("movq", "$" + q.arg2, "%rbx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rbx");
            }
            insts.push_back(ins);
            ins = instruction("idiv", "%rbx", "");
            insts.push_back(ins);
            ins = instruction("movq", "%rax" + ',', "%rdx");
        }
        else if(q.op == "%"){
            if(!isVariable(q.arg1)){   // arg1 is a literal
                ins = instruction("movq", "$" + q.arg1, "%rax");
                insts.push_back(ins);
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rax");
                insts.push_back(ins);                
            }
            ins = instruction("cqto");
            insts.push_back(ins);

            if(!isVariable(q.arg2)){  // arg2 is a literal
                ins = instruction("movq", "$" + q.arg2, "%rbx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rbx");
            }
            insts.push_back(ins);
            ins = instruction("idiv", "%rbx", "");
        }
        else if(q.op == "<<"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("sal", "%cl", "%rdx");
        }
        else if(q.op == ">>"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("sar", "%cl", "%rdx");
        }
        else if(q.op == ">>>"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("shr", "%cl", "%rdx");
        }
        else if(q.op == ">"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "%rd999x", "%rcx");
            insts.push_back(ins);
            ins = instruction("jl", "1f");  // true
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f"); // false
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        else if(q.op == "<"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = instruction("jg", "1f");  // true
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f"); // false
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        else if(q.op == ">="){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = instruction("jle", "1f");  // true
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f"); // false
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        else if(q.op == "<="){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = instruction("jge", "1f");  // true
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f"); // false
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        else if(q.op == "=="){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = instruction("je", "1f");  // true
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f"); // false
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        else if(q.op == "!="){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);

            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rcx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rcx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "%rdx", "%rcx");
            insts.push_back(ins);
            ins = instruction("jne", "1f");  // true
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f"); // false
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        else if(q.op == "&"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("and", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("and", to_string(y) + "(%rbp)", "%rdx");
            }     
        }
        else if(q.op == "|"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("or", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("or", to_string(y) + "(%rbp)", "%rdx");
            }     
        }
        else if(q.op == "^"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("xor", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("xor", to_string(y) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "&&"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("je", "1f");
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("je", "1f");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        else if(q.op == "||"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jne", "1f");     // true
            insts.push_back(ins);
            if(!isVariable(q.arg2)){
                ins = instruction("movq", "$" + q.arg2, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = instruction("cmp", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jne", "1f");     // true
            insts.push_back(ins);
            ins = instruction("movq", "$0", "%rdx");
            insts.push_back(ins);
            ins = instruction("jmp", "2f");     // false
            insts.push_back(ins);
            ins = instruction("", "1", "", "", "label");
            insts.push_back(ins);
            ins = instruction("movq", "$1", "%rdx");
            insts.push_back(ins);
            ins = instruction("", "2", "", "", "label");
        }
        insts.push_back(ins);
        
        ins = instruction("movq", "%rdx", to_string(z) + "(%rbp)");
        insts.push_back(ins);
    }
    else if(q.insType == "unary"){        // b(y) = op a(x)
        if(q.op == "~"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = instruction("neg", "%rdx", "");
        }
        else if(q.op == "!"){
            if(!isVariable(q.arg1)){
                ins = instruction("movq", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            }
            insts.push_back(ins);
            ins = instruction("not", "%rdx", "");
        }
        else if(q.op == "-"){
            ins = instruction("xor", "%rdx", "%rdx");
            insts.push_back(ins);
            if(!isVariable(q.arg1)){
                ins = instruction("sub", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("sub", to_string(x) + "(%rbp)", "%rdx");
            }
        }
        else if(q.op == "+"){
            ins = instruction("xor", "%rdx", "%rdx");
            insts.push_back(ins);
            if(!isVariable(q.arg1)){
                ins = instruction("add", "$" + q.arg1, "%rdx");
            }
            else{
                ins = instruction("add", to_string(x) + "(%rbp)", "%rdx");
            }
        }
        insts.push_back(ins);
        
        ins = instruction("movq", "%rdx", to_string(y) + "(%rbp)");
        insts.push_back(ins);
    }
    else if(q.insType == "assignment"){   // b(y) = a(x)
        if(!isVariable(q.arg1)){
            ins = instruction("movq", "$" + q.arg1+",", to_string(y) + "(%rbp)");
            insts.push_back(ins);
        }
        else{
            ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
            insts.push_back(ins);            
            ins = instruction("movq", "%rdx", to_string(y) + "(%rbp)");
            insts.push_back(ins);
        }
    }
    else if(q.insType == "conditional"){  // if_false/if_true(op) a(x) goto y
        if(!isVariable(q.arg1)){
            ins = instruction("movq", "$" + q.arg1, "%rdx");
        }
        else{
            ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
        }
        insts.push_back(ins);
        ins = instruction("cmp", "$0", "%rdx");
        insts.push_back(ins);
        
        if(q.op == "ifFalse"){
            //ins = instruction("je", "L" + to_string(y));
            ins = instruction("je", q.arg2);

        }
        else if(q.op == "ifTrue"){
            // ins = instruction("jne", "L" + to_string(y));
            ins = instruction("jne", q.arg2);
        }
        insts.push_back(ins);
    } 
    else if(q.insType == "goto"){         // goto (x)
        // ins = instruction("jmp", "L" + to_string(x));
        ins = instruction("jmp", q.arg2);
        insts.push_back(ins);
    }
    else if(q.insType == "store"){        // *(r(z) + a2) = a1(x)
        if(!isVariable(q.arg1)){
            ins = instruction("movq", "$" + q.arg1, "%rax");
        }
        else{
            ins = instruction("movq", to_string(x) + "(%rbp)", "%rax");
        }
        insts.push_back(ins);
        
        ins = instruction("movq", to_string(z) + "(%rbp)", "%rdx");
        insts.push_back(ins);

        if(q.arg2 == "" || !isVariable(q.arg2)) {
            ins = instruction("movq", "%rax", q.arg2 + "(%rdx)");
            insts.push_back(ins);
        }
        else {
            cout << "Unknown TAC `" << q.code << "`. Cannot make load from this code!" << endl;
            exit(1);  
        }
    }
    else if(q.insType == "load"){         // r(z) = *(a1(x) + a2(y))
        ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx");
        insts.push_back(ins);

        if(q.arg2 == "" || !isVariable(q.arg2)) {
            ins = instruction("movq", q.arg2 + "(%rdx)", "%rdx");
            insts.push_back(ins);
        }
        else {
            cout << "Unknown TAC `" << q.code << "`. Cannot make load from this code!" << endl;
            exit(1);
        }

        ins = instruction("movq", "%rdx", to_string(z) + "(%rbp)");
        insts.push_back(ins);
    }
    else if(q.insType == "begin_func") {  // perform callee duties
        if(y == 1) {        // make start label if it is the main function
            ins = instruction("", "main", "", "", "label");
            insts.push_back(ins);
        }

        ins = instruction("", q.arg1, "", "", "label");     // add label
        insts.push_back(ins);


        ins = instruction("pushq", "%rbp");      // old base pointer
        insts.push_back(ins);
        ins = instruction("movq", "%rsp,", "%rbp");    // shift base pointer to the base of the new activation frame
        insts.push_back(ins);
        ins = instruction("pushq", "%rbx");
        insts.push_back(ins);
        ins = instruction("pushq", "%rdi");
        insts.push_back(ins);
        ins = instruction("pushq", "%rsi");
        insts.push_back(ins);
        ins = instruction("pushq", "%r12");
        insts.push_back(ins);
        ins = instruction("pushq", "%r13");
        insts.push_back(ins);
        ins = instruction("pushq", "%r14");
        insts.push_back(ins);
        ins = instruction("pushq", "%r15");
        insts.push_back(ins);

        // shift stack pointer to make space for locals and temporaries, ignore if no locals/temporaries in function
        if(x > 0) {
            ins = instruction("sub", "$" + to_string(x), "%rsp");
            insts.push_back(ins);
        }
    }
    else if(q.insType == "return") {    // clean up activation record
        if(q.arg1 != "") {      // Load %rax with the return value if non-void function
            if(!isVariable(q.arg1)) {
                ins = instruction("movq", "$" + q.arg1, "%rax");
            }
            else {
                ins = instruction("movq", to_string(y) + "(%rbp)", "%rax");
            }
            insts.push_back(ins);
        }
        
        ins = instruction("add", "$" + to_string(x), "%rsp");   // delete all local and temporary variables
        insts.push_back(ins);
        ins = instruction("popq", "%r15");                      // restore old register values
        insts.push_back(ins);
        ins = instruction("popq", "%r14");
        insts.push_back(ins);
        ins = instruction("popq", "%r13");
        insts.push_back(ins);
        ins = instruction("popq", "%r12");
        insts.push_back(ins);
        ins = instruction("popq", "%rsi");
        insts.push_back(ins);
        ins = instruction("popq", "%rdi");
        insts.push_back(ins);
        ins = instruction("popq", "%rbx");
        insts.push_back(ins);
        ins = instruction("popq", "%rbp");
        insts.push_back(ins);

        ins = instruction("ret");
        insts.push_back(ins);
    }
    else if(q.insType == "end_func") {
        if(x == 1) {        // if main function
            ins = instruction("movq", "$60", "%rax");
            insts.push_back(ins);
            ins = instruction("xor", "%rdi", "%rdi");
            insts.push_back(ins);
            ins = instruction("syscall");
            insts.push_back(ins);
        }
        else {              // otherwise we perform usual callee clean up
            // end func cannot return any values    
            ins = instruction("add", "$" + to_string(y), "%rsp");   // delete all local and temporary variables
            insts.push_back(ins);
            ins = instruction("popq", "%r15");                      // restore old register values
            insts.push_back(ins);
            ins = instruction("popq", "%r14");
            insts.push_back(ins);
            ins = instruction("popq", "%r13");
            insts.push_back(ins);
            ins = instruction("popq", "%r12");
            insts.push_back(ins);
            ins = instruction("popq", "%rsi");
            insts.push_back(ins);
            ins = instruction("popq", "%rdi");
            insts.push_back(ins);
            ins = instruction("popq", "%rbx");
            insts.push_back(ins);
            ins = instruction("popq", "%rbp");
            insts.push_back(ins);
            ins = instruction("ret");
            insts.push_back(ins);
        }
    }
    else if(q.insType == "shift_pointer") {
        // no need to do anything really for x86
    }
    else if(q.insType == "func_call") {
        if(x == 0) {        // if function is called without any parameters, we have yet to perform caller responsibilities
            ins = instruction("pushq", "%rax");
            insts.push_back(ins);
            ins = instruction("pushq", "%rcx");
            insts.push_back(ins);
            ins = instruction("pushq", "%rdx");
            insts.push_back(ins);
            ins = instruction("pushq", "%r8");
            insts.push_back(ins);
            ins = instruction("pushq", "%r9");
            insts.push_back(ins);
            ins = instruction("pushq", "%r10");
            insts.push_back(ins);
            ins = instruction("pushq", "%r11");
            insts.push_back(ins);
        }
        ins = instruction("call", q.arg1);      // call the function
        insts.push_back(ins);

        if(q.arg1 == "print"){          // deal specially with print
            ins = instruction("add", "$8", "%rsp");
            insts.push_back(ins);
        }
        else if(q.arg1 == "allocmem") {
            ins = instruction("add", "$8", "%rsp");             // deal specially with allocmem
            insts.push_back(ins);
        }
        else if(x > 0) {                             // pop the parameters
            ins = instruction("add", "$" + to_string(x*stack_offset), "%rsp");
            insts.push_back(ins);
        }
    }
    else if(q.insType == "return_val") {
        // move the return value stored in %rax to the required location
        if(q.result != "") {      // if the function returns a value
            ins = instruction("mov", "%rax", to_string(x) + "(%rbp)");
            insts.push_back(ins);
        }

        // restore original state of registers
        ins = instruction("popq", "%r11");
        insts.push_back(ins);
        ins = instruction("popq", "%r10");
        insts.push_back(ins);
        ins = instruction("popq", "%r9");
        insts.push_back(ins);
        ins = instruction("popq", "%r8");
        insts.push_back(ins);
        ins = instruction("popq", "%rdx");
        insts.push_back(ins);
        ins = instruction("popq", "%rcx");
        insts.push_back(ins);
        ins = instruction("popq", "%rax");
        insts.push_back(ins);
    }
    else if(q.insType == "push_param"){   // pushq a(x) || pushq const
        if(y == 1) {        // first parameter, perform caller saved registers
            ins = instruction("pushq", "%rax");
            insts.push_back(ins);
            ins = instruction("pushq", "%rcx");
            insts.push_back(ins);
            ins = instruction("pushq", "%rdx");
            insts.push_back(ins);
            ins = instruction("pushq", "%r8");
            insts.push_back(ins);
            ins = instruction("pushq", "%r9");
            insts.push_back(ins);
            ins = instruction("pushq", "%r10");
            insts.push_back(ins);
            ins = instruction("pushq", "%r11");
            insts.push_back(ins);
        }
        if(!isVariable(q.arg1)) {  // it is just a constant
            ins = instruction("pushq", "$" + q.arg1, "");
            insts.push_back(ins);
        } 
        else {
            ins = instruction("pushq", to_string(x) + "(%rbp)"); // load rbp + x
            insts.push_back(ins);    
        }
    }
    else if(q.insType == "cast"){     // r(y) = (op) a(x)
        if(!isVariable(q.arg1)) {  // it is a constant
            ins = instruction("movq", "$" + q.arg1, "%rdx");
        } 
        else {
            ins = instruction("movq", to_string(x) + "(%rbp)", "%rdx"); // load rbp + x
        }
        insts.push_back(ins);    
        ins = instruction("movq", "%rdx", to_string(y) + "(%rbp)");
        insts.push_back(ins);    
    }
    else if(q.insType == "label"){    // label Lx
        ins = instruction("", q.arg1, "", "", "label");
        insts.push_back(ins);
    }

    return insts;
}


void print_code(string asm_file) {
    ofstream out(asm_file);
    cout<<"printing code"<<endl;
    if(asm_file == "") {
        for(auto ins : code) {
            out<<ins.code<<endl;
        }
    }
    else {
        for(auto ins : code) {
            out<<ins.code<<endl;
        }
    }

    ifstream print_func("print_func.s");
    string line;

    while(getline(print_func, line)){
        out << line << '\n';
    }

    ifstream alloc_mem("allocmem.s");
    while(getline(alloc_mem, line)) {
        out << line << '\n';
    }
}


////////////////////////////////////////////////////////////////
//end modifying
////////////////////////////////////////////////////////////////

int yylex();
void yyerror(const char *s);
void tacToAssembly(ofstream& file, FILE*assem);
string instrType(string op);


map<int, pair<string, vector<int>>> AST;
int nodeCount = -1;

void ParentToChild(int parent, int child) {
  (AST[parent].second).push_back(child);
}

int nodeInit(string nodeName) {
    nodeCount++;
    string name = nodeName;
    vector<int> children;
    AST[nodeCount].first = name;
    AST[nodeCount].second = children;
    return nodeCount;
}


void write_gv(string &filename) {
  ofstream out(filename);
  if (!out.is_open()) {
    cerr << "ERROR: gv file can't be opened ";
    return;
  }

  out << "digraph AST {\n";
  
  for (const auto &node : AST) {
    int nodeId = node.first;
    string nodeName = node.second.first;
    vector<int> nodeChildren = node.second.second;

    out << nodeId << " [label=\"" << nodeName << "\"];\n";
    for (auto c : nodeChildren) {
      if (c>=0) {
        out << nodeId << "->" << c << ";\n";
      }
    }
  }

  out << "}";
  out.close();
}

int debug = 0;
void debugging(string msg, int mode){
    // if(debug == mode){
    //     cout <<"||->"<< msg << endl;
    // }

}

int getSize(string type){
    if(type == "int"){return 4;}
    else if(type == "float"){return 8;}
    else if(type == "str"){return 256;}
    else if(type == "string"){return 256;}
    else if(type == "bool"){return 1;}
    else if(type.compare(0,4,"list") ==0){
        return 8; //pointer 
    }
    else if(type=="none") {return 1;}
    else if(type =="class"){return 100;}
    else {
        return 8;
    }
}

//Sym entry globals
int num_args = 0;
int param_num = -1;

class SymbolEntry {
      public:
        string token;
        string type;
        int size;
        string scope_name;
        int offset;
        int lineno;

        //function
        string rtype;
        int num_args;
        int arg_num;

        string par_arg_shape; //to get shape of parameters of args

        
        //constructor
        SymbolEntry(){ 
        }

        SymbolEntry(string token, string type, int size, int offset, string scope_name, int lineno, int num_args, int arg_num){
          this->token = token;
          this->type = type;
          this->size = size;
          this->offset = offset;
          this->scope_name = scope_name;
          this->lineno = lineno;
          this->num_args= num_args;
          this->arg_num = arg_num;
          
        }
        void print_entry(){
          cout << token << " " << type << " " << size << " " << offset << " " << scope_name << " " << lineno << " "<<num_args << " "<<arg_num<< endl;
        }
};

string found_table;

class SymbolTable {
    public:
        map <pair<string,string>, SymbolEntry> Table;
        SymbolTable* Parent;
        string TableName;
        string Signature;
        vector<SymbolTable*> childTables;
        int level_no;

        //puts in entry into this symbol table
        void entry(string lexeme, string sig, string token, string type, int size,  int offset, string scope_name, int line, int num_args, int arg_num){
            pair<string, string> id = {lexeme, sig};
            Table[id] = SymbolEntry(token, type, size, offset, scope_name, line, num_args, arg_num);
        }

        SymbolTable(){}
        SymbolTable(SymbolTable* P, string name, string signature){
            if(!P){
                level_no = 0;
                Parent = NULL;
                TableName = name;
                Signature = signature;
            }
            else{
                level_no = P->level_no + 1;
                Parent = P;
                P->childTables.push_back(this);
                TableName = name;
                Signature = signature;
            }
        }

        SymbolEntry* lookup(pair<string,string>id){
            for(auto it=this; it!=NULL; it=it->Parent){
                // pair<string, string> id = {lexeme, signature};
                if(it->Table.find(id) != it->Table.end()){
                    found_table = it->TableName;
                    // cout << "fouond_table " << found_table << endl;
                    return &(it->Table[id]);
                }
            }
            return NULL;
        }  

        // SymbolEntry* funcLookup(string lexeme){
        //     for(auto it=this; it!=NULL; it=it->Parent){
        //         if(it->Table.find(lexeme) != it->Table.end()){
        //             return &(it->Table[lexeme]);
        //         }
        //     }
        //     return NULL;
        // }

        // SymbolEntry* findMethod(string method){
        //     if(Table.find(method)!= Table.end()){
        //         //found
        //         return &(Table[method]);
        //     }
        //     return NULL;
        // }     

        void print_table(){
            cout << "table name: " << TableName << endl;
            for(auto it=Table.begin(); it!=Table.end(); it++){
                cout<<it->first.first << "||" << it->first.second <<": ";
                it->second.print_entry();
            }
            if(!childTables.empty()){
                cout << "\nchild table(s) of: " << TableName << endl;
                    for( auto it: childTables){
                        // it->print_table();
                        cout << "name: "<< it->TableName << endl;
                    }
                    cout << endl;
            }
        }

        // string parShape(string func_name){
        //     //func_name assumed to exist already
        //     SymbolTable* funcTable;
        //     int flag = 0;
        //     for(SymbolTable* it : childTables ){
        //         if(it->TableName == func_name){
        //             funcTable = it;
        //             flag = 1;
        //             break;
        //         }
        //     }

        //     if(!flag){string s("$"); return s;}
        //     map<int, string> temp;
        //     for(auto it=(funcTable->Table).begin(); it!=(funcTable->Table).end(); it++){
        //         if( (it->second).token == "PARAM"){
        //             temp[(it->second).arg_num] = (it->second).type;
        //         }
        //     }
        //     string res = "";
        //     for(auto it = temp.begin(); it!=temp.end(); it++){
        //         res += it->second;
        //     }
        //     return res;

        // }
};

//sym entry globals
SymbolTable* curr_table = new SymbolTable(NULL, "global", "");
stack<SymbolTable*> tableStk;

int offset = 0;
stack<int> offsetStk;

string curr_scope_name = "global";
stack<string> scopeStk;

vector<SymbolTable*> TablesList (1,curr_table);
// TablesList.push_back(curr_table);  //gives error

//vector of (lexeme,lineno), (type, param_num)
vector< pair< pair<string,int>, pair<string, int> >> fparams;

//vector of (lexeme, (type, arg_num) )
vector< pair<string, pair<string, int>>> fargs;

//vector (funcname, scope_name)
vector< pair<string, string> > func_list;

char curr_return_type[100];

// list of classes in what???
//vector (classname, scope_name)
vector< pair<string, string> > class_list;


SymbolTable* findTable(string tableName, string signature){
     for( auto it: TablesList){
        if(it->TableName == tableName && it->Signature == signature){
            return it;
        }
    }
    return NULL;
}

int label_count = 0;
string getLabel(){
    return "L" + to_string(label_count++);
}
int temp_count = 0;
string getTemp(){
    return "t" + to_string(temp_count++);
}

char* concat(string str1, string str2) {
    if(str1.length()>0){
        str1  = str1 + "\n";
    }
    char* result = new char[str1.length() + str2.length() + 1];
    strcpy(result, str1.c_str());
    strcat(result, str2.c_str());
    return result;
}

string str(char* c){
    string s(c);
    return s;
}

char* cstar(string my_string){
    char* cp = new char[my_string.length() + 1]; 
    strcpy(cp, my_string.c_str());
    return cp;
}

char* nullCST() {
    char* null_string = new char[1];
    null_string[0] = '\0';
    return null_string;
}

string TAC_output = "";

stack<string> breakStk;
stack<string> contStk;

stack<string> endstartStk;
stack<string> successStk;


%}


%union{
    int nodeNum;
    char* text;
    
    struct{
        int nodeNum;
        int count;
        int size;
        int ndim;
        int nelem; 
        int is_self;        /*for self.x:int*/
        char lexeme[100];
        char type[100];
        char par_arg_shape[100];

        int list_size;

        char end_label[100];

        char break_[100];
        char cont_[100];

        
        char success_[100];
        char start_[100];
        char end_[100];
        
        char range_start[100];
        char range_end[100];
        char range_step[100];

        char* TAC;
        char res[100];

    } node;

}


%token NEWLINE

%token AS ASYNC ASSERT AWAIT BREAK CLASS CONTINUE DEF DEL ELIF ELSE EXCEPT FALSE FINALLY FOR FROM GLOBAL IF IMPORT IN IS LAMBDA NONE NONLOCAL PASS RAISE RETURN TRUE TRY WHILE WITH YIELD RANGE LEN PRINT


%token <text> NAME
%token <text> NUMBER
%token <text> NUMBER_INT
%token <text> NUMBER_FLOAT

%token INT FLOAT STR BOOL LIST

%token TRIPLE_DOT


%token MINUS PLUS ASTERISK FORWARDSLASH DOUBLESLASH DOUBLE_STAR NOT OR AND  LT_LT GT_GT AMPERSAND BAR CAP TILDE COLON_EQ LT GT LT_EQ GT_EQ EQ_EQ NOT_EQ PERCENT


%token <text>STRING

%token LPAREN RPAREN LCURLY RCURLY LSQUARE RSQUARE DOT COMMA COLON SEMICOLON RARR

%token AMPERSAND_EQ AT AT_EQ CAP_EQ DOUBLE_SLASH_EQ DOUBLE_STAR_EQ EQUALS FORWARDSLASH_EQ LT_GT LT_LT_EQ MINUS_EQ PERCENT_EQ PIPE_EQ PLUS_EQ RT_RT_EQ STAR_EQ


%left LT GT LT_EQ GT_EQ 
%left PLUS MINUS ASTERISK FORWARDSLASH DOUBLESLASH
%left OR AND
%left PERCENT DOUBLE_STAR GT_GT 
%left AT


%right EQUALS PLUS_EQ MINUS_EQ STAR_EQ FORWARDSLASH_EQ DOUBLE_SLASH_EQ PERCENT_EQ AT_EQ AMPERSAND_EQ PIPE_EQ CAP_EQ RT_RT_EQ LT_LT_EQ DOUBLE_STAR_EQ 

%right TILDE COLON_EQ NOT


%token INDENT
%token DEDENT
%token ENDMARKER


%type <node> input
%type <node> stmts
%type <node> normalstmt ending exprstmt listType stmt funccall delstmt globalstatement assignstmt assignments multiplicativeExpr ids vardeclaration typeDeclaration primitiveType numericType  listExpr expression logicalOr logicalAnd bitwiseOr bitwiseXor bitwiseAnd equalExpr shiftExpr addExpr expoExpr relExpr negated_expr nonlocalstmt primaryExpr arguments compoundstmt ifstatement elifstmts elifstmt elseblock whilestatement forstmt forexpr ForList funcdef parameters returnType Suite classdef returnnstmt funcheader classheader classarguments methodcall loop_action elif_action


%start input


%%
    

/* Starting symbol */
input 
        : stmts ending  {
            debugging("input", 1);
            $$.nodeNum = nodeInit("input");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $2.nodeNum);

            $$.TAC = concat($1.TAC, str($2.TAC));
            TAC_output = str($$.TAC);

            }
        |  ending {
            $$.nodeNum = nodeInit("input");
            ParentToChild($$.nodeNum, $1.nodeNum);

            $$.TAC = $1.TAC;
            TAC_output = str($$.TAC);

        }
        ;
    
stmts : 
        stmt   { 
            $$.nodeNum = nodeInit("stmts");
            ParentToChild($$.nodeNum,$1.nodeNum);
            debugging("stmts", 1);

            strcpy($$.end_label, $1.end_label);
            $$.TAC = $1.TAC;

        }
        | stmts stmt { 
            debugging("stmts", 1);

            $$.nodeNum = $1.nodeNum;
            ParentToChild($$.nodeNum, $2.nodeNum);

            strcpy($$.end_label, $2.end_label);
            $$.TAC = concat($1.TAC, str($2.TAC));
        
        }
        ;

globalstatement :
        GLOBAL NAME    { 
            debugging("global statement", 1);
            $$.nodeNum = nodeInit("Global");
            string name = $2;
            ParentToChild($$.nodeNum, nodeInit(name));

            string code = "global" + str($2);
            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, code);
            
        }
        ;
    
nonlocalstmt :
        NONLOCAL NAME  { 
            debugging("nonlocal statement", 1);
            $$.nodeNum = nodeInit("nonlocal");
            string name = $2;
            ParentToChild($$.nodeNum, nodeInit(name));

            string code = "global" + str($2);
            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, code);            
        }
        ;

stmt : 
        normalstmt NEWLINE  {
            $$.nodeNum = $1.nodeNum;
            debugging("stmt", 1);

            string s_end = getLabel();
            strcpy($$.end_label, s_end.c_str());
            $$.TAC = $1.TAC;
        }
        | compoundstmt  { 
            debugging("stmt", 1);
            $$.nodeNum = $1.nodeNum;

            string s_end = getLabel();
            strcpy($$.end_label, s_end.c_str());
            $$.TAC = $1.TAC;

        }
        ;


normalstmt :
        exprstmt     { 
            debugging("normalstmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        | delstmt              { 
            $$.nodeNum = $1.nodeNum;
            debugging("normalstmt", 1);

            $$.TAC = $1.TAC;
        }
        | BREAK           {
            debugging("normal break stmt", 1);    
            $$.nodeNum = nodeInit("break");

            $$.TAC = nullCST();
            string break_label = breakStk.top();
            string code = "goto " + break_label;
            $$.TAC = concat($$.TAC, code);       

        }
        | CONTINUE         { 
            $$.nodeNum = nodeInit("continue");            
            debugging("normal continue stmt", 1);

            $$.TAC = nullCST();
            string cont_label = contStk.top();
            string code = "goto " + cont_label;
            $$.TAC = concat($$.TAC, code); 

        }
        | PASS  {
            debugging("normal pass stmt", 1);
            $$.nodeNum = nodeInit("pass");

            $$.TAC = nullCST();
            
        }
        | globalstatement         { 
            debugging("normal global stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;

        }
        | nonlocalstmt      { 
            debugging("normal nonlocal stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        | assignstmt        { 
            debugging("normal assign stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;

        }
        | returnnstmt         { 
            debugging("normal return stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        | expression                 { 
            debugging("normal expression stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        ;
        
compoundstmt : 
        ifstatement  {
            debugging("compound stmt", 1);
            $$.nodeNum=$1.nodeNum;

            $$.TAC = $1.TAC;
        }
        | whilestatement  { 
            debugging("compound stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        | forstmt  { 
            debugging("compound stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        | funcdef  { 
            debugging("compound stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        | classdef  { 
            debugging("compound stmt", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
        }
        ;




    //normal stmt types
exprstmt :
        vardeclaration    { 
            debugging("exprstmt", 1);
            $$.nodeNum = $1.nodeNum;

            if($1.is_self){
                SymbolTable* classST = curr_table->Parent;
                if((classST->Table).find({$1.lexeme,""} ) != classST->Table.end()){

                    SymbolEntry* memEntry = &((classST->Table)[{$1.lexeme,""}]);
                    cout << "Member " << $1.lexeme << " already declared at line " << memEntry->lineno << endl;
                    yyerror("Variable redeclaration");
                }
                
                int temp2 = offsetStk.top();
                offsetStk.pop();
                classST->entry($1.lexeme, "", "NAME", $1.type, getSize($1.type), temp2, "class", yylineno, 0, 0);
                temp2 += getSize($1.type);
                offsetStk.push(temp2);

                $$.TAC = $1.TAC;

            }
            else{
                //entry into symbol table for variable declaration
                //vardecl has lexeme and type
                //check if already exists
                SymbolEntry* namelookup = curr_table->lookup({$1.lexeme,""});
                if(namelookup){
                    //exists
                    cout << "Variable previously declared at "<< namelookup->lineno << endl;
                    yyerror("Variable redeclaration");
                }else{
                    //new declaration
                    //params arent entried into symbol table
                    
                    //check if primitve type is list, because list size depends on list item type
                    string lt($1.type);
                    if(lt.compare(0,4,"list")!=0){
                        curr_table->entry($1.lexeme, "", "NAME", ($1).type, getSize(($1).type) , offset, curr_scope_name, yylineno, 0, 0);
                        offset = offset + getSize($1.type);
                    }
                    else{
                        //this is list
                        
                        curr_table->entry($1.lexeme,"", "NAME", ($1).type, getSize($1.type) , offset, curr_scope_name, yylineno, $1.list_size , 0);
                        offset = offset + $1.size;

                    }

                    $$.TAC = $1.TAC;
                }

            }
        }
        ;

returnnstmt :
        RETURN expression   { 
            debugging("return statement",1);
            $$.nodeNum = nodeInit("return");
            ParentToChild($$.nodeNum, $2.nodeNum);

            //check if inside function
            if(curr_scope_name != "func"){
                //return is outside 
                yyerror("return call outside of function definition");
            }

            //check type match with that of function body
            if( strcmp($2.type, curr_return_type)!=0){
                cout << "TypeError: function return type is "<< curr_return_type << " but returning " << $2.type << endl;
                yyerror("return type mismatch");
            }

            string code = "return " + str($2.res) + "\ngoto ra";
            $$.TAC = concat($2.TAC, code);

        }
        | RETURN  { 
            debugging("return statement",1);
            $$.nodeNum = nodeInit("return");

            if(curr_scope_name != "func"){
                //return is outside 
                yyerror("TypeError: return call outside of function definition");
            }         
            //none can be returned for non "none" functions  

            string code = "goto ra";
            $$.TAC = cstar(code); 
        }
        ;

delstmt :
        DEL expression   { 
            debugging("delstmt", 1);
            $$.nodeNum = nodeInit("deleteStmt");
            ParentToChild($$.nodeNum, $2.nodeNum);

            string code = "del " + str($2.res);
            $$.TAC = concat($2.res, code);
        }
        ;
    
    
assignstmt:
        assignments {
            debugging("assignstmt",1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.TAC = $1.TAC;
        }
        | ids PLUS_EQ expression  {
            $$.nodeNum = nodeInit("+=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //ids is checke for declare before use
            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch "<<  $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "+" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

        }
        | ids MINUS_EQ expression  {
            $$.nodeNum = nodeInit("-=");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch " <<  $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "-" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

         }
        | ids STAR_EQ expression  { 
            $$.nodeNum = nodeInit("*=");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch " << $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }
            string t = getTemp();
            string code = t + " = " + str($1.res) + "*" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
        }
        | ids FORWARDSLASH_EQ expression  {
            $$.nodeNum = nodeInit("/=");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch " << $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "/" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

         }
        | ids DOUBLE_SLASH_EQ expression  {
            $$.nodeNum = nodeInit("//=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch " << $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "//" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

         }
        | ids PERCENT_EQ expression  { 
            $$.nodeNum = nodeInit("%=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch " << $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }
            string t = getTemp();
            string code = t + " = " + str($1.res) + "%" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
        }
        | ids AT_EQ expression  { 
            $$.nodeNum = nodeInit("@=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch " << $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "@" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

        }
        | ids AMPERSAND_EQ expression  {
            $$.nodeNum = nodeInit("&=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch " << $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "&" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

         }
        | ids PIPE_EQ expression  { 
            $$.nodeNum = nodeInit("|=");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch "<<  $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "|" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

        }
        | ids CAP_EQ expression  { 
            $$.nodeNum = nodeInit("^=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch "<<  $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }
            
            string t = getTemp();
            string code = t + " = " + str($1.res) + "^" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

        }
        | ids RT_RT_EQ expression  {
            $$.nodeNum = nodeInit(">>=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch "<<  $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + ">>" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

         }
        | ids LT_LT_EQ expression  { 
            $$.nodeNum = nodeInit("<<=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch "<<  $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "<<" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

        }
        | ids DOUBLE_STAR_EQ expression  { 
            $$.nodeNum = nodeInit("**=");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //type check
            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: Type mismatch "<<  $1.type << "and " << $3.type << endl;
                yyerror("TypeError");
            }

            string t = getTemp();
            string code = t + " = " + str($1.res) + "**" + str($3.res);
            code = code + "\n" + str($1.res) + " = " + t;
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);

        }
        ; 

assignments :
        ids EQUALS assignments { 
            debugging("assignments", 1);
            $$.nodeNum = nodeInit("=");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //check type match
            if(strcmp($1.type, $3.type)==0){
                //equal
                strcpy($$.type, $1.type);

                string code = str($1.res) + " = " + str($3.res);
                $$.TAC = concat($1.TAC, str($3.TAC));
                $$.TAC = concat($$.TAC,code );
            }
            else{
                cout << "TypeError: " << $3.type << " assigned to " << $1.type << endl;
                yyerror("Type mismatch during assignment");
            }

        }
        | ids EQUALS expression  {
            debugging("assignments", 1);
            $$.nodeNum = nodeInit("=");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //check if type of expression matches type of ids
            if(strcmp($1.type, $3.type)==0){
                strcpy($$.type, $1.type);

                string code = str($1.res) + " = " + str($3.res);
                $$.TAC = concat($1.TAC, str($3.TAC));
                $$.TAC = concat($$.TAC, code);
            }
            else{
                cout << "TypeError: "<< $3.type << " assigned to " << $1.type << endl;
                yyerror("Type mismatch during assignment");
            }
         }
        ;

  
vardeclaration :
        typeDeclaration EQUALS expression { 
            debugging("variable declaration", 1);
            $$.nodeNum = nodeInit("=");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            //check if var isnt already declared: DONE at typedeclaration

            //check type match
            if(strcmp($1.type, $3.type)!=0){
                //doesn't match
                cout << "TypeError: "<< $3.type << " assigned to " << $1.type << endl;
                yyerror("Type mismatch during assignment");
            }

            $$.is_self = $1.is_self; 
            $$.list_size = $3.list_size;

            strcpy($$.lexeme, $1.lexeme);
            strcpy($$.type, $1.type);

            string code = str($1.res) + " = " + str($3.res);
            $$.TAC = concat($3.TAC, code);

        }
        | typeDeclaration {
            debugging("variable declaration", 1);
            $$.nodeNum = $1.nodeNum;

            $$ = $1;

            strcpy($$.res, $1.res);
            $$.TAC = $1.TAC;
        }

        ;

typeDeclaration :
        NAME COLON primitiveType  {
            $$.nodeNum = nodeInit(":");
            debugging("type declaration", 1);
            string t= $1;
            string s = "ID(" +t + ")";
            ParentToChild($$.nodeNum, nodeInit(s));
            ParentToChild($$.nodeNum, $3.nodeNum);

            strcpy($$.type, $3.type);
            strcpy($$.lexeme, $1); //IMP for parameters

            strcpy($$.res, $1);
            $$.TAC = $3.TAC;
            
        }
        
        | NAME DOT typeDeclaration { 
            $$.nodeNum = nodeInit("atomicExpe");
            debugging("type declaration", 1);
            string t= $1;
            string s = "ID(" +t + ")";
            ParentToChild($$.nodeNum, nodeInit(s));            
            int dot = nodeInit(".");            
            ParentToChild($$.nodeNum, dot);
            ParentToChild(dot, $3.nodeNum);

            //if NAME is self, declare $3.lexeme into class symbol table
            if( t != "self"){
                cout << "NAME is" << t << "|"<<endl;
                cout << $1 << " cannot declare its member. only <self> can "<< endl;
                yyerror("Illegal declaration");
            }
            
            //NAME has to be self
            $$.is_self = 1;
            strcpy($$.lexeme, $3.lexeme);
            strcpy($$.type, $3.type);

            //TODO
        }
        ;
        
ids : 
        NAME{
            debugging("ids", 1);
            string t= $1;
            string s = "ID(" +t + ")"; 
            $$.nodeNum = nodeInit(s);

            //if predefined variables don't err
            if(strcmp($1,"__name__")==0){

                strcpy($$.lexeme, $1);
                $$.TAC = nullCST();
                $$.TAC = concat($$.TAC, "@program start :");
                strcpy($$.res, $1);
            }
            else{
                // this name is being used (after declaration)
                SymbolEntry* namelookup = curr_table->lookup({$1,""});
                if(namelookup){
                    //exists: OK
                    strcpy($$.type, namelookup->type.c_str());
                    strcpy($$.lexeme, $1);

                    strcpy($$.res, $1);
                    $$.TAC = nullCST();
                }
                else{
                    //does not exits
                    // cout << "here\n";
                    yyerror("Variable not declared yet");
                }

            }

            
            
         }
        | NAME LSQUARE expression RSQUARE {
            debugging("ids", 1);
            $$.nodeNum = nodeInit("atom_expr");
            string t= $1;
            string s = "ID(" +t + ")"; 
            ParentToChild($$.nodeNum, nodeInit(s));
            int child= nodeInit("[]");
            ParentToChild($$.nodeNum, child);
            ParentToChild(child, $3.nodeNum);

            SymbolEntry* namelookup = curr_table->lookup({$1,""});
            if(namelookup){
                //exists: OK
                //check if list type
                if( namelookup->type.compare(0,4, "list")!=0){
                    cout << "TypeError: " << $1 << " cannot be indexed." << endl;
                    yyerror(" Not of type <list>");
                }

                if(strcmp($3.type, "int")!=0){
                    //accessing without int index
                    yyerror("Index must be <int> value");
                }

                //set ids type
                char ids_type[100];
                int y = 0;
                for(int x = 5; x < (namelookup->type).size()-1 ; x++){
                    ids_type[y] = (namelookup->type)[x];
                    y++;
                }
                ids_type[y] = '\0';

                string ls($1);
                ls = ls + "[]";
                strcpy($$.type, ids_type);
                strcpy($$.lexeme, ls.c_str());

                string t = getTemp();
                string code = t + " = "  + str($3.res) + "*" + to_string(getSize($$.type));
                string r = str($1) + "[" + t + "]";
                
                strcpy($$.res, r.c_str());

                $$.TAC = concat($3.TAC, code);


            }
            else{
                yyerror("Variable not declared");
            }

        }
        | NAME DOT NAME {
            debugging("ids", 1);
            $$.nodeNum = nodeInit("atomic_expr");
            string t= $1;
            string s = "ID(" +t + ")";
            ParentToChild($$.nodeNum, nodeInit(s));
            int dot = nodeInit(".");            
            ParentToChild($$.nodeNum, dot);
            ParentToChild(dot, nodeInit($3));

            
            //check if NAME2 is defined field in NAME1 class

            //case 1: object is doing stuff with member
            //case 2: self or class name inside class funcdef is using

            SymbolEntry* nEntry = curr_table->lookup({$1,""});
            if(nEntry){
                SymbolEntry* classN = curr_table->lookup({nEntry->type,""});
                if(!classN || classN->type!="class"){
                    cout<< $1 << " is not object of some class" << endl;
                    yyerror("Variable cannot invoke member");
                }
                //NAME1 is object of class now
                //find class table and see if this field exists
                SymbolTable* classT = findTable(nEntry->type, "");
                auto findMem = (classT->Table).find({$3,""});
                if(findMem == (classT->Table).end()){
                    //no such field
                    cout << $3 << " is not member of class "<< nEntry->type << endl;
                    yyerror("Invalid member invoked");
                }
                auto memToken = (findMem->second).token;
                if(memToken!="NAME"){
                    cout << $3 << " is not member of class "<< nEntry->type << endl;
                    yyerror("Invalid member invoked");
                }
                //ALLGOOD
                auto memType = (findMem->second).type;
                strcpy($$.type, memType.c_str());

                //TODO


            }
            else{
                // cout << "here \n";
                cout << "Unknown variable " << $1 << endl;
                yyerror("Unknown Variable. Must declare before use.");
            }


        }
        ;


primitiveType : 
        numericType   { 
            debugging("primitive numeric", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.size = $1.size;

            $$.TAC = $1.TAC;
        }
        | STR     { 
            debugging("primitive string", 1);
            $$.nodeNum = nodeInit("string");

            strcpy($$.type, "str");

            $$.TAC = nullCST();
            
        }
        | BOOL    {
            debugging("primitive boolean", 1);
            $$.nodeNum = nodeInit("bool"); 

            strcpy($$.type, "bool");
            $$.size = getSize("bool");

            $$.TAC = nullCST();
        }
        | listType   {
            debugging("primitive list", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.size = $1.size;

            $$.TAC = $1.TAC;
        }
        | NAME       {
            debugging("primitive ids", 1);
            string t= $1;
            string s = "ID(" +t + ")";
            $$.nodeNum = nodeInit(s);
            
            //check if its a class
            SymbolEntry* classEntry = curr_table->lookup({$1,""});
            if(!classEntry){
                yyerror("TypeError: Unknown Type");
            }
            else{
                if(classEntry->token != "CLASS"){
                    yyerror("TypeError: Unknown Type");
                }

                strcpy($$.type, $1);            

                $$.TAC = nullCST();
            }
        }

        ; 
    
numericType : 
        INT       { 
            debugging("numeric int", 1);
            $$.nodeNum = nodeInit("int");

            // $$.type = "int"
            strcpy($$.type, "int");
            $$.size = getSize("int");

            $$.TAC = nullCST();
            
        }
        | FLOAT   {
            debugging("numeric float", 1);
            $$.nodeNum = nodeInit("float");

            // $$.type = "float";
            strcpy($$.type, "float");
            $$.size = getSize("float");

            $$.TAC = nullCST();
        }
        ;


listType :
        LIST LSQUARE primitiveType RSQUARE { 
            debugging("list type", 1);
            $$.nodeNum = nodeInit("atomExpr");
            ParentToChild($$.nodeNum, nodeInit("list"));
            int child = nodeInit("[]");
            ParentToChild(child, $3.nodeNum);
            ParentToChild($$.nodeNum, child);

            string temp($3.type);
            string ltype = "list[" + temp + "]";
            strcpy($$.type, ltype.c_str());    
            
            $$.size = getSize(ltype);

            $$.TAC = $3.TAC;
        }
        ;

  
    

    
logicalOr 
        : logicalAnd    {
            debugging("logical or", 1);
            $$.nodeNum = $1.nodeNum;
            strcpy($$.type, $1.type);

            $$.list_size = $1.list_size;

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | logicalOr OR logicalAnd { 
            debugging("logical or", 1);
            $$.nodeNum = nodeInit("or");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " or " + str($3.res);
            $$.TAC = $1.TAC;
            $$.TAC = concat($$.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

logicalAnd 
        : bitwiseOr  { 
            debugging("logical and", 1);
            $$.nodeNum = $1.nodeNum;

            $$.list_size = $1.list_size;
            strcpy($$.type, $1.type);
            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | logicalAnd AND bitwiseOr { 
            debugging("logical and", 1);
            $$.nodeNum= nodeInit("and");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t= getTemp();
            string code = t + " = " + str($1.res) + " and " + str($3.res);
            $$.TAC = $1.TAC;
            $$.TAC = concat($$.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

  

bitwiseOr 
        : bitwiseXor   { 
            debugging("bitwise or", 1);
            $$.nodeNum = $1.nodeNum;

            $$.list_size = $1.list_size;
            strcpy($$.type, $1.type);
            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | bitwiseOr BAR bitwiseXor { 
            debugging("bitwise or", 1);
            $$.nodeNum = nodeInit("|");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t= getTemp();
            string code = t + " = " + str($1.res) + " | " + str($3.res);
            $$.TAC = $1.TAC;
            $$.TAC = concat($$.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

bitwiseXor 
        : bitwiseAnd   { 
            debugging("bitwise xor", 1);
            $$.nodeNum = $1.nodeNum;

            $$.list_size = $1.list_size;

            strcpy($$.type, $1.type);
            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | bitwiseXor CAP bitwiseAnd { 
            debugging("bitwise xor", 1);
            $$.nodeNum = nodeInit("^");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " ^ " + str($3.res);
            $$.TAC = $1.TAC;
            $$.TAC = concat($$.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

bitwiseAnd 
        : equalExpr    { 
            debugging("bitwise and", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.list_size = $1.list_size;

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | bitwiseAnd AMPERSAND equalExpr { 
            debugging("bitwise and", 1);
            $$.nodeNum = nodeInit("&");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " +  str($1.res) + " & " + str($3.res);
            $$.TAC = $1.TAC;
            $$.TAC = concat($$.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

listExpr :
        listExpr COMMA expression  { 
            debugging("list expression", 1);
            $$.nodeNum = nodeInit(",");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            if(strcmp($1.type, $3.type)!=0){
                cout << "TypeError: " << endl;
                yyerror("list of poly type not allowed");
            }

            strcpy($$.type, $1.type);

            $$.list_size = $1.list_size + 1;

            string list_temp = str($1.res);
            string code = list_temp + "[" + to_string(($$.list_size-1)*getSize($1.type)) + "]" + " = " + str($3.res);
            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $1.TAC);
            $$.TAC = concat($$.TAC, $3.TAC);
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, list_temp.c_str());

        }
        | expression { 
            debugging("list expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);

            $$.list_size = 1;

            string list_temp = getTemp();
            string code = list_temp + "[" + to_string(($$.list_size-1)*getSize($1.type)) + "]" + " = " + str($1.res);
            $$.TAC = concat($1.TAC, code);
            strcpy($$.res, list_temp.c_str());


        }
        |   {
            $$.nodeNum = -1;
            $$.list_size = 0;
            $$.TAC = nullCST();
            string s = "";
            strcpy($$.res, s.c_str() );
        }
        

expression 
        : logicalOr { 
            debugging("expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.list_size = $1.list_size;

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        ;

equalExpr 
        : relExpr  { 
            debugging("equality expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.list_size = $1.list_size;

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | equalExpr EQ_EQ relExpr {  
            debugging("equality expression", 1);
            $$.nodeNum = nodeInit("==");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " == " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
            
        }
        | equalExpr NOT_EQ relExpr {
            debugging("equality expression", 1);
            $$.nodeNum = nodeInit("!=");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " != " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        | equalExpr COLON_EQ relExpr {
            debugging("equality expression", 1);
            $$.nodeNum = nodeInit(":=");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " := " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());

        }
        | equalExpr IS relExpr {
            debugging("equality expression", 1);
            $$.nodeNum = nodeInit("=");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " is " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        | equalExpr IN ids {
            debugging("equality expression", 1);
            $$.nodeNum = nodeInit("in");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " in " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        | equalExpr NOT IN ids {
            debugging("equality expression", 1);
            $$.nodeNum = nodeInit("!=");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $4.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " not in " + str($4.res);
            $$.TAC = concat($1.TAC, str($4.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

   

shiftExpr 
        : addExpr {
                    $$.nodeNum = $1.nodeNum; 
                    debugging("shift expression", 1); 

                    strcpy($$.type, $1.type); 
                    $$.list_size = $1.list_size; 

                    $$.TAC = $1.TAC;
                    strcpy($$.res, $1.res);

                }
        | shiftExpr LT_LT addExpr {
            debugging("shift expression", 1);
            $$.nodeNum = nodeInit("<<");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " << " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
         }
        | shiftExpr GT_GT addExpr { 
            debugging("shift expression", 1);
            $$.nodeNum = nodeInit(">>");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " >> " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

addExpr 
        : multiplicativeExpr  { 
            debugging("additive expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.list_size = $1.list_size;

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | addExpr PLUS multiplicativeExpr { 
            debugging("additive expression", 1);
            $$.nodeNum = nodeInit("+");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " + " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        | addExpr MINUS multiplicativeExpr { 
            debugging("additive expression", 1);
            $$.nodeNum = nodeInit("-");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " - " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;

relExpr 
        : shiftExpr  { 
            debugging("relational expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.list_size = $1.list_size;

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
        }
        | relExpr LT_GT shiftExpr { 
            debugging("relational expression", 1);
            $$.nodeNum = nodeInit("<>");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " <> " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        | relExpr LT shiftExpr { 
            debugging("relational expression", 1);
            $$.nodeNum = nodeInit("<");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " < " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }

        | relExpr GT shiftExpr { 
            debugging("relational expression", 1);
            $$.nodeNum = nodeInit(">");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            // cout << "here" << endl;
        
            string t = getTemp();
            
            string code = t + " = " + str($1.res) + " > " + str($3.res);
        
            $$.TAC = concat($1.TAC, str($3.TAC));
            
            $$.TAC = concat($$.TAC, code);
            
            strcpy($$.res, t.c_str());

        }
        | relExpr LT_EQ shiftExpr {
            debugging("relational expression", 1);
            $$.nodeNum = nodeInit("<=");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " <= " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
         }
        | relExpr GT_EQ shiftExpr {
            debugging("relational expression", 1);
            $$.nodeNum = nodeInit(">=");
            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " >= " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
         }
        ;

multiplicativeExpr 
        : expoExpr   { 
            debugging("multiplicative expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            $$.list_size = $1.list_size;

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);

        }
        | multiplicativeExpr ASTERISK expoExpr { 
            debugging("multiplicative expression", 1);
            $$.nodeNum = nodeInit("*");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " * " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
            
        }
        | multiplicativeExpr FORWARDSLASH expoExpr  {
            debugging("multiplicative expression", 1);
            $$.nodeNum = nodeInit("/");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " / " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());

        
         }
        | multiplicativeExpr DOUBLESLASH expoExpr {
            debugging("multiplicative expression", 1);
            $$.nodeNum = nodeInit("//");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " // " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());

         }
        | multiplicativeExpr PERCENT expoExpr { 
            debugging("multiplicative expression", 1);
            $$.nodeNum = nodeInit("%");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " % " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());

        }
        ;

expoExpr 
        : negated_expr     {
            debugging("exponentiation expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);
            $$.list_size = $1.list_size;
         }
        | negated_expr DOUBLE_STAR expoExpr {
            debugging("exponentiation expression", 1);
            $$.nodeNum = nodeInit("**");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            strcpy($$.type, $1.type);

            string t = getTemp();
            string code = t + " = " + str($1.res) + " ** " + str($3.res);
            $$.TAC = concat($1.TAC, str($3.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
         }
        ;

negated_expr 
        : primaryExpr    {
            debugging("negated expression", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);

            $$.list_size = $1.list_size;
            
        }
        | MINUS negated_expr {
            debugging("negated expression", 1);
            $$.nodeNum = nodeInit("-");            
            ParentToChild($$.nodeNum, $2.nodeNum);

            strcpy($$.type, $2.type);

            string t = getTemp();
            string code = t + " = " + " - " + str($2.res);
            $$.TAC = nullCST();
            $$.TAC = concat( $$.TAC, str($2.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
         }
        | NOT negated_expr { 
            debugging("negated expression", 1);
            $$.nodeNum = nodeInit("not");            
            ParentToChild($$.nodeNum, $2.nodeNum);

            strcpy($$.type, $2.type);

            string t = getTemp();
            string code = t + " = " + " not " + str($2.res);
            $$.TAC = nullCST();
            $$.TAC = concat( $$.TAC, str($2.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        | TILDE negated_expr {
            debugging("negated expression", 1);
            $$.nodeNum = nodeInit("~");
            ParentToChild($$.nodeNum, $2.nodeNum);

            strcpy($$.type, $2.type);

            string t = getTemp();
            string code = t + " = " + " ~ " + str($2.res);
            $$.TAC = nullCST();
            $$.TAC = concat( $$.TAC, str($2.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
         }
        | PLUS negated_expr { 
            debugging("negated expression", 1);
            $$.nodeNum = nodeInit("+");            
            ParentToChild($$.nodeNum, $2.nodeNum);

            strcpy($$.type, $2.type);

            string t = getTemp();
            string code = t + " = " + " + " + str($2.res);
            $$.TAC = nullCST();
            $$.TAC = concat( $$.TAC, str($2.TAC));
            $$.TAC = concat($$.TAC, code);
            strcpy($$.res, t.c_str());
        }
        ;




primaryExpr 
        : ids { 
            debugging("primary expression", 1);
            // cout << "primary expression" << endl;
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);
            strcpy($$.lexeme, $1.lexeme);

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res);

        }
        | NUMBER_INT { 
            debugging("primary expression", 1);
            string t= $1;
            string s = "INT(" +t + ")"; 
            $$.nodeNum = nodeInit(s);

            strcpy($$.lexeme, $1);
            strcpy($$.type, "int");
            $$.size = getSize("int");

            $$.TAC = nullCST();
            strcpy($$.res, $1 );
            
        }
        | NUMBER_FLOAT { 
            debugging("primary expression", 1);
            string t= $1;
            string s = "FLOAT(" +t + ")"; 
            $$.nodeNum = nodeInit(s);

            strcpy($$.lexeme, $1);
            strcpy($$.type, "float");
            $$.size = getSize("float");

            $$.TAC = nullCST();
            strcpy($$.res, $1 );
            
        }
        | STRING { 
            debugging("primary expression, string", 1);
            string t= $1;
            t = t.substr(1, t.size()-2);
            t = "\\\"" + t + "\\\"";
            string s = "LITERAL(" +t + ")";
            $$.nodeNum = nodeInit(s);


            int strlen = t.size();
            $$.size = strlen*getSize("str");
            strcpy($$.lexeme, $1);
            strcpy($$.type, "str");

            $$.TAC = nullCST();
            strcpy($$.res, $1 );
            
        }
        | TRUE {
            debugging("primary expression, true", 1);
            $$.nodeNum = nodeInit("True");

            strcpy($$.type, "bool");
            $$.size = getSize("bool");
            strcpy($$.lexeme, "true");  

            $$.TAC = nullCST();
            strcpy($$.res, $$.lexeme );          
         }
        | FALSE {
            debugging("primary expression, false", 1);
            $$.nodeNum = nodeInit("False");
            
            strcpy($$.type, "bool");
            $$.size = getSize("bool");
            strcpy($$.lexeme, "false");

            $$.TAC = nullCST();
            strcpy($$.res, $$.lexeme );
         }
        | NONE { 
            debugging("primary expression, none", 1);
            $$.nodeNum = nodeInit("None");
            strcpy($$.type, "none");


            $$.size = 0;
            strcpy($$.type, "none");
            strcpy($$.lexeme, "none");

            $$.TAC = nullCST();
            strcpy($$.res, $$.lexeme );
        }
        | funccall { 
            debugging("function call", 1);
            $$.nodeNum = $1.nodeNum;

            strcpy($$.type, $1.type);

            $$.TAC = $1.TAC;
            strcpy($$.res, $1.res );
        }
        | LPAREN expression RPAREN { 
            $$.nodeNum = nodeInit("()");            
            ParentToChild($$.nodeNum, $2.nodeNum);

            strcpy($$.type, $2.type);

            string t = getTemp();
            string code = t + " = " + str($2.res);
            $$.TAC = concat($2.TAC, code);
            strcpy($$.res, t.c_str());

        }
        | LSQUARE listExpr RSQUARE {
            $$.nodeNum = nodeInit("[]");
            ParentToChild($$.nodeNum, $2.nodeNum);

            string temp($2.type);
            string ltype = "list[" + temp + "]";
            strcpy($$.type, ltype.c_str()); 
            $$.list_size = $2.list_size;

            //TODO

            string t = getTemp();
            string ret_temp = getTemp();
            string code = t + " = " + to_string($2.list_size) + "*" + to_string(getSize($2.type)) + "\npushparam " + t + "\ncall memalloc 1\npop_return " + ret_temp;

            code = code + "\n" + str($2.res) + " = " + ret_temp;

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, code);
            $$.TAC = concat($$.TAC, $2.TAC);
            strcpy($$.res, $2.res);

        }
        ;





arguments :
        expression { 
            debugging("arguments", 1);
            $$.nodeNum = $1.nodeNum;

            // string s = $1.type;
            // $$.par_arg_shape = s;
            strcpy($$.par_arg_shape, $1.type);
            $$.nelem = 1;

            string code = "pushparam " + str($1.res);
            $$.TAC = concat($1.TAC, code);
            strcpy($$.res, $1.res);

        }
        | expression COMMA arguments {
            debugging("arguments", 1);
            $$.nodeNum = nodeInit(",");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            $$.nelem = $3.nelem + 1;

            string s($1.type);
            string curr($3.par_arg_shape);
            string comma = ",";
            curr = s+ comma + curr;
            strcpy($$.par_arg_shape, curr.c_str());

            string code = "pushparam " + str($1.res);
            $$.TAC = concat($3.TAC, str($1.TAC));
            $$.TAC = concat($$.TAC, code);

        }
        |    {
            $$.nodeNum = -1;
            $$.nelem = 0;
            string s = "";
            strcpy($$.par_arg_shape, s.c_str());

            $$.TAC = nullCST();
        }
        ;

funccall 
        : PRINT LPAREN arguments RPAREN {
            debugging("funccall", 1);
            $$.nodeNum = nodeInit("funccall");
            string s = "print";
            ParentToChild($$.nodeNum, nodeInit(s));            
            int child = nodeInit("()");            
            ParentToChild($$.nodeNum, child);
            ParentToChild(child, $3.nodeNum);

            if($3.nelem != 1){
                yyerror("Predefined function call Error: Invalid print call. Make sure to pass a SINGLE primitve type expression");
            }
            
            if( strcmp($3.par_arg_shape,"int")!=0 && strcmp($3.par_arg_shape,"float")!=0 && strcmp($3.par_arg_shape,"bool")!=0 && strcmp($3.par_arg_shape,"str")!=0 ){
                yyerror("Predefined function call Error: Invalid print call. Make sure to pass a single PRIMITIVE(int,float,bool,str) type expression");
            }
            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, str($3.TAC));
            string code = "call PRINT 1";
            $$.TAC = concat($$.TAC, code);

            // strcpy($$.)

        }
        | LEN LPAREN arguments RPAREN {
            if($3.nelem != 1){
                yyerror("Predefinged function call Error: Invalid len call. Make sure to pass a single expression of type <list>");
            }
            string shape = str($3.par_arg_shape);
            if(shape.compare(0,4,"list")!=0){
                yyerror("Predefined function call Error: Invalid len call. Make sure to pass a list type expression");
            }

            yyerror("len operation is runtime result. not implemented yet. Do not call");
            

        }

        | NAME LPAREN arguments RPAREN {
            debugging("funccall", 1);
            $$.nodeNum = nodeInit("funccall");
            string s = $1;
            ParentToChild($$.nodeNum, nodeInit(s));            
            int child = nodeInit("()");            
            ParentToChild($$.nodeNum, child);
            ParentToChild(child, $3.nodeNum);

            //predefined functions 
            

            //check if declared
            SymbolEntry* funclookup = curr_table->lookup({$1, $3.par_arg_shape});
            
            // cout << "after lookup\n";
            if(funclookup){
                if(funclookup->token != "FUNC"){
                    //this ain't a function
                    cout << "function not defined" << endl;
                    yyerror("Function must be defined before use");
                }

                // if($3.nelem != funclookup->num_args){
                //     cout << "function " << $1 << "takes " << funclookup->num_args << " argument(s) but " << $3.nelem << " argument(s) were given"<< endl;
                //     yyerror("argument count mismatch") ;
                // }

                // //check funcs in current scope
                // string par_shape = curr_table->parShape($1);
                // //check funcs in global scope
                // if(par_shape == "$"){par_shape = (TablesList[0])->parShape($1);}
                // if(strcmp($3.par_arg_shape, par_shape.c_str())!=0){
                //     cout << "arguments type mismatch. required signature: " << par_shape << " but found "<< $3.par_arg_shape<<  endl;
                //     yyerror("Argument types mismatch");
                // }

                //ALLOK

                strcpy($$.type, funclookup->type.c_str());
                string code = "call " + found_table + "_" + str($1) + "_" + str($3.par_arg_shape) + " " + to_string($3.nelem);

                $$.TAC = nullCST();
                string pushra = "pushparam ra";
                $$.TAC = concat($$.TAC, str($3.TAC));
                $$.TAC = concat($$.TAC, pushra);
                $$.TAC = concat($$.TAC, code);
                string t = getTemp();
                if(funclookup->type != "none"){
                    string code1 = "pop_return " + t;
                    $$.TAC = concat($$.TAC, code1);
                }
                strcpy($$.res, t.c_str());
                found_table = "";

            }
            else{
                cout << "function not defined OR given arguments do not match existing function signature, hence not resolved" << endl;
                yyerror("Function must be defined before use");
            }
        }
        | NAME DOT methodcall { 
            $$.nodeNum = nodeInit("funccall");
            string s = $1;
            int dot = nodeInit(".");
            ParentToChild($$.nodeNum, dot);
            ParentToChild(dot, nodeInit(s));
            ParentToChild(dot, $3.nodeNum);

            
            SymbolEntry* nEntry = curr_table->lookup({$1,""});
            if(nEntry){
                //name exists: check if class object
                SymbolEntry* cEntry = curr_table->lookup({nEntry->type,""});
                if(!cEntry || cEntry->token != "CLASS"){
                    yyerror("Cannot invoke method");
                }
                //check if methodcall is method of that class or exists in parent
                SymbolTable* classTable = findTable(nEntry->type, "");
                if(!classTable){
                    yyerror("Invalid method invoked");
                }

                SymbolEntry* methodEntry = classTable->lookup({$3.lexeme, $3.par_arg_shape});
                if(!methodEntry){
                    cout << "method not defined OR given arguments do not match existing function signature hence not resolved" << endl;
                    yyerror("Function must be defined before use"); 
                }


                //ALLOK

                strcpy($$.type, (methodEntry->type).c_str());

                string code = "method_for " + str($1) + "\ncall " + found_table + "_" + str($3.lexeme) + "_" + str($3.par_arg_shape) + " " + to_string($3.nelem);
                $$.TAC = concat($3.TAC, code);
                string t = getTemp();
                string code1 = "pop_return " + t;
                $$.TAC = concat($$.TAC, code1);

                strcpy($$.res, t.c_str());

            }
            else{
                yyerror("Unknown Variable: Declare before use");

            }

        }
        ;

methodcall
        : NAME LPAREN arguments RPAREN {
            // cout << "inside method call" << endl;
            $$.nodeNum = nodeInit($1);
            int parens = nodeInit("()");            
            ParentToChild($$.nodeNum, parens);
            ParentToChild(parens, $3.nodeNum);

            strcpy($$.lexeme, $1);
            $$.nelem = $3.nelem;

            strcpy($$.par_arg_shape, $3.par_arg_shape);

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $3.TAC);            
        }

elif_action
    : {
        string succ_label = getLabel();
        successStk.push(succ_label);
        strcpy($$.success_, succ_label.c_str());
    }
   
    
ifstatement : 
        IF expression COLON Suite elif_action elifstmts elseblock {
            debugging("if stmt", 1);
            $$.nodeNum = nodeInit("if");
            ParentToChild($$.nodeNum, $2.nodeNum);
            ParentToChild($$.nodeNum, $4.nodeNum);
            ParentToChild($$.nodeNum, $6.nodeNum);
            ParentToChild($$.nodeNum, $7.nodeNum);


            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $2.TAC);

            string code  = "ifz " + str($2.res) + " goto " + str($6.start_);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($4.TAC));  

            string suite_succ = "goto " + str($5.success_); //universal success;
            $$.TAC = concat($$.TAC, suite_succ);

            string code1 = str($6.start_) + " :" ;
            $$.TAC = concat($$.TAC, code1);
            //

            $$.TAC = concat($$.TAC, str($6.TAC));

            $$.TAC = concat($$.TAC, str($6.end_) + " :");

            $$.TAC = concat($$.TAC, $7.TAC);

            $$.TAC = concat($$.TAC, str($5.success_) + " :");

            successStk.pop();

        }
        | IF expression COLON Suite elif_action elifstmts { 
            debugging("if stmt", 1);
            $$.nodeNum = nodeInit("if");
            ParentToChild($$.nodeNum, $2.nodeNum);
            ParentToChild($$.nodeNum, $4.nodeNum);
            ParentToChild($$.nodeNum, $6.nodeNum);


            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $2.TAC);

            string code  = "ifz " + str($2.res) + " goto " + str($6.start_);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($4.TAC));

            string code1 = "goto " + str($5.success_);
            $$.TAC = concat($$.TAC, code1);

            string code2 = str($6.start_) + ":";
            $$.TAC = concat($$.TAC, code2);
            
            $$.TAC = concat($$.TAC, str($6.TAC));

            string code4 = str($6.end_) + " :";
            $$.TAC = concat($$.TAC, code4);

            string code3 = str($5.success_) + ":\n";
            $$.TAC = concat($$.TAC, code3);

        }
        | IF expression COLON Suite elseblock { 
            debugging("if stmt", 1);
            $$.nodeNum = nodeInit("if");
            ParentToChild($$.nodeNum, $2.nodeNum);
            ParentToChild($$.nodeNum, $4.nodeNum);
            ParentToChild($$.nodeNum, $5.nodeNum);

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $2.TAC);

            string code  = "ifz " + str($2.res) + " goto " + str($5.start_);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($4.TAC));

            string code1 = "goto " + str($5.end_);
            $$.TAC = concat($$.TAC, code1);

            string code2 = str($5.start_) + ":";
            $$.TAC = concat($$.TAC, code2);

            $$.TAC = concat($$.TAC, str($5.TAC));

            string code3 = str($5.end_) + ":";
            $$.TAC = concat($$.TAC, code3);
            
        }
        | IF expression COLON Suite { 
            debugging("if stmt", 1);
            $$.nodeNum = nodeInit("if");
            ParentToChild($$.nodeNum, $2.nodeNum);
            ParentToChild($$.nodeNum, $4.nodeNum);

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, str($2.TAC));

            string code  = "ifz " + str($2.res) + " goto " + str($4.end_label);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($4.TAC));

            string code1 = str($4.end_label) + ":";
            $$.TAC = concat($$.TAC, code1);

        };

elifstmt : 
        ELIF expression COLON Suite  {
            debugging("elifstmt", 1);
            $$.nodeNum = nodeInit("elif");
            ParentToChild($$.nodeNum, $2.nodeNum);
            ParentToChild($$.nodeNum, $4.nodeNum);

            string sl = getLabel();
            string el = getLabel();

            $$.TAC = nullCST();

            $$.TAC = concat($$.TAC, $2.TAC);
            
            string code = "ifz " + str($2.res) + " goto " + el;
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, $4.TAC);

            string succ = successStk.top();
            $$.TAC = concat($$.TAC, "goto " + succ);

            strcpy($$.end_label, $4.end_label);
            strcpy($$.start_, sl.c_str());
            strcpy($$.end_, el.c_str());

         }
        ;

elifstmts : 
        elifstmt            { 
            debugging("elifstmts", 1);
            $$.nodeNum = $1.nodeNum;

            $$.TAC = $1.TAC;
            strcpy($$.end_label, $1.end_label);       //added in ifstmt or as elifstmsts

            strcpy($$.start_, $1.start_);
            strcpy($$.end_, $1.end_);
        }
        | elifstmts elifstmt   {
            debugging("elifstmts", 1);
            $$.nodeNum = nodeInit("elif");            
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $2.nodeNum);

            // $$.TAC = concat($1.TAC, str($2.TAC));
            // strcpy($$.end_label, $2.end_label);

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $1.TAC);

            string code = str($1.end_) + ":";
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, $2.TAC);

            strcpy($$.end_label, $2.end_label); //added in ifstmt
            strcpy($$.start_, $1.start_);
            strcpy($$.end_, $2.end_);
        }
        
        ;

    

elseblock :
        ELSE COLON Suite  { 
            debugging("elseblock", 1);
            $$.nodeNum = nodeInit("else");
            ParentToChild($$.nodeNum, $3.nodeNum);

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $3.TAC);

            string sl = getLabel();
            string el = getLabel();
            strcpy($$.start_, sl.c_str());            
            strcpy($$.end_, el.c_str());
        } 
        ;

forstmt :
        FOR forexpr COLON loop_action Suite elseblock  {
            debugging("for stmt", 1);
            $$.nodeNum = nodeInit("for");            
            ParentToChild($$.nodeNum, $2.nodeNum);            
            ParentToChild($$.nodeNum, $4.nodeNum);
            ParentToChild($$.nodeNum, $5.nodeNum);

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, str($2.res)+" = "+str($2.range_start)+" - "+str($2.range_step));
            
            string loop_start = str($4.cont_);
            $$.TAC = concat($$.TAC, loop_start + " :");
            
            string code = str($2.res)+" = "+str($2.res)+" + "+str($2.range_step);
            $$.TAC = concat($$.TAC, code);

            string cond = getTemp();
            code = cond+" = "+str($2.res)+" < "+str($2.range_end);
            $$.TAC = concat($$.TAC, code);

            code = "ifz "+cond+" goto "+str($5.end_label);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, $5.TAC);

            code = "goto "+loop_start;
            $$.TAC = concat($$.TAC, code);

            code = str($5.end_label)+" :";
            $$.TAC = concat($$.TAC,code);

            $$.TAC = concat($$.TAC, str($6.TAC));

            code = str($4.break_)+" :";
            $$.TAC = concat($$.TAC, code);

            // cout << "done for stmt\n";

            breakStk.pop();
            contStk.pop();

         }
        | FOR forexpr COLON loop_action Suite  {
            debugging("for stmt", 1);
            $$.nodeNum = nodeInit("for");
            ParentToChild($$.nodeNum, $2.nodeNum);
            ParentToChild($$.nodeNum, $4.nodeNum);

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, str($2.res)+" = "+str($2.range_start)+" - "+str($2.range_step));

            string loop_start = str($4.cont_);
            $$.TAC = concat($$.TAC, loop_start + " :");
            
            string code = str($2.res)+" = "+str($2.res)+" + "+str($2.range_step);
            $$.TAC = concat($$.TAC, code);

            string cond = getTemp();
            code = cond+" = "+str($2.res)+" < "+str($2.range_end);
            $$.TAC = concat($$.TAC, code);

            code = "ifz "+cond+" goto "+str($4.break_);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($5.TAC));


            code = "goto "+loop_start;
            $$.TAC = concat($$.TAC, code);

            code = str($4.break_)+ " :";
            $$.TAC = concat($$.TAC, code);


            breakStk.pop();
            contStk.pop();
            // cout << "done for stmt1\n";

         }
        ;

ForList 
        : RANGE LPAREN expression COMMA expression COMMA expression RPAREN{

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, $3.TAC);
            strcpy($$.range_start, $3.res);
            strcpy($$.range_end, $5.res);
            strcpy($$.range_step, $7.res);

            //cant check start < end condition
            //runtime variable right??

        }
        | funccall   {
            debugging("for list", 1);
            $$.nodeNum = $1.nodeNum;
            $$ = $1;

            yyerror("for loop only to be run using range function");

            //check if funccall type is list
            string ftype($1.type);
            if( ftype.compare(0,4,"list")!=0){
                cout << "TypeError: "<< "Function return type is <"<< ftype<< "> , but expected is a <list>" << endl;
                yyerror("Functtion return type is not a list");

                $$.TAC = $1.TAC;
                strcpy($$.res, $1.res);
            }
         }
        | ids  {
            debugging("for list", 1);
            $$.nodeNum = $1.nodeNum;

            yyerror("for loop only to be run using range function");

            //check if declared
            SymbolEntry* idslookup = curr_table->lookup({$1.lexeme,""});
            if(idslookup){
                //exists: OK
                //check if list
                if(idslookup->type.compare(0,4,"list")!=0){
                    //not a list
                    cout << "TypeError" << endl;
                    yyerror("Expected type list");
                }

                strcpy($$.type,(idslookup->type).c_str());

                $$.TAC = $1.TAC;
                strcpy($$.res, $1.res);
            }
            else{
                //does not exits
                yyerror("Variable not declared");
            }

        }
        | LSQUARE listExpr RSQUARE {
            debugging("for list", 1);
            $$.nodeNum = nodeInit("[]");            
            ParentToChild($$.nodeNum, $2.nodeNum);

            yyerror("for loop only to be run using range function");

            string temp($2.type);
            temp = "list[" + temp + "]";
            strcpy($$.type, temp.c_str());

            //TODO
            //but list iteration can be ommitted

            $$.TAC = nullCST();
            strcpy($$.res, $2.res);

            
            
        }
        ;
loop_action
    : {
        string break_label = getLabel();
        breakStk.push(break_label);
        strcpy($$.break_, break_label.c_str());

        string cont_label = getLabel();
        contStk.push(cont_label);
        strcpy($$.cont_, cont_label.c_str());
    }

whilestatement :
        WHILE expression COLON loop_action Suite elseblock  {
            debugging("while stmt", 1);
            $$.nodeNum = nodeInit("while");            
            ParentToChild($$.nodeNum, $2.nodeNum);            
            ParentToChild($$.nodeNum, $4.nodeNum);
            ParentToChild($$.nodeNum, $5.nodeNum);

            $$.TAC = nullCST();
            
            $$.TAC = concat($$.TAC, str($4.cont_) + ":" );

            $$.TAC = concat($$.TAC, str($2.TAC));

            string code = "ifz " + str($2.res) + " goto " + str($5.end_label);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($5.TAC));

            $$.TAC = concat($$.TAC, "goto " + str($4.cont_));

            string code2 = str($5.end_label) + " :";
            $$.TAC = concat($$.TAC, code2);

            $$.TAC = concat($$.TAC, str($6.TAC));

            $$.TAC = concat($$.TAC, str($4.cont_) + " :");

            breakStk.pop();
            contStk.pop();

         }
        | WHILE expression COLON loop_action Suite  { 
            debugging("while stmt", 1);
            $$.nodeNum = nodeInit("while");            
            ParentToChild($$.nodeNum, $2.nodeNum);            
            ParentToChild($$.nodeNum, $4.nodeNum);

            $$.TAC = nullCST();

            string loopstart = getLabel();
            $$.TAC = concat($$.TAC, str($4.cont_) + ":" );

            $$.TAC = concat($$.TAC, str($2.TAC));

            string code = "ifz " + str($2.res) + " goto " + str($4.break_);
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($5.TAC));

            $$.TAC = concat($$.TAC, "goto " + str($4.cont_));

            string code1 = str($4.break_) + " :";
            $$.TAC = concat($$.TAC, code1);

            breakStk.pop();
            contStk.pop();

        }
        ;


parameters: 
        vardeclaration  {
            debugging("parameters", 1);
            $$ = $1;

            $$.nelem = 1;
            if(param_num==-1){param_num = 1;}
            else {param_num ++;}

            fparams.push_back({{$1.lexeme,yylineno},{$1.type, param_num}});
            strcpy($$.par_arg_shape, $1.type);

            $$.TAC = nullCST();
            string code = str($1.res) + " popparam ";
            $$.TAC = concat($$.TAC, code);

        }
        | parameters COMMA vardeclaration {
            debugging("parameters", 1);
            $$.nodeNum = nodeInit(",");
            ParentToChild($$.nodeNum, $1.nodeNum);
            ParentToChild($$.nodeNum, $3.nodeNum);

            $$.nelem = $1.nelem + 1;
            if(param_num==-1){param_num = 1;}
            else {param_num ++;}

            fparams.push_back({{$3.lexeme,yylineno},{$3.type, param_num}});

            string curr($1.par_arg_shape);
            string comma(",");
            string s($3.type);
            curr = curr + comma + s;
            strcpy($$.par_arg_shape, curr.c_str());

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, str($1.TAC));

            string code = str($3.res) + " popparam ";
            $$.TAC = concat($$.TAC, code);

        }
        | NAME {
            debugging("parameters", 1);
            string t= $1;
            string s = "ID(" +t + ")";
            $$.nodeNum = nodeInit(s);

            //name must be self
            if(strcmp($1, "self")!=0){
                //not self
                yyerror("Type hint must be provided for function definition");
            }
            
            //self is of type, classname which is the curr_table
            strcpy($$.par_arg_shape, curr_table->TableName.c_str());

            //TODO

            $$.TAC = nullCST();

            string code = str($1) + " popparam ";
            $$.TAC = concat($$.TAC, code);
            
        }
        |   {
            debugging("parameters", 1);
            $$.nodeNum = -1;
            $$.nelem = 0;
            strcpy($$.type, "none");

            strcpy($$.par_arg_shape, "");

            $$.TAC = nullCST();


        }
        ;  

returnType : 
        primitiveType { 
            debugging("return type", 1);
            $$.nodeNum = $1.nodeNum;
            strcpy($$.type, $1.type);
            $$ = $1;

            $$.TAC = $1.TAC;
        }
       
        | NONE { 
            debugging("return type", 1);
            $$.nodeNum = nodeInit("None");
            strcpy($$.type, "none");            

            $$.TAC = nullCST();
        }
        ;
    
    

forexpr :
        NAME IN ForList    { 
            debugging("for expression", 1);
            $$.nodeNum = nodeInit("in");
            string t= $1;
            string s = "ID(" +t + ")";
            ParentToChild($$.nodeNum, nodeInit(s));
            ParentToChild($$.nodeNum, $3.nodeNum);

            //if new name then create new entry 
            // char ntype[100];
            // int y = 0;
            // for(int i=5; i< strlen($3.type)-1 ; i++){
            //     ntype[y] = ($3.type)[i];
            //     y++;
            // }
            // ntype[y] = '\0';
            // string sntype(ntype);

            SymbolEntry* namelookup = curr_table->lookup({$1,""});
            if(!namelookup){
                curr_table->entry($1, "", "NAME", "int", getSize("int") , offset,curr_scope_name, yylineno, 0, 0);
                offset = offset + getSize(($3).type);

                $$.TAC = nullCST();
                strcpy($$.res, $1);
                strcpy($$.range_start, $3.range_start);
                strcpy($$.range_end, $3.range_end);
                strcpy($$.range_step, $3.range_step);

            }
            else{
                //exists, so need to check if type matches
                if(namelookup->type != "int"){
                    cout<< "TypeError: " << "expected type <"<< "int" << ">, and found <"<< namelookup->type << "> "<< endl;;
                    yyerror("loop variable type mismatch");
                }

                $$.TAC = nullCST();
                strcpy($$.res, $1);
                strcpy($$.range_start, $3.range_start);
                strcpy($$.range_end, $3.range_end);
                strcpy($$.range_step, $3.range_step);

            }

        }
        ;


funcdef :
        funcheader Suite  { 
            $$ = $1;
            ParentToChild($$.nodeNum, $2.nodeNum);

            //after func def
            curr_table = tableStk.top();
            tableStk.pop();

            curr_scope_name = scopeStk.top();
            scopeStk.pop();

            offset = offsetStk.top();
            offsetStk.pop();

            $$.TAC = nullCST();
            $$.TAC = concat($$.TAC, str($1.TAC));
            $$.TAC = concat($$.TAC, str($2.TAC));

            string endfunc = "goto ra\nendfunc";
            $$.TAC = concat($$.TAC,endfunc);
        }    
        ;

funcheader 
        : DEF NAME LPAREN parameters RPAREN RARR returnType COLON {
            $$.nodeNum = nodeInit("def");
            string t= $2;
            string s = "ID(" +t + ")";
            ParentToChild($$.nodeNum, nodeInit(s));            
            int parens=nodeInit("()");            
            ParentToChild(parens, $4.nodeNum);
            ParentToChild($$.nodeNum, parens);
            ParentToChild($$.nodeNum, $7.nodeNum); 

            //check if func name already exists
            string scope_of_func = curr_table->TableName;
            SymbolEntry* funcEntry = curr_table->lookup({$2,$4.par_arg_shape});
            if(funcEntry){
                cout << "Function definition with same signature already exists" << endl;
                yyerror("Function/Method redeclaration");
            }

            // cout << "par arg shape: " << $4.par_arg_shape << endl;
            curr_table->entry($2, $4.par_arg_shape, "FUNC", $7.type, getSize($7.type), offset, curr_scope_name, yylineno, $4.nelem, 0);
            offset += getSize($7.type);

            tableStk.push(curr_table);
            curr_table = new SymbolTable(curr_table, $2, $4.par_arg_shape);
            TablesList.push_back(curr_table);

            scopeStk.push(curr_scope_name);
            curr_scope_name = "func";

            offsetStk.push(offset);
            offset = 0;

            strcpy(curr_return_type, $7.type);

            for( int i=0; i<fparams.size(); i++){
                curr_table->entry(fparams[i].first.first, "", "PARAM", fparams[i].second.first, getSize(fparams[i].second.first), offset, curr_scope_name, fparams[i].first.second, 0, fparams[i].second.second);

                offset += getSize(fparams[i].second.first);
            }

            fparams.clear();
            param_num = -1;

            $$.TAC = nullCST();
        
            string code = "begin func " + scope_of_func + "_" + str($2) + "_" + str($4.par_arg_shape) + " :\nra popparam";

            
            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($4.TAC));

            found_table = "";


        }
        | DEF NAME LPAREN parameters RPAREN COLON {
            $$.nodeNum = nodeInit("def");
            string t= $2;
            string s = "ID(" +t + ")";
            ParentToChild($$.nodeNum, nodeInit(s));            
            int parens=nodeInit("()");            
            ParentToChild(parens, $4.nodeNum);
            ParentToChild($$.nodeNum, parens);

            //do sig checks and then push
            string scope_of_func = curr_table->TableName;
            SymbolEntry* funcEntry = curr_table->lookup({$2,$4.par_arg_shape});
            if(funcEntry){
                cout << "Function definition with same signature already exists" << endl;
                yyerror("Function/Method redeclaration");
            }

            // cout << "par arg shape: " << $4.par_arg_shape << endl;
            curr_table->entry($2, $4.par_arg_shape , "FUNC", "none", getSize("none"), offset, curr_scope_name, yylineno, $4.nelem, 0 );
            offset += getSize("none");

            tableStk.push(curr_table);
            curr_table = new SymbolTable(curr_table, $2, $4.par_arg_shape);
            TablesList.push_back(curr_table);

            scopeStk.push(curr_scope_name);
            curr_scope_name = "func";

            offsetStk.push(offset);
            offset = 0;

            strcpy(curr_return_type, "none");

            for( int i=0; i<fparams.size(); i++){
                curr_table->entry(fparams[i].first.first, "", "PARAM", fparams[i].second.first, getSize(fparams[i].second.first), offset, curr_scope_name, fparams[i].first.second, 0, fparams[i].second.second);

                offset += getSize(fparams[i].second.first);
            }

            fparams.clear();
            param_num = -1;

            $$.TAC = nullCST();
            
            string code = "beginfunc "+scope_of_func + "_" + str($2) + "_" + str($4.par_arg_shape) + " :\nra popparam";

            $$.TAC = concat($$.TAC, code);

            $$.TAC = concat($$.TAC, str($4.TAC));

            found_table = "";
        }
    

classdef :
        classheader COLON Suite    { 
            debugging("class definition", 1);
            $$.nodeNum = $1.nodeNum;
            ParentToChild($$.nodeNum, $3.nodeNum);

            curr_table = tableStk.top();
            tableStk.pop();

            curr_scope_name = scopeStk.top();
            scopeStk.pop();

            offset = offsetStk.top();
            offsetStk.pop();

            $$.TAC = $3.TAC;


        }
        | classheader LPAREN classarguments RPAREN COLON Suite  { 
            debugging("class definition", 1);
            $$.nodeNum = $1.nodeNum;
            int PARs = nodeInit("()");
            ParentToChild(PARs, $3.nodeNum);
            ParentToChild($$.nodeNum, PARs);
            ParentToChild($$.nodeNum, $6.nodeNum);
            
            //curr_table is abhi ke class ka table
            //find the parent classes and put this as child
            SymbolTable* parent_table = findTable($3.lexeme,"");
            curr_table->Parent = parent_table;
            parent_table->childTables.push_back(curr_table);

            curr_table = tableStk.top();
            tableStk.pop();

            curr_scope_name = scopeStk.top();
            scopeStk.pop();

            offset = offsetStk.top();
            offsetStk.pop();

            $$.TAC = $6.TAC;
        }
        ;

classheader
    : CLASS NAME {
        $$.nodeNum = nodeInit("classdef");
        ParentToChild($$.nodeNum, nodeInit($2));

        class_list.push_back({$2,curr_scope_name});

        curr_table->entry($2,"", "CLASS", "class", getSize("class"), offset, curr_scope_name, yylineno, 0, 0); //num-args argnum

        offset += getSize("class");

        tableStk.push(curr_table);
        curr_table = new SymbolTable(curr_table, $2, "");
        curr_table->entry("self", "", "PARAM", $2, getSize("class"), offset, "class", yylineno, 0, 0);
        offset += getSize("class");
        TablesList.push_back(curr_table);

        scopeStk.push(curr_scope_name);
        curr_scope_name = "class";

        offsetStk.push(offset);
        offset = 0;

        $$.TAC = nullCST();
        strcpy($$.res, $2);

    };
    
classarguments
    : NAME {
        debugging("classarguments",1);
        $$.nodeNum = nodeInit($1);

        //curr scope is that of this new class
        $$.nelem = 1;
        //check if argument exists as class
        SymbolEntry* classEntry = curr_table->lookup({$1,""});
        if(classEntry){
            if(classEntry->token != "CLASS"){
                cout << "TypeError: expected type <class> but found " << classEntry->token << endl;
                yyerror("Arguments to class definition must be defined class");
            }

            //OK
            //take variables of this class and add them in this table
            SymbolTable* parentClass = findTable($1, "");
            for(auto it: parentClass->Table){
                if(it.second.type != "PARAM" || it.second.token!="FUNC"){
                    curr_table->entry(it.first.first,"", it.second.token, it.second.type, it.second.size, it.second.offset, curr_scope_name, yylineno, it.second.num_args, it.second.arg_num );
                }
                offset = offset + it.second.size;
            }
            strcpy($$.lexeme, $1);
        }
        else{
            yyerror("Argument not valid class");
        }
        
        
    }
    | classarguments COMMA NAME { //multiple inheritance anyways not allowed
        $$.nodeNum = nodeInit(",");
        ParentToChild($$.nodeNum, $1.nodeNum);
        ParentToChild($$.nodeNum, nodeInit($3));

        $$.nelem = $1.nelem + 1;
        //check if argument exists as class
        SymbolEntry* classEntry = curr_table->lookup({$3,""});
        if(classEntry){
            if(classEntry->token != "CLASS"){
                cout << "TypeError: expected type <class> but found " << classEntry->token << endl;
                yyerror("Arguments to class definition must be defined class");
            }
        }
        else{
            yyerror("Argument not valid class");
        }

    }

    | {
        $$.nodeNum = -1;
        $$.nelem = 0;
    }
    ;

Suite : 
        normalstmt NEWLINE { 
            debugging("suite", 1);
            $$.nodeNum = $1.nodeNum;
            $$ = $1;

            string s_end = getLabel();
            strcpy($$.end_label, s_end.c_str());

            $$.TAC = $1.TAC;

        }
        | NEWLINE INDENT stmts DEDENT { 
            // cout << "-----------------" << endl;
            $$.nodeNum = $3.nodeNum;
            $$ = $3;

            strcpy($$.end_label, $3.end_label);
            $$.TAC = $3.TAC;
        }
        ; 

ending 
        : NEWLINE ending  {
            debugging("ending", 1);
            $$.nodeNum=nodeInit("newline"); 

            $$.TAC = nullCST();
            
            }
        | ENDMARKER { 
            debugging("ending", 1);
            $$.nodeNum=nodeInit("EOF"); 

            $$.TAC = nullCST();            
        }
        ;
    
%%

int main(int argc, char **argv){

    //find if --debug flag is present in the command the arguments
    for(int i = 0; i < argc; i++){
        if(strcmp(argv[i], "--debug") == 0){
            debug = 1;
            break;
        }
    }

    for(int i = 0; i < argc; i++){
        if(strcmp(argv[i], "--st") == 0){
            for(auto it: TablesList){
                it->print_table();
                cout << "---------------------\n------------------" << endl;
            }
            break;
        }
    }

    int parsed  = 0;

    //search if -f (file input) is present in the command line arguments
    for(int i = 0; i<argc; i++){
        if(strcmp(argv[i], "-input") == 0){
            if(i+1 < argc){
                FILE *fp = fopen(argv[i+1], "r");
                if(fp){

                    yyin = fp;
                    yyparse();
                    parsed = 1;
                    fclose(fp);
                }
                else{
                    printf("Error: File not found\n");
                    return 1;
                }
            }
            else{
                printf("Error: File not found\n");
                return 1;
            }
        }
    }

    for(int i = 0; i < argc; i++){
        if(strcmp(argv[i], "-3ac") == 0){
            ofstream tac_file("_3AC.txt");

            if(!tac_file){
                cerr << "Error in creating _3AC.txt";
                return 1;
            }
            string final_3AC = "";
            istringstream iss(TAC_output);
            string line;

            // Iterate through each line of the string
            while (getline(iss, line)) {
                // Print each line
                if(line.length()==0){
                    continue;
                }
                if(line.back() != ':'){
                    final_3AC = final_3AC + "\t" + line + "\n";
                }else{
                    final_3AC = final_3AC + line + "\n";
                }
            }
            
            tac_file << final_3AC;
            tac_file.close();
        }
    }

    for(int i = 0; i < argc; i++){
        if(strcmp(argv[i], "-sym") == 0){
            ofstream out("symbol_tables.csv");

            if(!out.is_open()){
                cerr << "Failed to open symbol_tables.csv";
                return 1;
            }
            for(auto it: TablesList){
                string c = "";
                for(auto jt: it->childTables){
                    c = c + "," + jt->TableName;
                }

                out << ",,,,,,,," << endl;
                if(it->Parent){
                    out << "TableName:,"<< it->TableName << ",Parent: " << it->Parent->TableName << ",Child(s): " << c << endl;

                }else{
                    out << "TableName:,"<< it->TableName << ",Parent: " << "NULL" <<  ",Child(s): " << c << endl;
                }

                out << "Name,Signature,Token,Type,Size,Offset,LineNo,NumArgs,ArgNum" << std::endl;

                for(auto kt: it->Table) {
                    out << kt.first.first << ","<< kt.first.second << ","<<kt.second.token << "," << kt.second.type << ","<< kt.second.size << ","<< kt.second.offset << ","<< kt.second.lineno << ","<< kt.second.num_args << ","<< kt.second.arg_num << endl;
                }
                out << "\n\n";
            }

            out.close();
        }
    }

    if(parsed == 0){
        yyin = stdin;
        yyparse();
    }

    for(int i = 0; i < argc; i++){
        if(strcmp(argv[i], "-ast") == 0){
            string filename = "AST.dot";
            write_gv(filename);
        }
    }

    gen_global();
    gen_text();

    print_code(asm_file);

    


    return 0;
}

void yyerror(const char *message)
{
    //error with line no and message with yytext
    fprintf(stderr, "Error at line %d: %s\n", yylineno, message);
    fprintf(stderr, "%s\n",yytext);
    fprintf(stderr, "^\n");
    exit(EXIT_FAILURE); 
} 

/*
errors in asm file:
space before labels and main
commas when 2 registers are being used
*/