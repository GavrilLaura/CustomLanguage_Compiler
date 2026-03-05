#include "AST.h"
#include "SymTable.h"
#include <iostream>
#include <string>

using namespace std;

EvalValue ASTNode::evaluate(SymTable* table) {
    if (!this) return EvalValue();

    //literali
    if (nodeType == NODE_LIT) {
        return EvalValue(dataType, value);
    }

    //identificatori
    if (nodeType == NODE_ID) {
        return EvalValue(dataType, table->getVarValue(value));
    }

    //atribuire
    if (nodeType == NODE_ASSIGN || op == "<-") {
        EvalValue res = right->evaluate(table);
        table->updateVarValue(left->value, res.val);
        return res;
    }

    //print
    if (nodeType == NODE_PRINT || op == "Print") {
        EvalValue res = left->evaluate(table);
        string afisat = res.val;
        if (afisat.length() >= 2 && afisat[0] == '"' && afisat[afisat.length() - 1] == '"') {
            afisat= afisat.substr(1, afisat.length() - 2);
        }
        cout << afisat << endl;
        return res;
    }

    //noduri other
    if (nodeType == NODE_OTHER) {
        if (value.find("new_") == 0) {
            return EvalValue(dataType, "instanta_obiect"); 
        }
        //pentru obj.camp
        bool gasit = false;
        for(int i = 0; i < value.length(); i++) {
            if(value[i] == '.') {
                gasit = true;
                break;
            }
        }
        if (gasit) {
            return EvalValue(dataType, table->getVarValue(value));
        }

        if (dataType == "int") return EvalValue("int", "0");
        if (dataType == "float") return EvalValue("float", "0.0");
        if (dataType == "bool") return EvalValue("bool", "false");
        return EvalValue("string", "");
    }

    if (op == "!" && left && !right) {
        EvalValue l = left->evaluate(table);
        if (l.val == "true") return EvalValue("bool", "false");
        return EvalValue("bool", "true");
    }
    
    //operatori binari
    if (left && right) {
        EvalValue l = left->evaluate(table);
        EvalValue r = right->evaluate(table);

        if (op == "+") {
            if (dataType == "int") return EvalValue("int", to_string(std::stoi(l.val) + std::stoi(r.val)));
            return EvalValue("float", to_string(std::stof(l.val) + std::stof(r.val)));
        }
        if (op == "-") {
            if (dataType == "int") return EvalValue("int", to_string(std::stoi(l.val) - std::stoi(r.val)));
            return EvalValue("float", to_string(std::stof(l.val) - std::stof(r.val)));
        }
        if (op == "*") {
            if (dataType == "int") return EvalValue("int", to_string(std::stoi(l.val) * std::stoi(r.val)));
            return EvalValue("float", to_string(std::stof(l.val) * std::stof(r.val)));
        }
        if (op == ">") {
            if (std::stof(l.val) > std::stof(r.val)) {
                return EvalValue("bool", "true");
            } else {
                return EvalValue("bool", "false");
            }
        }
        if (op == "<") {
            if (std::stof(l.val) < std::stof(r.val)) {
                return EvalValue("bool", "true");
            } else {
                return EvalValue("bool", "false");
            }
        }
        if (op == "==") {
            if (l.val == r.val) {
                return EvalValue("bool", "true");
            } else {
                return EvalValue("bool", "false");
            }
        }
        if (op == "&&" ) {
            if (l.val == "true" && r.val == "true") {
                return EvalValue("bool", "true");
            } else {
                return EvalValue("bool", "false");
            }
        }
        if (op == "||" ) {
            if (l.val == "true" || r.val == "true") {
                return EvalValue("bool", "true");
            } else {
                return EvalValue("bool", "false");
            }
        }
    }

    return EvalValue("void", ""); //default
}