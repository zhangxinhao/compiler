#ifndef TOKEN_H
#define TOKEN_H

typedef enum {
    LE = 256, GE, EQ, NE, AND, OR, NUMBER,
    STRING, ID, VOID, INT, WHILE,
    IF, ELSE, RETURN, BREAK, CONTINUE, PRINTF,
    SCANF, MAIN, DMINUS, DPLUS
} TokenType;

static void print_token(int token) {
    static char* token_strs[] = {
        "LE", "GE", "EQ", "NE", "AND", "OR", "NUMBER",
        "STRING", "ID", "VOID", "INT", "WHILE",
        "IF", "ELSE", "RETURN", "BREAK", "CONTINUE", "PRINTF",
        "SCANF", "MAIN", "DMINUS", "DPLUS"
    };

    if (token < 256) {
        printf("%-20c", token);
    } else {
        printf("%-20s", token_strs[token-256]);
    }
}

#endif