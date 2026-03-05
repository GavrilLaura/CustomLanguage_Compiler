# Proiect Compilator - Limbaj Personalizat

Acest proiect reprezintă implementarea unui compilator/interpretator pentru un limbaj de programare personalizat, utilizând instrumentele **Flex** (analiză lexicală) și **Bison** (analiză sintactică), împreună cu limbajul **C++**.

## Funcționalități
* **Analiză Lexicală:** Identificarea token-ilor (cuvinte cheie, identificatori, operatori).
* **Analiză Sintactică:** Verificarea structurii gramaticale.
* **Tabelă de Simboluri (SymTable):** Gestionarea variabilelor și a tipurilor de date.
* **Arbore Sintactic Abstract (AST):** Reprezentarea ierarhică a instrucțiunilor pentru evaluare.
* **Gestionarea erorilor:** Detectarea și raportarea erorilor de sintaxă sau semantică.

## Structura Fișierelor
* `limbaj.l` - Definirea regulilor lexicale (Flex).
* `limbaj.y` - Definirea gramaticii și a regulilor de reducere (Bison).
* `AST.cpp` / `AST.h` - Implementarea nodurilor pentru arborele sintactic.
* `SymTable.cpp` / `SymTable.h` - Logica pentru stocarea și validarea identificatorilor.
* `compile` - Script de automatizare pentru procesul de build.

## Instalare și Rulare

### Precerințe
Asigură-te că ai instalate următoarele utilitare:
* `flex`
* `bison`
* `g++`

### Compilare
Pentru a genera executabilul, rulează scriptul de compilare inclus:
```bash
chmod +x compile
./compile

(Acest proiect a fost realizat împreună cu Todireanu Laura-Maria)
