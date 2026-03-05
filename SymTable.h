#ifndef SYMTABLE_H
#define SYMTABLE_H

#include <iostream>
#include <fstream>
#include <map>
#include <string>
#include <vector>
#include "AST.h"

using namespace std;

using std::string;
using std::vector;
using std::map;

//info despre variabilele declarate: tip + nume
class IdInfo {
    public:
    string type;
    string name;
    string value;
   
    IdInfo() {} //constructor gol
    IdInfo(string* type, string* name, string* value);//constructor tip + nume
};

//info despre functiile declarate: tipul rezultatului returnat + lista cu tipurile parametrilor
class FuncInfo {
public:
    string returnType;
    vector<string> paramTypes; //lista tipurilor parametrilor

    FuncInfo() {} //constructor gol
    FuncInfo(string returnType, vector<string> params) 
        : returnType(returnType), paramTypes(params) {} //constructor tipul de return + tipul parametrilor
};

//info despre tabela de simboluri propriu zisa
class SymTable {
    SymTable* parent;                       //pointer la scopeul parinte
    string scopeName;                       // numele scopului global main
    map<string, IdInfo> ids;                //map cu toate variabilele : nume + info var
    map<string, FuncInfo> funcs;            //map cu toate functiile vizibile in acest scope
    vector<string> classNames;              //lista cu numele claselor definite
    map<string, SymTable*> classScopes;     //map cu numele claselor si tabela de simboluri
    map<string, SymTable*> functionScopes;  //map cu numele functiilor si tabela de simboluri

public:
    SymTable(string name, SymTable* parent=nullptr);                        //constructor
    SymTable* getParent();                                                  //returneaza pointer catre parinte (tabela superioara)
    SymTable* getClassScope(string className);                              //returneaza domeniul unei clase
    bool existsId(string* s);                                               //verif daca o var a mai fost declarata (NU cauta si in parinte)
    bool existsFunc(string name);                                           //verif daca o functie exista (cauta si in parinte)
    bool existsFunc_local(string name);                                     //verif daca o functie exista (NU cauta si in parinte)
    void addVar(string* type, string* name);                                //adauga o var in ids
    void addFuncs(string name, string returnType, vector<string> params);   //adauga o functie in funcs
    string* getType(string* id);                                            //det tipul unei variabile (si in parinte)
    string getFuncReturnType(string funcName);                              //det tipul returnat de o functie
    vector<string> getFuncParams(string name);                              //det parametrii unei functii
    void addClass(string name);                                             //adauga o clasa in classNames
    void addClassScope(string name, SymTable* scope);                       //adauga scope-ul unei clasei 
    void addFunctionScope(string name, SymTable* scope);                    //adauga scope-ul unei functii
    bool isClass(string name);                                              //verif daca un identificator este nume de clasa valid
    //void printVars();                                                       //afiseaza din tabela
    void printTables(ofstream& file);                                       //afiseaza in tables.txt   
    string getVarValue(string name);                                        //returneaza valoarea unei variabile din symtable
    void updateVarValue(string name, string val);                           //actualizeaza valoare unei variabile
    ~SymTable();                                                            //destructor
};

string check_arithmetic(const string& st, const string& dr, const char* op);      //verifica validitatea op matematice             
string check_boolean(const string& st, const string& dr, const char* op);         //verifica validitatea op logice
string check_relational(const string& st, const string& dr);                      //verifica validitatea op de comparatie

string* check_member_access(string* objName, string* memberName, SymTable* currentScope);                            //verifica accesul la campurile unei clase
string* check_method_access(string* objName, string* methodName, vector<string>* givenArgs, SymTable* currentScope); //verifica apelurile de metode din clase

#endif