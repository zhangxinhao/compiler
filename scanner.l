%{
#include "token.h"
#include "symbolTable.h"
int cur_line_num = 1;
void lex_error(char* msg, int line, char* str);
%}

INTEGER             ([0-9]+)
UNTERM_STRING       (\042[^\042\n]*)
STRING              (\042[^\042\n]*\042)
IDENTIFIER          ([_a-zA-Z][_a-zA-Z0-9]*)
OPERATOR            ([+*-/%=,;!<>(){}])
COMMENT             ("//"[^\n]*)
COMMENTS            ("/*"(([^\*]*(\*[^\/])?)*)"*/")

%%

[\n]                { cur_line_num++;         }
[ \t\r\a]+          {                         }
{COMMENT}           {                         }
{COMMENTS}          {                         }

{OPERATOR}          { return yytext[0];       }

"++"                { return DPLUS;           }
"--"                { return DMINUS;          }
"<="                { return LE;              }
">="                { return GE;              }
"=="                { return EQ;              }
"!="                { return NE;              }
"&&"                { return AND;             }
"||"                { return OR;              }
"main"              { return MAIN;            }
"void"              { return VOID;            }
"int"               { return INT;             }
"while"             { return WHILE;           }
"if"                { return IF;              }
"else"              { return ELSE;            }
"return"            { return RETURN;          }
"break"             { return BREAK;           }
"continue"          { return CONTINUE;        }
"printf"            { return PRINTF;          }
"scanf"             { return SCANF;           }

{INTEGER}           { return NUMBER;          }
{STRING}            { return STRING;          }
{IDENTIFIER}        { return ID;              }

<<EOF>>             { return 0; }

{UNTERM_STRING}     { lex_error("Unterminated string constant", cur_line_num, yytext);  }
[_a-zA-Z0-9]*       { lex_error("Illegal identifier", cur_line_num, yytext);            }
.                   { lex_error("Unrecognized character", cur_line_num, yytext);        }

%%

int main(int argc, char* argv[]) {
    int token;
    SymbolTable st;
    string check;

    while ((token = yylex())) {
        if (token == ID) {
            print_token(token);
            printf("%-20s", yytext);
            check = st.find(yytext);
            if (check != "-1") {
                printf("%-20s\n", check.c_str());
            } else {
                st.insert(yytext, "local", "keyword", cur_line_num);
                check = st.find(yytext);
                printf("%-20s\n", check.c_str());
            }
        } else {
            print_token(token);
            puts(yytext);
        }
    }
    return 0;
}

void lex_error(char* msg, int line, char* str) {
    printf("\nError at line %-3d: %s\t%s\n\n", line, msg, str);
}

int yywrap(void) {
    return 1;
}