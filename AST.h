#ifndef AST_H
#define AST_H

#include <string>
#include <iostream>
#include <vector>
#include "SymTable.h"

//evaluator pentru valorile arborilor AST
struct EvalValue {
    std::string type;
    std::string val;

    EvalValue() : type("void"), val("") {}
    EvalValue(std::string t, std::string v) : type(t), val(v) {}

};

enum NodeType { NODE_OP, NODE_LIT, NODE_ID, NODE_OTHER, NODE_ASSIGN, NODE_PRINT };

class ASTNode {
public:
    NodeType nodeType;
    std::string op;         
    std::string value;      
    std::string dataType;
    ASTNode *left, *right;

    ASTNode(NodeType nt, std::string v, std::string dt, ASTNode* l = nullptr, ASTNode* r = nullptr)
        : nodeType(nt), value(v), op(v), dataType(dt), left(l), right(r) {}

    EvalValue evaluate(class SymTable* table);
};

#endif