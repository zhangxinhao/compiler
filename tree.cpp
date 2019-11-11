#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<stdarg.h>
#include"tree.h"

int i;

struct parser_tree *node(char *_type, char *value, char *_helper)
{
	struct parser_tree *root = new parser_tree();
	if (!root)
	{
		printf("Out of space! Program failed. ");
		exit(0);
	}
	root->node_type = _type;
	root->node_value = value;
	root->node_helper = _helper;
	root->node_var = NULL;
	root->left = NULL;
	root->right = NULL;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}

struct parser_tree *node(char* v, char *_type, char *value, char *_helper)
{
	struct parser_tree *root = new parser_tree();
	//struct parser_tree *root = (struct parser_tree*)malloc(sizeof(struct parser_tree));
	if (!root)
	{
		printf("Out of space! Program failed. ");
		exit(0);
	}
	root->node_type = _type;
	root->node_value = value;
	root->node_helper = _helper;
	root->node_var = v;
	root->left = NULL;
	root->right = NULL;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}

struct parser_tree *node(parser_tree *a, char *_type, char *value, char *_helper)
{
	struct parser_tree *root = new parser_tree();
	if (!root)
	{
		printf("Out of space! Program failed. ");
		exit(0);
	}
	root->node_type = _type;
	root->node_value = value;
	root->node_helper = _helper;
	root->node_var = NULL;
	root->left = a;
	root->right = NULL;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}



struct parser_tree *node(parser_tree *a, parser_tree *b, char *_type, char *value, char *_helper)
{
	struct parser_tree *root = new parser_tree();
	if (!root)
	{
		printf("Out of space! Program failed. ");
		exit(0);
	}
	root->node_type = _type;
	root->node_value = value;
	root->node_helper = _helper;
	root->node_var = NULL;
	root->left = a;
	root->right = b;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}

struct parser_tree *node(parser_tree *a, parser_tree *b, parser_tree *c, char *_type, char *value, char *_helper)
{
	struct parser_tree *root = new parser_tree();
	if (!root)
	{
		printf("Out of space! Program failed. ");
		exit(0);
	}
	root->node_type = _type;
	root->node_value = value;
	root->node_helper = _helper;
	root->node_var = NULL;
	root->left = a;
	root->right = b;
	root->temp1 = c;
	root->temp2 = NULL;
	return root;
}

void sibling_eval(struct parser_tree*root) {
	if (root != NULL) {
		if (root->sibling.size() != 0)
		{
			for (int index = root->sibling.size() - 1; index >= 0; --index)
				eval(root->sibling[index], 0);
		}
	}
}

void sibling_print(struct parser_tree*root) {
	if (root != NULL) {
		if (root->sibling.size() != 0)
		{
			for (int index = root->sibling.size() - 1; index >= 0; --index)
				printf("%-3d", root->sibling[index]->num);
		}
	}
}
void eval(struct parser_tree*root, int level)
{
	static int num = -1;
	if (root != NULL)
	{
		eval(root->left, 0);
		sibling_eval(root->left);

		eval(root->right, 0);
		sibling_eval(root->right);

		eval(root->temp1, 0);
		sibling_eval(root->temp1);

		eval(root->temp2, 0);
		sibling_eval(root->temp2);

		num++;
		root->num = num;

		printf("%-3d: ", root->num);
		if (root->node_type != NULL)
		{
			printf("%-20s  ", root->node_type);
		}
		if (root->node_value != NULL)
		{
			if (root->node_value != "NULL"){
				printf("%-20s  ", root->node_value);
			}
		}

		printf("%-10s  ", "Children: ");
		if (root->left != NULL)
		{
			printf("%-3d", root->left->num);
			sibling_print(root->left);
		}
		if (root->right != NULL)
		{
			printf("%-3d", root->right->num);
			sibling_print(root->right);
		}
		if (root->temp1 != NULL)
		{
			printf("%-3d", root->temp1->num);
			sibling_print(root->temp1);
		}
		if (root->temp2 != NULL)
		{
			printf("%-3d", root->temp2->num);
			sibling_print(root->temp2);
		}

		printf("\n");
		
	}
}

bool is_val(struct parser_tree* root)
{
	if (root->node_type == "Val")
		return true;
	else
		return false;
}

