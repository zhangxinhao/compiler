%{
#include "y.tab.h"
#include "stdio.h"
#include "stdlib.h"
#include "tree.h"
#include <cstring>
#define YYTYPE char*
#pragma warning (disable : 4996)

%}
%option yylineno
VOID            void
MAIN            main
INT             int
CHAR            char
FLOAT           float
DOUBLE          double
ASSIGN          =
IF              if
ELSE            else
WHILE           while
FOR             for
BREAK           break
CONTINUE        continue
PLUS            \+
DPLUS           \+\+
MINUS           \-
DMINUS          \-\-
MUL             \*
DIV             \/
MOD             \%
BITOR           \|
BITAND          \&
BITXOR          \^
EG              \>=
EL              \<=
EQ              ==
EN              !=
BITLEFT         \<\<
BITRIGHT        \>\>
GT              \>
LT              \<
AND             \&\&
OR              \|\|
NOT             !
LP              \(
RP              \)
LC              \{
RC              \}
RETURN          return
COMMA           ,
SQM             ;
COMMENT         \/\/(.*){DELIM}*$
COMMENTS        "/*"(([^\*]*(\*[^\/])?)*)"*/"
DELIM           [ \t\r]
NEWLINE         \n
WHITESPACE      {DELIM}+
LETTER          [a-zA-Z]
DIGIT           [0-9]
INTEGER_VALUE   ([1-9]{DIGIT}*|0)
FLOAT_VALUE     {DOUBLE_VALUE}(f|F)
DOUBLE_VALUE    ({DIGIT}*\.{DIGIT}*)|({INTEGER_VALUE}(e|E)-?{INTEGER_VALUE})
CHAR_VALUE      \'.\'
STRING_VALUE    \"(.*)\"
READ            read
WRITE           write
ID              (_|{LETTER})(_|{LETTER}|{DIGIT})*
%%


{MAIN}          { return MAIN;       }
{INT}           { return INT;        }
{VOID}          { return VOID;       }
{FLOAT}         { return FLOAT;      }
{DOUBLE}        { return DOUBLE;     }
{CHAR}          { return CHAR;       }
{ASSIGN}        { return ASSIGN;     }
{IF}            { return IF;         }
{ELSE}          { return ELSE;       }
{WHILE}         { return WHILE;      }
{PLUS}          { return PLUS;       }
{MINUS}         { return MINUS;      }
{FOR}           { return FOR;        }
{MUL}           { return MUL;        }
{DIV}           { return DIV;        }
{EG}            { return EG;         }
{EL}            { return EL;         }
{EQ}            { return EQ;         }
{BITLEFT}       { return BITLEFT;    }
{BITRIGHT}      { return BITRIGHT;   }
{GT}            { return GT;         }
{LT}            { return LT;         }
{AND}           { return AND;        }
{OR}            { return OR;         }
{NOT}           { return NOT;        }
{LP}            { return LP;         }
{RP}            { return RP;         }
{LC}            { return LC;         }
{RC}            { return RC;         }
{RETURN}        { return RETURN;     }
{COMMA}         { return COMMA;      }
{SQM}           { return SQM;        }
{MOD}           { return MOD;        }
{BITAND}        { return BITAND;     }
{BITOR}         { return BITOR;      }
{BITXOR}        { return BITXOR;     }
{READ}          { return READ;       }
{WRITE}         { return WRITE;      }
{EN}            { return EN;         }
{DPLUS}         { return DPLUS;      }
{DMINUS}        { return DMINUS;     }
{ID}            { yylval.str = new char[strlen(yytext)]; strcpy(yylval.str, yytext); return ID;              }
{INTEGER_VALUE} { yylval.str = new char[strlen(yytext)]; strcpy(yylval.str, yytext); return INTEGER_VALUE;   }
{FLOAT_VALUE}   { yylval.str = new char[strlen(yytext)]; strcpy(yylval.str, yytext); return FLOAT_VALUE;     }    
{CHAR_VALUE}    { yylval.str = new char[strlen(yytext)]; strcpy(yylval.str, yytext); return CHAR_VALUE;      }
{DOUBLE_VALUE}  { yylval.str = new char[strlen(yytext)]; strcpy(yylval.str, yytext); return DOUBLE_VALUE;    }
{COMMENT}       { yylval.str = new char[strlen(yytext)]; strcpy(yylval.str, yytext); return COMMENT;         }
{COMMENTS}      { yylval.str = new char[strlen(yytext)]; strcpy(yylval.str, yytext); return COMMENTS;        }

%%
int yywrap(void)
{
 return 1;
}
