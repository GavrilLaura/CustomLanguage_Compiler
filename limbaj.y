%code requires {
    #include <string>
    #include <vector>
    #include <utility> // pt pair
    #include "AST.h"
    #include "SymTable.h"
    using namespace std;
    
}

%{
    #include <iostream>
    #include <fstream>
    #include "SymTable.h"
    extern FILE* yyin;
    extern char* yytext;
    extern int yylineno;
    extern int yylex();
    void yyerror(const char * s);
    class SymTable* current;
    int errorCount = 0;
    std::vector<ASTNode*> mainASTs; // Vectorul pentru evaluarea main-ului

    
%}

%union {
    std::string* Str;                                           // Pentru numele variabilelor si tipurile lor
    std::vector<std::pair<std::string, std::string>>* Params;   // Lista de parametri la declararea functiei <Tip, Nume>
    std::vector<std::string>* Args;                             // Lista de argumente la apelul functiei (doar Tipurile)
    std::pair<std::string, std::string>* ParamItem;             // Un singur parametru
    class ASTNode* ast;
}


%token LT GT EQ AND OR
%token BGIN END ASSIGN BR_ST BR_DR
%token PLUS MINUS TIMES DIVIDE
%token INT_LIT FLOAT_LIT BOOL_LIT STRING_LIT
%token RETURN
%token NEW
%token CLASS DOT
%token IF ELSE WHILE
%token PRINT

%token<Str> ID TYPE 

%type<ast> value expression statement statement_main
%type<Params> list_param
%type<ParamItem> param
%type<Args> call_args id_list

%start progr

%left OR
%left AND
%left LT GT EQ
%left PLUS MINUS
%left TIMES DIVIDE 
%right NOT
%left DOT

%%

// Programul principal
progr : global_declarations main {
        if (errorCount == 0) cout << "The program is correct!" << endl;
    }
    ;

// Declaratii globale pentru variabile, functii si clase
global_declarations : global_decl                   
             | class_decl        
             | global_assign     
             | global_declarations global_decl      
             | global_declarations class_decl 
             | global_declarations global_assign
             ;


global_decl : TYPE id_list ';' { 
    //declarare variabile globale
        for (const string& name : *$2) {
            string* currentName = new string(name);
            if(!current->existsId(currentName)) {
                current->addVar($1, currentName);
            } else {
                errorCount++; 
                string msg = "Variabila '" + name + "' deja definita global";
                yyerror(msg.c_str());
            }
            delete currentName;
        }
        delete $1; delete $2;
    }
    | TYPE ID ':' list_param  {
        //declarare functii
        if(current->existsFunc_local(*$2)) {
            errorCount++; 
            yyerror("Functie deja definita");
        } else {
            //construim lista de tipuri pentru SymTable
            vector<string> paramTypes;
            for(auto p : *$4) {
                paramTypes.push_back(p.first);
            }
            //adaugam functia in tabela parinte
            current->addFuncs(*$2, *$1, paramTypes);
        }

        //schimbarea domeniului pentru corpul functiei
        SymTable* newScope = new SymTable("function_" + *$2, current);
        current->addFunctionScope(*$2, newScope);
        current = newScope;

        //adaugam parametrii ca variabile locale in noul scope
        for(auto p : *$4) {
            string* t = new string(p.first);
            string* n = new string(p.second);
            current->addVar(t, n); 
            delete t; delete n;
        }
    }
    BR_ST list BR_DR {
        //revenim la domeniul parinte
        current = current->getParent();
        
        delete $1; delete $2; delete $4; 
    }
    | ID ID ';' {
        // Declarare obiect al unei clase
        if (current->isClass(*$1)) {
            current->addVar($1, $2);
        } else {
            yyerror("Clasa inexistenta");
        }
        delete $1; delete $2;
    }

    ;

id_list : ID {
            $$ = new vector<string>();
            $$->push_back(*$1);
            delete $1;
        }
        | id_list ',' ID {
            $$ = $1;
            $$->push_back(*$3);
            delete $3;
        }
        ;

//declarare clasa
class_decl : CLASS ID {
        current->addClass(*$2);
        SymTable* clScope = new SymTable(*$2, current);
        current->addClassScope(*$2, clScope);
        current = clScope;
    } 
    BR_ST class_body BR_DR {
        current = current->getParent();
        delete $2;
    }
    ;

class_body : global_decl
            | global_assign
            | class_body global_decl
            | class_body global_assign
            ;

global_assign : ID ASSIGN expression ';' {
        string* id_type = current->getType($1);
        if(id_type == nullptr){
            errorCount++;
            yyerror("Variabila din stanga nu este declarata");
        } else {
            if (*id_type != $3->dataType) {
                errorCount++;
                yyerror("Atribuire interzisa");
            }
            delete id_type;
        }
        delete $1;
    }
    ;

//gestionarea listei de parametri la definirea unei functii
list_param : { 
        //initializare vector de perechi gol
        $$ = new vector<pair<string, string>>(); 
    }
    | param { 
        $$ = new vector<pair<string, string>>();
        $$->push_back(*$1);
        delete $1;
    }
    | list_param ',' param {
        $$ = $1;
        $$->push_back(*$3);
        delete $3;
    }
    ;

param : TYPE ID {
        $$ = new std::pair<std::string, std::string>(*$1, *$2);
        delete $1; delete $2;
    }
    ;
   
//liste de instructiuni din corpul unei functii
list : statement ';'    
     | control_stmt     
     | list statement ';'
     | list control_stmt
     ;

//instructiuni din corpul functiilor
statement : ID ASSIGN expression {
        //atribuiri
        string* id = $1;
        string value_type = $3->dataType;
        string* id_type = current->getType(id);

        if(id_type == nullptr){
            errorCount++;
            yyerror("Variabila din stanga nu este declarata");
        } else {
            //Verificam daca tipurile sunt identice
            if (*id_type != value_type) {
                errorCount++;
                yyerror("Atribuire interzisa");
            }
            delete id_type;
        }
        delete id;
    }
    | RETURN expression { 
        delete $2; 
    }
    | RETURN {
    }
    | ID '(' call_args ')' {
        //apel de functie
        std::string funcName = *$1;
        std::vector<std::string>* givenArgs = $3;

        if(!current->existsFunc(*$1)) {
            errorCount++;
            std::string msg = "Functia '" + *$1 + "' nu este definita.";
            yyerror(msg.c_str());
        } else {
            std::vector<string> expectedParams = current->getFuncParams(funcName);
            if (expectedParams.size() != givenArgs->size()) {
                errorCount++;
                std::string msg = "Numar gresit de argumente. Asteptat: " + std::to_string(expectedParams.size()) + 
                                  ", Primit: " + std::to_string(givenArgs->size());
                yyerror(msg.c_str());
            } else {
                for (size_t i = 0; i < expectedParams.size(); ++i) {
                    if (expectedParams[i] != (*givenArgs)[i]) {
                        if ((*givenArgs)[i].empty()) continue; // skip daca argumentul a avut o eroare inainte
                        errorCount++;
                        std::string msg = "Tip gresit la argumentul " + std::to_string(i+1);
                        yyerror(msg.c_str());
                    }
                }
            }
        }
        delete $1; delete $3;
    }
    | ID ID {
        // Declarare obiect al unei clase
        if (current->isClass(*$1)) {
            current->addVar($1, $2);
        } else {
            yyerror("Clasa inexistenta");
        }
        delete $1; delete $2;
    }

    | ID DOT ID ASSIGN expression {
    string* memberType = check_member_access($1, $3, current);

    if (memberType != nullptr) {
        if (*memberType != $5->dataType) {
            errorCount++;
            string msg = "Tip incorect la atribuire.";
            yyerror(msg.c_str());
        }
        delete memberType;
    }
    delete $1; delete $3; 
    }
    | PRINT '(' expression ')' {
        $$ = new ASTNode(NODE_PRINT, "Print", $3->dataType, $3);
        mainASTs.push_back($$);
    }
    | TYPE id_list { 
        for (const string& name : *$2) {
            string* currentName = new string(name);
            if(!current->existsId(currentName)) {
                current->addVar($1, currentName);
            } else {
                errorCount++; 
                string msg = "Variabila '" + name + "' deja declarata local";
                yyerror(msg.c_str());
            }
            delete currentName;
        }
        delete $1; delete $2;
    }
    ;

//functia main()
main : BGIN {
        SymTable* mainScope = new SymTable("main", current);
        current->addFunctionScope("main", mainScope);
        current = mainScope;
    }
    list_main END {
        //revenim la global
        current = current->getParent();
    }
    ;

//lista de statements pentru main()
list_main : statement_main ';'
          | control_stmt_main
          | list_main statement_main ';'
          | list_main control_stmt_main
          ;

statement_main : ID ASSIGN expression {
        string* id_type = current->getType($1);
        ASTNode* idNode = nullptr;
        
        if(id_type == nullptr){
            errorCount++;
            yyerror("Variabila din stanga nu este declarata");
            idNode = new ASTNode(NODE_ID, *$1, "error");
        } else {
            if (*id_type != $3->dataType) {
                errorCount++;
                yyerror("Atribuire interzisa");
            }
            idNode = new ASTNode(NODE_ID, *$1, *id_type);
            delete id_type;
        }
        
        $$ = new ASTNode(NODE_ASSIGN, "<-", $3->dataType, idNode, $3);
        mainASTs.push_back($$);
        delete $1;
    }
    | ID '(' call_args ')' {
        //apel de functie in main
        std::string funcName = *$1;
        std::vector<std::string>* givenArgs = $3;

        if(!current->existsFunc(funcName)) {
            errorCount++; 
            std::string msg = "Functia '" + funcName + "' nu este definita";
            yyerror(msg.c_str());
            $$ = new ASTNode(NODE_OTHER, "call", "error");
        } else {
            std::vector<std::string> expectedParams = current->getFuncParams(funcName);
            if(expectedParams.size() != givenArgs->size()) {
                errorCount++;
                yyerror("Nr argumente invalid");
            } else {
                for (size_t i = 0; i < expectedParams.size(); ++i) {
                    if (expectedParams[i] != (*givenArgs)[i]) {
                        errorCount++;
                        yyerror("Tip argument invalid in expresie");
                    }
                }
            }

            $$ = new ASTNode(NODE_OTHER, "call", current->getFuncReturnType(funcName));
        }
        delete $1; delete $3;
    }
    | ID DOT ID ASSIGN expression {
        string fullName = *$1 + "." + *$3;
        string* memberType = check_member_access($1, $3, current);
        string dataType = "error"; //valoare default

        if (memberType != nullptr) {
            dataType = *memberType;
            if (dataType != $5->dataType) {
                errorCount++;
                string msg = "Tip incorect in main la atribuire.";
                yyerror(msg.c_str());
            }
            delete memberType;
        }
        ASTNode* memberNode = new ASTNode(NODE_OTHER, fullName, dataType);
        $$ = new ASTNode(NODE_ASSIGN, "<-", $5->dataType, memberNode, $5);
        mainASTs.push_back($$);
        delete $1; delete $3; 
    }
    | ID DOT ID '(' call_args ')' {
        string* t = check_method_access($1, $3, $5, current);
        if(t) { 
            $$ = new ASTNode(NODE_OTHER, "field", *t);
        }
        else $$ = new ASTNode(NODE_OTHER, "field", "error");
        delete $1; delete $3; delete $5; if(t) delete t;
    }
    | PRINT '(' expression ')' {
        $$ = new ASTNode(NODE_PRINT, "Print", $3->dataType, $3);
        mainASTs.push_back($$);
    }
    ;

//expresii
expression : NOT expression {
                if ($2->dataType != "bool") {
                    errorCount++;
                    yyerror("Operatorul '!' poate fi aplicat doar tipului bool");
                    $$ = new ASTNode(NODE_OP, "!", "error", $2);
                } else {
                    $$ = new ASTNode(NODE_OP, "!", "bool", $2);
                }
            }
            | expression PLUS expression {
                string t = check_arithmetic($1->dataType, $3->dataType, "+");
                $$ = new ASTNode(NODE_OP, "+", t, $1, $3);
            }
           | expression MINUS expression  {
                string t = check_arithmetic($1->dataType, $3->dataType, "-");
                $$ = new ASTNode(NODE_OP, "-", t, $1, $3);
            }
           | expression TIMES expression  {
                string t = check_arithmetic($1->dataType, $3->dataType, "*");
                $$ = new ASTNode(NODE_OP, "*", t, $1, $3);
            }
           | expression DIVIDE expression {
                string t = check_arithmetic($1->dataType, $3->dataType, "/");
                $$ = new ASTNode(NODE_OP, "/", t, $1, $3);
            }
           | expression AND expression    {
                string t = check_boolean($1->dataType, $3->dataType, "AND");
                $$ = new ASTNode(NODE_OP, "&&", t, $1, $3);
            }
           | expression OR expression     {
                string t = check_boolean($1->dataType, $3->dataType, "OR");
                $$ = new ASTNode(NODE_OP, "||", t, $1, $3);
            }
           | expression LT expression     {
                string t = check_relational($1->dataType, $3->dataType);
                $$ = new ASTNode(NODE_OP, "<", t, $1, $3);
            }
           | expression GT expression     {
                string t = check_relational($1->dataType, $3->dataType);
                $$ = new ASTNode(NODE_OP, ">", t, $1, $3);
            }
           | expression EQ expression     {
                string t = check_relational($1->dataType, $3->dataType);
                $$ = new ASTNode(NODE_OP, "==", t, $1, $3);
            }
           | '(' expression ')'           { $$ = $2; }
           | value                        { $$ = $1; }
           | ID '(' call_args ')' {
                //apel de functie in expresie
                std::string funcName = *$1;
                std::vector<std::string>* givenArgs = $3;

                if(!current->existsFunc(funcName)) {
                    errorCount++; 
                    std::string msg = "Functia '" + funcName + "' nu este definita";
                    yyerror(msg.c_str());
                    $$ = new ASTNode(NODE_OTHER, "call", "error");
                } else {
                    std::vector<std::string> expectedParams = current->getFuncParams(funcName);
                    if(expectedParams.size() != givenArgs->size()) {
                        errorCount++;
                        yyerror("Nr argumente invalid");
                    } else {
                        for (size_t i = 0; i < expectedParams.size(); ++i) {
                            if (expectedParams[i] != (*givenArgs)[i]) {
                                errorCount++;
                                yyerror("Tip argument invalid in expresie");
                            }
                        }
                    }

                    $$ = new ASTNode(NODE_OTHER, "call", current->getFuncReturnType(funcName));
                }
                delete $1; delete $3;
           }
           
           //acces membru
           | ID DOT ID {
            string fullName = *$1 + "." + *$3;
                string* t = check_member_access($1, $3, current);
                if(t) { 
                    $$ = new ASTNode(NODE_OTHER, fullName, *t);
                    delete t;
                }
                else $$ = new ASTNode(NODE_OTHER, fullName, "error");
                delete $1; delete $3;
           }
           
           //acces metoda
           | ID DOT ID '(' call_args ')' {
                string* t = check_method_access($1, $3, $5, current);
                if(t) { 
                    $$ = new ASTNode(NODE_OTHER, "field", *t);
                }
                else $$ = new ASTNode(NODE_OTHER, "field", "error");
                delete $1; delete $3; delete $5; if(t) delete t;
           }
           | NEW ID '('')' {
                if (!current->isClass(*$2)) {
                    yyerror("Nu se poate instantiat ceva ce nu este o clasa");
                }
                $$ = new ASTNode(NODE_OTHER, "new_" + *$2, *$2);
                delete $2;
            }
           ;

//variabile sau literali
value : ID {
        string* type = current->getType($1);
        if (type) {
            $$ = new ASTNode(NODE_ID, *$1, *type);
        } else { 
            errorCount++; 
            yyerror("Variabila nedefinita"); 
            $$ = new ASTNode(NODE_ID, *$1, "error");
        }
        delete $1; if(type) delete type;
    }
    | INT_LIT {
        $$ = new ASTNode(NODE_LIT, yytext, "int");
    }
    | FLOAT_LIT {
        $$ = new ASTNode(NODE_LIT, yytext, "float");
    }
    | STRING_LIT {
        $$ = new ASTNode(NODE_LIT, yytext, "string");
    }
    | BOOL_LIT {
        $$ = new ASTNode(NODE_LIT, yytext, "bool");
    }
    ;

//lista de argumente la apel
call_args : { 
        $$ = new vector<string>(); 
    }
    | expression {
        $$ = new vector<string>();
        $$->push_back($1->dataType); //tipul expresiei
        delete $1;
    }
    | call_args ',' expression {
        $$ = $1;
        $$->push_back($3->dataType);
        delete $3;
    }
    ;


//structuri de control if, while
list_no_decl : statement_no_decl ';'
             | control_stmt
             | list_no_decl statement_no_decl ';'
             | list_no_decl control_stmt
             ;

statement_no_decl : ID ASSIGN expression 
                  | PRINT '(' expression ')'
                  | ID '(' call_args ')'
                  | RETURN expression
                  | RETURN
                  ;

control_stmt : IF '(' expression ')' BR_ST list_no_decl BR_DR 
             | IF '(' expression ')' BR_ST list_no_decl BR_DR ELSE BR_ST list_no_decl BR_DR
             | WHILE '(' expression ')' BR_ST list_no_decl BR_DR
             ;

control_stmt_main : IF '(' expression ')' BR_ST list_main BR_DR 
                  | IF '(' expression ')' BR_ST list_main BR_DR ELSE BR_ST list_main BR_DR
                  | WHILE '(' expression ')' BR_ST list_main BR_DR
                  ;

%%

void yyerror(const char * s){
    cout << "eroare: " << s << " la linia: " << yylineno << endl;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        cout << "Utilizare: " << argv[0] << " <fisier_intrare>" << endl;
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Eroare la deschiderea fisierului");
        return 1;
    }
    current = new SymTable("global");
    yyparse();

    if (errorCount == 0) {
        cout << "\n--- Evaluare AST (Executie) ---\n";
        for (auto node : mainASTs) {
            if (node) node->evaluate(current);
        }
        ofstream file("tables.txt");
        if (file.is_open()) {
            current->printTables(file); 
            file.close();
            cout << "\nTabelele de simboluri au fost salvate in tables.txt" << endl;
        }
    } else {
        cout << "\nProgramul are erori semantice (" << errorCount << "). Verificati consola." << endl;
    }

    return 0;
}
