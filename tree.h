#include<iostream>
#include<vector>
using namespace std;
struct parser_tree
{
	struct parser_tree *left;
	struct parser_tree *right;
	struct parser_tree *temp1;
	struct parser_tree *temp2;
	char* node_type;
	char* node_value;
	char* node_helper;
	char* node_var;
	int num;
	std::vector<struct parser_tree*> sibling;
};

extern struct parser_tree *node(char *_type, char *value, char *_helper);
extern struct parser_tree *node(char *v, char *_type, char *value, char *_helper);
extern struct parser_tree *node(parser_tree *a, char *_type, char *value, char *_helper);
extern struct parser_tree *node(parser_tree *a, parser_tree *b, char *_type, char *value, char *_helper);
extern struct parser_tree *node(parser_tree *a, parser_tree *b, parser_tree *c, char *_type, char *value, char *_helper);
extern void eval(struct parser_tree *root, int level);
extern bool is_val(struct parser_tree *root);



