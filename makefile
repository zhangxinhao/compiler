compiler: lex.yy.c tree.cpp y.tab.c
	g++ -w -std=c++11 lex.yy.c tree.cpp y.tab.c -o compiler

lex.yy.c: scanner.l
	flex -o lex.yy.c scanner.l

y.tab.c: parser.y
	bison -dy parser.y

clean:
	rm lex.yy.c y.tab.h y.tab.c compiler && : > output

run: compiler
	./compiler