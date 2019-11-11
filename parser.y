%{
#include <iostream>
#include <stdlib.h>
#include <string>
#include <map>
#include <math.h>
#include <set>
#include <string>
#include "tree.h"
using namespace std;
int yylex(void);
void yyerror(const char * p) {}

// int -> string
char* itoa(int value, char* result, int base) {
	// check that the base if valid
	if (base < 2 || base > 36) { *result = '\0'; return result; }

	char* ptr = result, *ptr1 = result, tmp_char;
	int tmp_value;

	do {
		tmp_value = value;
		value /= base;
		*ptr++ = "zyxwvutsrqponmlkjihgfedcba9876543210123456789abcdefghijklmnopqrstuvwxyz" [35 + (tmp_value - value * base)];
	} while ( value );

	// Apply negative sign
	if (tmp_value < 0) *ptr++ = '-';
	*ptr-- = '\0';
	while(ptr1 < ptr) {
		tmp_char = *ptr;
		*ptr--= *ptr1;
		*ptr1++ = tmp_char;
	}
	return result;
}

vector<string> errors;
vector<string> values;
set<string> symbols;
vector< vector<string> > all;
map<string, string> symbol_type;
struct parser_tree* rec;

// 符号表检查
void symbol_check(struct parser_tree* node, int _flag, string tp) {
	if (node == NULL) return;
	values.push_back(node->node_value);
	all.push_back({node->node_type, node->node_value});
	if (node->node_type == "definition_list") {
		for (int index = node->sibling.size() - 1; index >= 0; --index) {
			symbol_check(node->sibling[index], _flag, tp);
		}
		if (node->node_value == "Expr_assign") {
			symbol_check(node->left, 1, tp);
			symbol_check(node->right, -1, tp);
		} else {
			symbol_check(node->left, _flag, tp);
		}
	} else if (node->node_type == "variable") {
		for (int index = node->sibling.size() - 1; index >= 0; --index) {
			symbol_check(node->sibling[index], _flag, tp);
		}
		string var_name = node->node_value;
		if (_flag == 1) {
			if (symbol_type.find(var_name) != symbol_type.end()) {
				string msg = var_name + " is defined repeatly";
				errors.push_back(msg);
			} else {
				symbol_type[var_name] = tp;
			}
		} else if (_flag == -1) {
			if (symbol_type.find(var_name) != symbol_type.end()) {
			} else {
				string msg = var_name + " is not defined";
				errors.push_back(msg);
			}
		}
	}
}
void reverse_check(struct parser_tree* node) {
	if(node == NULL) return;
	for (struct parser_tree* bros: node->sibling){
		reverse_check(bros);
	}
	if (node->node_type == "variable") {
		if (symbol_type.find(node->node_value) == symbol_type.end()){
			cout<< (string(node->node_value) + " is not defined")<<endl;
			return;
		}
	}
	reverse_check(node->left);
	reverse_check(node->right);
	reverse_check(node->temp1);
	reverse_check(node->temp2);
}
#pragma warning (disable : 4996)
%}
// YYTYPE
// yylval
%union{
	char* str;
	struct parser_tree* root;
	double d;
	char c;
	int i;
	float f;
}
// tokens generated in y.tab.h
%token <str> ID
%token <str> INTEGER_VALUE
%token <str> FLOAT_VALUE
%token <str> CHAR_VALUE
%token <str> DOUBLE_VALUE
%token <str> COMMENT COMMENTS
%token INT FLOAT VOID DOUBLE CHAR FOR MAIN READ WRITE RETURN IF ELSE WHILE WHITESPACE SQM COMMA ASSIGN EG EL EQ GT LT PLUS MINUS MUL DIV AND OR NOT LP RP LC RC MOD BITAND BITOR EN DPLUS DMINUS BITXOR
%type <root> Program main_type complete_statement statements statement definition_statement type_name definition_list variable expression while_statement 
bool_expression read_statement write_statement for_statement for_list for_expression_1 for_expression_2 for_expression_3 if_statement left_expression variable_list comment_statement

%left COMMA
%right ASSIGN // =
%left OR	  // ||
%left AND     // &&
%left BITOR 
%left BITXOR
%left BITAND  // &
%left EQ EN   // == !=
%left LT GT EG EL   // < > <= >=
%left BITLEFT BITRIGHT // << >>
%left PLUS MINUS    // + -
%left MUL DIV MOD// * / %
%nonassoc NOT DPLUS DMINUS NSIGN PSIGN//! ++a --a negative_sign positive_sign
%nonassoc BDPLUS BDMINUS//a++ a-- 

%%
Program:main_type MAIN LP RP complete_statement{
		$$ = node($1,$5,"Program","NULL",NULL);
		if (errors.size() == 0)	{
			eval($$,0);
		}
	}
    ;
main_type:INT{$$ = node("main_type","int",NULL);}
    |VOID{$$ = node("main_type","void",NULL);}
	|{$$ = node("main_type","NULL",NULL);}
	;
complete_statement:LC statements RC{$$ = node($2,"complete_statement","NULL",NULL);}
         ;
statements:statement statements{/*$$ = node($1,$2,"statements","statements",NULL);*/
		($2->sibling).push_back($1);
		$$ = $2;
	 }
     |statement{$$ = $1;}
	 ;
statement:definition_statement{$$ = node($1,"statement","definition_statement",NULL);}
    |if_statement{$$ = node($1,"statement","if_statement",NULL);}
	|while_statement{$$ = node($1,"statement","while_statement",NULL);}
	|read_statement{$$ = node($1,"statement","read_statement",NULL);}
	|write_statement{$$ = node($1,"statement","write_statement",NULL);}
	|expression SQM{
		reverse_check($1);
	$$ = node($1,"statement","expression;",NULL);}
	|SQM{$$ = node("statement",";",NULL);}
	|LC RC{$$ = node("statement",";",NULL);}
	|complete_statement{$$ = node($1,"statement","complete_statement",NULL);}
	|for_statement{$$ = node($1,"statement","for_statement",NULL);}
	|statement comment_statement{$$ = $1;}
	|comment_statement statement{$$ = $2;}
	|RETURN INTEGER_VALUE SQM{$$ = node("statement", "Return", NULL);}
	;
comment_statement:COMMENT{$$ = node(NULL,NULL,NULL);}
      |COMMENTS{$$ = node(NULL,NULL,NULL);}
	  |COMMENT comment_statement{$$ =$2;}
	  |COMMENTS comment_statement{$$ = $2;}
	  ;
definition_statement:type_name definition_list SQM{
	$$ = node($1, $2, "definition_statement", "NULL", NULL);
	symbol_check($2, 1, $1->node_value);
	}
   ;
type_name:INT{$$ = node("type_name","int",NULL);}
    |VOID{$$ = node("type_name","void",NULL);}
	|CHAR{$$ = node("type_name","char",NULL);}
	|FLOAT{$$ = node("type_name","float",NULL);}
	|DOUBLE{$$ = node("type_name","double",NULL);}
	;
definition_list:left_expression{$$ = $1;}
       |left_expression ASSIGN expression{$$ = node($1,$3,"definition_list","Expr_assign",NULL);}
	   |left_expression COMMA definition_list{
	   		$3->sibling.push_back($1);
			$$ = $3;
	   }
	   |left_expression ASSIGN expression COMMA definition_list{
	   struct  parser_tree* temp = node($1,$3,"definition_list","Expr_assign",NULL);
	   $5->sibling.push_back(temp);
	   $$ = $5;
	   }
	   ;
variable:ID{
	$$ = node("variable",$1,"NULL");
	symbols.insert($1);
	}
   ;
left_expression:variable{$$ = $1;$$->node_helper="left_expression";}
         |LP variable RP{$$ = $2;$$->node_helper="left_expression";}
		 |LP variable_list RP{$$ = $2;$$->node_helper="left_expression";}
		 ;
variable_list:variable{$$ = $1;}
       |variable COMMA variable_list{$$ = $3;}
	   ;
expression:expression PLUS expression{
	if(!($1->node_type=="expression")&&!($3->node_type=="expression")){
			if(!(is_val($1)&&is_val($3))){
				if($1->node_type=="variable") 
					if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
				if($3->node_type=="variable") 
					if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
				$$ = node($1,$3,"expression","Add",NULL);
			}
			else{	
				int temp1,temp2=0;
				double temp3,temp4=0;
				char c[20]="";
				// implicit conversion
				if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
				if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
				if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
				if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
				if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1+temp2,c,10);$$ = node(c,"Val",c,"int");}
				if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp1+temp4);$$ = node(c,"Val",c,"double");}
				if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {sprintf(c,"%f",temp3+temp2);$$ = node(c,"Val",c,"double");}
				if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp3+temp4);$$ = node(c,"Val",c,"double");}
			}
		}
	else{
		$$ = node($1,$3,"expression","Add",NULL);
	}
	}
	|expression MINUS expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","MINUS",NULL);
			}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			// implicit conversion
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1-temp2,c,10);$$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp1-temp4);$$ = node(c,"Val",c,"double");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {sprintf(c,"%f",temp3-temp2);$$ = node(c,"Val",c,"double");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp3-temp4);$$ = node(c,"Val",c,"double");}
			}
	}
	|expression MUL expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Mul",NULL);
			}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			// implicit conversion
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1*temp2,c,10);$$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp1*temp4);$$ = node(c,"Val",c,"double");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {sprintf(c,"%f",temp3*temp2);$$ = node(c,"Val",c,"double");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp3*temp4);$$ = node(c,"Val",c,"double");}
		}
	}
	|expression DIV expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Div",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			// implicit conversion
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1/temp2,c,10);$$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp1/temp4);$$ = node(c,"Val",c,"double");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {sprintf(c,"%f",temp3/temp2);$$ = node(c,"Val",c,"double");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {sprintf(c,"%f",temp3/temp4);$$ = node(c,"Val",c,"double");}
		}
	}
	|expression BITOR expression{
		if(($1->node_type=="expression"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_or", "");
		}
		else if(($1->node_type=="variable"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_or", "");
		}
		else if(($1->node_type=="expression"&&$3->node_type=="variable")) {
			$$ = node($1, $3, "expression", "Bit_or", "");
		}
		else if(($1->node_type=="Val"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_or", "");
		}
		else if(($1->node_type=="expression"&&$3->node_type=="Val")) {
			$$ = node($1, $3, "expression", "Bit_or", "");
		}



	else if(($1->node_type=="variable")&&($3->node_type=="variable")){
		cout << "aaa" <<$1->node_value<<" " << $3->node_value <<endl;
		if(!((symbol_type.count($1->node_value)>0)&&(symbol_type.count($3->node_value)>0)))
		 {cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char")))
		 {$$ = node($1,$3,"expression","Bit_or",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else if($1->node_type=="variable"&&$3->node_type=="Val"){
		if(!(symbol_type.count($1->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&(($3->node_helper=="int")||($3->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_or",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else if($3->node_type=="variable"&&$1->node_type=="Val"){
		if(!(symbol_type.count($3->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))&&(($1->node_helper=="int")||($1->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_or",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else{	
			int temp1,temp2=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") printf("%s","type error");
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") printf("%s","type error");
			itoa(temp1|temp2,c,10); 
			$$ = node(c,"Val",c,"int");
		}
	}
	|expression BITXOR expression{
		if(($1->node_type=="expression"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_xor", "");
		}
		else if(($1->node_type=="variable"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_xor", "");
		}
		else if(($1->node_type=="expression"&&$3->node_type=="variable")) {
			$$ = node($1, $3, "expression", "Bit_xor", "");
		}
		else if(($1->node_type=="Val"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_xor", "");
		}
		else if(($1->node_type=="expression"&&$3->node_type=="Val")) {
			$$ = node($1, $3, "expression", "Bit_xor", "");
		}


	else if(($1->node_type=="variable")&&($3->node_type=="variable")){
		if(!((symbol_type.count($1->node_value)>0)&&(symbol_type.count($3->node_value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))) {$$ = node($1,$3,"expression","Bit_xor",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else if($1->node_type=="variable"&&$3->node_type=="Val"){
		if(!(symbol_type.count($1->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&(($3->node_helper=="int")||($3->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_xor",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else if($3->node_type=="variable"&&$1->node_type=="Val"){
		if(!(symbol_type.count($3->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))&&(($1->node_helper=="int")||($1->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_xor",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else{	
			int temp1,temp2=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") printf("%s","type error");
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") printf("%s","type error");
			itoa(temp1^temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|expression BITAND expression{
		if(($1->node_type=="expression"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_and", "");
		}
		else if(($1->node_type=="variable"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_and", "");
		}
		else if(($1->node_type=="expression"&&$3->node_type=="variable")) {
			$$ = node($1, $3, "expression", "Bit_and", "");
		}
		else if(($1->node_type=="Val"&&$3->node_type=="expression")) {
			$$ = node($1, $3, "expression", "Bit_and", "");
		}
		else if(($1->node_type=="expression"&&$3->node_type=="Val")) {
			$$ = node($1, $3, "expression", "Bit_and", "");
		}
	else if(($1->node_type=="variable")&&($3->node_type=="variable")){
		if(!((symbol_type.count($1->node_value)>0)&&(symbol_type.count($3->node_value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))) {$$ = node($1,$3,"expression","Bit_and",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else if($1->node_type=="variable"&&$3->node_type=="Val"){
		if(!(symbol_type.count($1->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&(($3->node_helper=="int")||($3->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_and",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else if($3->node_type=="variable"&&$1->node_type=="Val"){
		if(!(symbol_type.count($3->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))&&(($1->node_helper=="int")||($1->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_and",NULL);}
		else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
	}
	else{
			int temp1,temp2=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") printf("%s","type error");
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") printf("%s","type error");
			itoa(temp1&temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|expression MOD expression{
		if(($1->node_type=="variable")&&($3->node_type=="variable")){
			if(!((symbol_type.count($1->node_value)>0)&&(symbol_type.count($3->node_value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))) {$$ = node($1,$3,"expression","Mod",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else if($1->node_type=="variable"&&$3->node_type=="Val"){
			if(!(symbol_type.count($1->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&(($3->node_helper=="int")||($3->node_helper=="char"))) {$$ = node($1,$3,"expression","Mod",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else if($3->node_type=="variable"&&$1->node_type=="Val"){
			if(!(symbol_type.count($3->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))&&(($1->node_helper=="int")||($1->node_helper=="char"))) {$$ = node($1,$3,"expression","Mod",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else{
			int temp1,temp2=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") printf("%s","type error");
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") printf("%s","type error");
			itoa(temp1%temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|expression BITRIGHT expression{
		if(($1->node_type=="variable")&&($3->node_type=="variable")){
			if(!((symbol_type.count($1->node_value)>0)&&(symbol_type.count($3->node_value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))) {$$ = node($1,$3,"expression","Bit_right",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else if($1->node_type=="variable"&&$3->node_type=="Val"){
			if(!(symbol_type.count($1->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&(($3->node_helper=="int")||($3->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_right",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else if($3->node_type=="variable"&&$1->node_type=="Val"){
			if(!(symbol_type.count($3->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))&&(($1->node_helper=="int")||($1->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_right",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else{
			int temp1,temp2=0;
			char c[20]="";
			if($1->node_helper=="float"||$1->node_helper=="double"||$3->node_helper=="float"||$3->node_helper=="double") printf("type error");
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			itoa(temp1>>temp2,c,10); 
			$$ = node(c,"Val",c,"int");

		}
	}
	|expression BITLEFT expression{
		if(($1->node_type=="variable")&&($3->node_type=="variable")){
			if(!((symbol_type.count($1->node_value)>0)&&(symbol_type.count($3->node_value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))) {$$ = node($1,$3,"expression","Bit_left",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else if($1->node_type=="variable"&&$3->node_type=="Val"){
			if(!(symbol_type.count($1->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->node_value]=="int")||(symbol_type[$1->node_value]=="char"))&&(($3->node_helper=="int")||($3->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_left",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else if($3->node_type=="variable"&&$1->node_type=="Val"){
			if(!(symbol_type.count($3->node_value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$3->node_value]=="int")||(symbol_type[$3->node_value]=="char"))&&(($1->node_helper=="int")||($1->node_helper=="char"))) {$$ = node($1,$3,"expression","Bit_left",NULL);}
			else {cout<<"error:use the expression with wrong number"<<endl;return 0;}
		}
		else{
		    int temp1,temp2=0;
		    char c[20]="";
			if($1->node_helper=="float"||$1->node_helper=="double"||$3->node_helper=="float"||$3->node_helper=="double") {printf("type error\n");return 0;}
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			itoa(temp1<<temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|expression EG expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_EG",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")){itoa(temp1>=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp1>=temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3>=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp3>=temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|expression EL expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_EL",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")){itoa(temp1<=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp1<=temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3<=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp3<=temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|expression EQ expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable")
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_EQ",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1==temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp1==temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3==temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {itoa(temp3==temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|expression EN expression{
		if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_EN",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1!=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp1!=temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3!=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {itoa(temp3!=temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|expression GT expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_GT",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1>temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")) {itoa(temp1>temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3>temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp3>temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|expression LT expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_LT",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1<temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")) {itoa(temp1<temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3<temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {itoa(temp3<temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|expression AND expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_and",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp1&&temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")) {itoa(temp1&&temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3&&temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")) {itoa(temp3&&temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|expression OR expression{
	if(!(is_val($1)&&is_val($3))){
			if($1->node_type=="variable") 
				if(symbol_type.count($1->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->node_type=="variable") 
				if(symbol_type.count($3->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"expression","Cmp_OR",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->node_helper=="int"||$1->node_helper=="char") temp1=atoi($1->node_var);
			if($1->node_helper=="float"||$1->node_helper=="double") temp3=atof($1->node_var);
			if($3->node_helper=="int"||$3->node_helper=="char") temp2=atoi($3->node_var);
			if($3->node_helper=="float"||$3->node_helper=="double") temp4=atof($3->node_var);
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="int"||$3->node_helper=="char")){itoa(temp1||temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="int"||$1->node_helper=="char")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp1||temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="int"||$3->node_helper=="char")) {itoa(temp3||temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->node_helper=="float"||$1->node_helper=="double")&&($3->node_helper=="float"||$3->node_helper=="double")){itoa(temp3||temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}

	|expression ASSIGN expression{
	if($1->node_type=="variable"){
			$$ = node($1,$3,"expression","Assign",NULL);
		}
	else if($1->node_value=="(expression)"){
		if(($1->left)->node_type=="variable") {
				$$ = node($1,$3,"expression","Assign",NULL);
		}
		else if(($1->left)->node_value=="++front") $$ = node($1,$3,"expression","Assign",NULL);
		else if(($1->left)->node_value=="--front") $$ = node($1,$3,"expression","Assign",NULL);
		else{cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
	}
	else if($1->node_value=="++front") $$ = node($1,$3,"expression","Assign",NULL);
	else if($1->node_value=="--front") $$ = node($1,$3,"expression","Assign",NULL);
	else if($1->node_value=="back++"||$1->node_value=="back--"){cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
	if(is_val($1)){
			cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;
		}
	else{
			$$ = node($1,$3,"expression","Assign",NULL);
		}
	}
	|NOT expression{
	if(!is_val($2)){
			if($2->node_type=="variable") 
				if(symbol_type.count($2->node_value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($2,"expression","Not","NULL");
		}
	else{
			int temp1=0;
			double temp3=0;
			char c[20]="";
			if($2->node_helper=="int"||$2->node_helper=="char") {temp1=atoi($2->node_var);itoa(!temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->node_helper=="float"||$2->node_helper=="double") {temp3=atof($2->node_var);itoa(!temp3,c,10);$$ = node(c,"Val",c,"int");}
		}
	}
	|DPLUS expression{
	if(!is_val($2)){
			if($2->node_type=="variable") $$ = node($2,"expression","++front",NULL);
			else if($2->node_value=="++front") $$ = node($2,"expression","++front",NULL);
			else if($2->node_value=="--front") $$ = node($2,"expression","++front",NULL);
			else if($2->node_value=="(expression)"){
				if(($2->left)->node_type=="variable") {$$ = node($2,"expression","++front",NULL);}
				else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
			}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($2->node_helper=="int") {temp1=atoi($2->node_var);itoa(++temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->node_helper=="char") {temp2=atoi($2->node_var);itoa(++temp2,c,10);$$ = node(c,"Val",c,"char");}
			if($2->node_helper=="double") {temp3=atof($2->node_var);sprintf(c,"%f",++temp3);$$ = node(c,"Val",c,"double");}
			if($2->node_helper=="float") {temp4=atof($2->node_var);sprintf(c,"%f",++temp4);$$ = node(c,"Val",c,"float");}
		}
	}
	|DMINUS expression{
	if(!is_val($2)){
			if($2->node_type=="variable") $$ = node($2,"expression","--front",NULL);
			else if($2->node_value=="++front") $$ = node($2,"expression","--front",NULL);
			else if($2->node_value=="--front") $$ = node($2,"expression","--front",NULL);
			else if($2->node_value=="(expression)"){
				if(($2->left)->node_type=="variable") {
					$$ = node($2,"expression","--front",NULL);
					}
					else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
					}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}

	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($2->node_helper=="int") {temp1=atoi($2->node_var);itoa(--temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->node_helper=="char") {temp2=atoi($2->node_var);itoa(--temp2,c,10);$$ = node(c,"Val",c,"char");}
			if($2->node_helper=="double") {temp3=atof($2->node_var);sprintf(c,"%f",--temp3);$$ = node(c,"Val",c,"double");}
			if($2->node_helper=="float") {temp4=atof($2->node_var);sprintf(c,"%f",--temp4);$$ = node(c,"Val",c,"float");}
		}
	}
	|expression DPLUS %prec BDPLUS{
	if(!is_val($1)){
			if($1->node_type=="variable") $$ = node($1,"expression","back++",NULL);
			else if($1->node_value=="++front") $$ = node($1,"expression","back++",NULL);
			else if($1->node_value=="--front") $$ = node($1,"expression","back++",NULL);
			else if($1->node_value=="(expression)"){
				if(($1->left)->node_type=="variable") {
					$$ = node($1,"expression","back++","NULL");
					}
					else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
					}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($1->node_helper=="int") {temp1=atoi($1->node_var);itoa(temp1++,c,10);$$ = node(c,"Val",c,"int");}
			if($1->node_helper=="char") {temp2=atoi($1->node_var);itoa(temp2++,c,10);$$ = node(c,"Val",c,"char");}
			if($1->node_helper=="double") {temp3=atof($1->node_var);sprintf(c,"%f",temp3++);$$ = node(c,"Val",c,"double");}
			if($1->node_helper=="float") {temp4=atof($1->node_var);sprintf(c,"%f",temp4++);$$ = node(c,"Val",c,"float");}
		}
	}
	|expression DMINUS %prec BDMINUS{
	if(!is_val($1)){
			if($1->node_type=="variable") $$ = node($1,"expression","back--",NULL);
			else if($1->node_value=="++front") $$ = node($1,"expression","back--",NULL);
			else if($1->node_value=="--front") $$ = node($1,"expression","back--",NULL);
			else if($1->node_value=="(expression)"){
				if(($1->left)->node_type=="variable") {
					$$ = node($1,"expression","back--","NULL");
					}
					else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
					}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($1->node_helper=="int") {temp1=atoi($1->node_var);itoa(temp1--,c,10);$$ = node(c,"Val",c,"int");}
			if($1->node_helper=="char") {temp2=atoi($1->node_var);itoa(temp2--,c,10);$$ = node(c,"Val",c,"char");}
			if($1->node_helper=="double") {temp3=atof($1->node_var);sprintf(c,"%f",temp3--);$$ = node(c,"Val",c,"double");}
			if($1->node_helper=="float") {temp4=atof($1->node_var);sprintf(c,"%f",temp4--);$$ = node(c,"Val",c,"float");}
		}
	}
	|PLUS expression %prec PSIGN{ $$ = node($2,"expression","+expression",NULL);}
	|MINUS expression %prec NSIGN{
	if(!is_val($2)){
			$$ = node($2,"expression","-expression",NULL);
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($2->node_helper=="int") {temp1=atoi($2->node_var);itoa(-temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->node_helper=="char") {temp2=atoi($2->node_var);itoa(-temp2,c,10);$$ = node(c,"Val",c,"char");}
			if($2->node_helper=="double") {temp3=atof($2->node_var);sprintf(c,"%f",-temp3);$$ = node(c,"Val",c,"double");}
			if($2->node_helper=="float") {temp4=atof($2->node_var);sprintf(c,"%f",-temp4);$$ = node(c,"Val",c,"float");}
		}
	}
	|LP expression RP{
		rec = $2;
		if($2->node_type=="Val"){$$ = node($2->node_value,"Val",$2->node_value,$2->node_helper);cout<<"node_value:"<<$2->node_value;}
		else {$$ = node($2,"expression","(expression)",NULL);}
	  }
	|expression COMMA expression{
		$3->sibling.push_back($1);
		$$ = $3;
		rec = $$;}
	|variable{$$ = $1;}
	|INTEGER_VALUE{$$ = node($1,"Val",$1,"int");}
	|FLOAT_VALUE{$$ = node($1,"Val",$1,"float");}
	|CHAR_VALUE{$$ = node($1,"Val",$1,"char");}
	|DOUBLE_VALUE{$$ = node($1,"Val",$1,"double");}
	;
if_statement:IF LP bool_expression RP statement{$$ = node($3,$5,"if_statement","if(...) ...",NULL);}
  |IF LP bool_expression RP statement ELSE statement{$5->node_helper = "IF_BRANCH"; $7->node_helper = "ELSE_BRANCH ";  $$ = node($3,$5,$7,"if_statement","if(...) .. else ...",NULL);}
  ;
while_statement:WHILE LP bool_expression RP statement{$$ = node($3,$5,"while_statement","NULL",NULL);}
     ;
bool_expression:expression{$$ = node($1,"bool_expression","expression",NULL);}
	;
read_statement:READ LP variable RP SQM{$$ = node($3,"read_statement","NULL",NULL);}
    ;
write_statement:WRITE LP expression RP SQM{$$ = node($3,"write_statement","NULL",NULL);}
     ;
for_statement:FOR LP for_list RP statement{$$ = node($3,$5,"for_statement","NULL",NULL);}
   ;
for_list:for_expression_1 SQM for_expression_2 SQM for_expression_3{$$ = node($1,$3,$5,"for_list",NULL,NULL);}
        ;
for_expression_1:variable{$$ = node($1,"for_expression_1","NULL",NULL);}
         |expression{$$ = node($1,"for_expression_1","NULL",NULL);}
		 |{$$ = node("for_expression_1 NULL","NULL",NULL);}
		 ;
for_expression_2:expression{$$ = node($1,"for_expression_2","NULL",NULL);}
		 |{$$ = node("for_expression_2 NULL","NULL",NULL);}
		 ;
for_expression_3:expression{$$ = node($1,"for_expression_3","NULL",NULL);}
         |{$$ = node("for_expression_3 NULL","NULL",NULL);}
		 ;

%%

int main(void)
{
	freopen("input","r",stdin);
	freopen("output","w",stdout);
	yyparse();
	return 1;
}
