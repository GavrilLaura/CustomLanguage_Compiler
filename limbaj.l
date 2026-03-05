%{
#include <stdio.h>
#include "limbaj.tab.h"
#include <string>
%}
%option noyywrap
%%
"int"   { yylval.Str = new std::string(yytext); return TYPE; }
"float" { yylval.Str = new std::string(yytext); return TYPE; }
"string" { yylval.Str = new std::string(yytext); return TYPE; }
"bool" { yylval.Str = new std::string(yytext); return TYPE; }
"void" { yylval.Str = new std::string(yytext); return TYPE; }
"Print" { return PRINT; }
"START_MAIN" { return BGIN; }
"END_MAIN" { return END; }
"class" { return CLASS; }
"if"    { return IF; }
"else"  { return ELSE; }
"while" { return WHILE; }
"." { return DOT; }
"{" {return BR_ST;}
"}" {return BR_DR;}
"true"|"false" { return BOOL_LIT; }    /* Literali boolean */
"return" { return RETURN; }
"new"    { return NEW; }
[_a-zA-Z][_a-zA-Z0-9]* {yylval.Str = new std::string(yytext); return ID;}
[0-9]+                 { return INT_LIT; }     /* Intregi */
[0-9]+\.[0-9]+         { return FLOAT_LIT; }   /* Numere cu virgula (float) */
"+"                     { return PLUS; }
"-"                     { return MINUS; }
"*"                     { return TIMES; }
"/"                     { return DIVIDE; }
"<"                     { return LT; }
">"                     { return GT; }
"=="                    { return EQ; }
"&&"                    { return AND; }
"||"                    { return OR; }
"!"                     { return NOT; }
[ \t]+                  ; /* Ignora spatiile si taburile */
\"[^"]*\"               { return STRING_LIT; }  /* Siruri de caractere */
";"                    { return ';'; }
"<-"                    { return ASSIGN; }
"("                    { return '('; }
")"                    { return ')'; }
","                    { return ','; }
":"                    { return ':'; }
\n {yylineno++;}
. {return yytext[0];}
