scanner: lex.yy.c token.h
	g++ -w -std=c++11 -o scanner lex.yy.c symbolTable.cpp

lex.yy.c: scanner.l
	flex $<

run:
	make && ./scanner < sample.c > out.txt

clean:
	rm lex.yy.c scanner && : > out.txt