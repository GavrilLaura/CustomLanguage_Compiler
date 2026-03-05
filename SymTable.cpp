#include "SymTable.h"
#include <fstream>
#include <iomanip>
using namespace std;

extern int errorCount;
extern void yyerror(const char * s);

SymTable::SymTable(string scopeName, SymTable* parent) 
    : scopeName(scopeName), parent(parent) {
}

IdInfo::IdInfo(string* type, string* name, string* value) {
    if (type) this->type = *type;
    if (name) this->name = *name;
    if (value) this->value = *value;
    else this->value = "undefined"; 
}

SymTable* SymTable::getParent() {
    return this->parent;
}

SymTable* SymTable::getClassScope(string className) {
    if (classScopes.find(className) != classScopes.end()) {
        return classScopes[className];
    }
    if (parent != nullptr) {
        return parent->getClassScope(className);
    }
    return nullptr;
}

bool SymTable::existsId(string* s) {
    return ids.find(*s) != ids.end(); //verifica existenta doar in scopeul curent
}

void SymTable::addVar(string* type, string*name) {
    string defaultVal = "0"; 
    if (*type == "float") defaultVal = "0.0";
    if (*type == "bool") defaultVal = "false";
    if (*type == "string") defaultVal = "";
    IdInfo var(type, name, &defaultVal);
    ids[*name] = var; 
}

string* SymTable::getType(string* id) {
    //cautam in domeniul curent
    if (ids.find(*id) != ids.end()) {
        return new string(ids[*id].type);
    }
    
    //daca nu am gasit si avem parinte, cautam in parinte
    if (parent != nullptr) {
        return parent->getType(id);
    }

    //nu exista nicaieri
    return nullptr;
}

string SymTable::getFuncReturnType(string name) {
    if (funcs.find(name) != funcs.end()) {
        return funcs[name].returnType;
    }
    if (parent != nullptr) {
        return parent->getFuncReturnType(name);
    }
    return ""; //pt functie nedefinita
}

void SymTable::addFuncs(string name, string returnType, vector<string> params) {
    funcs[name] = FuncInfo(returnType, params);
}

bool SymTable::existsFunc(string name) {
    if (funcs.find(name) != funcs.end()) return true;
    if (parent != nullptr) return parent->existsFunc(name);
    return false;
}

bool SymTable::existsFunc_local(string name) {
    if (funcs.find(name) != funcs.end()) return true;
    return false;
}

/*
void SymTable::printVars() {
    cout << "Domeniu: " << scopeName << endl;
    for (const pair<string, IdInfo>& v : ids) {
        cout << "  Var: " << v.first << " Type: " << v.second.type << endl; 
    }
}
*/

void SymTable::printTables(ofstream& file) {
    file << "DOMENIU: " << scopeName << endl;
    file << "PARINTE: ";
    if (parent != nullptr) {
        file << parent->scopeName;
    } else {
        file << "Niciunul (Global)";
    }
    file << endl;
    file << "VARIABILE: " << endl;
    if (ids.empty()) file << "nu exista variabile definite" << endl;
    for (auto const& [name, info] : ids) {
        file << "  Nume: " << name << endl
             << "  Tip: " << info.type << endl
             << "  Valoare: " << info.value << endl
             << "---------------------" << endl;
    }

    file << "FUNCTII: " << endl;
    if (funcs.empty()) file << "nu exista functii definite" << endl;
    for (auto const& [name, info] : funcs) {
        file << "  " << info.returnType << " " << name << "(";
        for (size_t i = 0; i < info.paramTypes.size(); ++i) {
            file << info.paramTypes[i];
            if(i < info.paramTypes.size() - 1) file << ", ";
            else file << "";
        }
        file << ")" << endl;
    }

    file << endl;

    for (auto const& [name, scope] : classScopes) {
        file << "*********************" << endl;
        file << "=====================" << endl;
        file << "*********************" << endl;
        file << endl;
        scope->printTables(file);
    }

    for (auto const& [name, scope] : functionScopes) {
        file << "*********************" << endl;
        file << "=====================" << endl;
        file << "*********************" << endl;
        file << endl;
        scope->printTables(file);
    }
}

vector<string> SymTable::getFuncParams(string name) {
    if (funcs.find(name) != funcs.end()) {
        return funcs[name].paramTypes;
    }
    if (parent != nullptr) {
        return parent->getFuncParams(name);
    }
    return vector<string>(); //returneaza vector gol daca nu exista functia
}

void SymTable::addClass(string name) {
        classNames.push_back(name);
    }

void SymTable::addClassScope(string name, SymTable* scope) {
    classScopes[name] = scope;
}

void SymTable::addFunctionScope(string name, SymTable* scope) {
    functionScopes[name] = scope;
}

bool SymTable::isClass(string name) {
        for(auto &n : classNames) {
            if(n == name) return true;
        }
        if (parent != nullptr) {
        return parent->isClass(name);
        }
        return false;
    }

SymTable::~SymTable() {
    //stergem tabelele copil pt a evita scurgeri de memorie
    for (auto& pair : classScopes) {
        delete pair.second;
    }
    ids.clear();
    funcs.clear();
    classNames.clear();
}

string SymTable::getVarValue(string name) {
    //pentru obj.camp
    int dotIdx = -1;
    for (int i = 0; i < (int)name.length(); i++) {
        if (name[i] == '.') {
            dotIdx = i;
            break;
        }
    }
    if (dotIdx != -1) {
        string objName = "";
        string fieldName = "";
        for (int i = 0; i < dotIdx; i++) {
            objName += name[i];
        }
        for (int i = dotIdx + 1; i < (int)name.length(); i++) {
            fieldName += name[i];
        }
        string* objType = this->getType(&objName);
        if (objType) {
            SymTable* cScope = this->getClassScope(*objType);
            delete objType;
            if (cScope) {
                return cScope->getVarValue(fieldName);
            }
        }
        return "0"; 
    }

   
    if (ids.count(name)) {
        return ids[name].value;
    }
    if (parent) {
        return parent->getVarValue(name);
    }

    return "0";
}

void SymTable::updateVarValue(string name, string val) {
    int dotIdx = -1;

    for (int i = 0; i < (int)name.length(); i++) {
        if (name[i] == '.') {
            dotIdx = i;
            break;
        }
    }

    if (dotIdx != -1) {
        string objName = "";
        string fieldName = "";

        for (int i = 0; i < dotIdx; i++) {
            objName += name[i];
        }

        for (int i = dotIdx + 1; i < (int)name.length(); i++) {
            fieldName += name[i];
        }

        string* objType = this->getType(&objName);
        if (objType) {
            SymTable* cScope = this->getClassScope(*objType);
            delete objType;
            if (cScope) {
                cScope->updateVarValue(fieldName, val);
                return;
            }
        }
    }

    if (ids.count(name)) {
        ids[name].value = val;
    } 
    else if (parent) {
        parent->updateVarValue(name, val);
    }
}

string check_arithmetic(const string& st, const string& dr, const char* op) {
    if (st == dr && (st == "int" || st == "float")) return st;
    errorCount++;
    return "";
}

string check_boolean(const string& st, const string& dr, const char* op) {
    if (st == "bool" && dr == "bool") return "bool";
    errorCount++;
    return "";
}

string check_relational(const string& st, const string& dr) {
    if (st == dr && (st == "int" || st == "float" || st == "bool")) return "bool";
    errorCount++;
    return "";
}

string* check_member_access(string* objName, string* memberName, SymTable* currentScope) {
    string* className = currentScope->getType(objName);
    if (className == nullptr) {
        errorCount++;
        yyerror(("Obiectul '" + *objName + "' nu este declarat.").c_str());
        return nullptr;
    }

    SymTable* cScope = currentScope->getClassScope(*className);
    if (cScope == nullptr) {
        errorCount++;
        yyerror(("Tipul '" + *className + "' nu este o clasa.").c_str());
        return nullptr;
    }

    string* memberType = cScope->getType(memberName);
    if (memberType == nullptr) {
        errorCount++;
        yyerror(("Membrul '" + *memberName + "' nu exista in clasa '" + *className + "'.").c_str());
        return nullptr;
    }

    return memberType;
}

string* check_method_access(string* objName, string* methodName, vector<string>* givenArgs, SymTable* currentScope) {
    string* className = currentScope->getType(objName);
    if (className == nullptr) {
        errorCount++;
        yyerror(("Obiectul '" + *objName + "' nu este declarat.").c_str());
        return new string("error");
    }

    SymTable* cScope = currentScope->getClassScope(*className);
    if (cScope == nullptr) {
        errorCount++;
        yyerror(("Tipul '" + *className + "' nu este o clasa.").c_str());
        return new string("error");
    }

    if (!cScope->existsFunc(*methodName)) {
        errorCount++;
        yyerror(("Metoda '" + *methodName + "' nu exista in clasa '" + *className + "'.").c_str());
        return new string("error");
    }

    vector<string> expectedParams = cScope->getFuncParams(*methodName);
    if (expectedParams.size() != givenArgs->size()) {
        errorCount++;
        yyerror(("Numar incorect de argumente pentru metoda '" + *methodName + "'.").c_str());
    } else {
        for (size_t i = 0; i < expectedParams.size(); ++i) {
            if (expectedParams[i] != (*givenArgs)[i]) {
                errorCount++;
                yyerror(("Tip gresit pentru argumentul " + std::to_string(i+1) + " la apelul metodei '" + *methodName + "'.").c_str());
            }
        }
    }

    return new string(cScope->getFuncReturnType(*methodName));
}







