%option noyywrap
%option nounput
/* MedidorMetrica.l                                                                                 */
/* Programa que, mediante flex++, separa oraciones (versos) escritos en español y contabiliza       */
/* sus sílabas métricas. Tras terminar con los versos del archivo de entrada, da un resumen sobre   */
/* el tipo de versos que contiene el archivo.                                                       */
/* Realizado por Javier Rodríguez Rodríguez para Modelos de Computación A2 GII-UGR 2019/2020        */
%{           /* Declaraciones */ 
    #include <iostream>
    #include <fstream>
    #include <vector>
    #include <iomanip>

    std::ifstream archivo_texto;
    
    std::vector<std::string> silabas_palabra;
    std::vector<unsigned> conteo_metrica;
    bool nueva_palabra = false;
    unsigned nro_silabas = 0;
    std::string palabra;

    void palabraPorSilabas(const char * silaba);
    unsigned ultimaPalabra();
    void finDeVerso();
%}

DELIMITADORES   [\t\0 ,.;:!?]

/* Flex++ no reconoce caracteres Unicode, como lo son las vocales acentuadas, pero acepta parámetros binarios con tal de que venga definido en 8 bits.            */
/* Por tanto, se especifican dichos caracteres a partir de su código hexadecimal asociado en la tabla Unicode. El prefijo \x especifica parámetros en hexadecimal */
/* En orden de aparición: ÁÉÍÓÚáéíóúÏÜïü (en vocales abiertas), Ññ (en consonantes)                                                                               */
VOCAL_ABIERTA	[AEOaeo]|\xc3[\x81\x89\x8d\x93\x9a\xa1\xa9\xad\xb3\xba\x8f\x9c\xaf\xbc]
VOCAL_CERRADA	[IUiu]
VOCAL			({VOCAL_ABIERTA}|{VOCAL_CERRADA})
DIPTONGO        ([Hh]?{VOCAL}({VOCAL_CERRADA}|[Yy])|[Hh]?{VOCAL_CERRADA}{VOCAL})+
SINALEFA        ({DIPTONGO}|[AEIOUYaeiouy])({DELIMITADORES}[Hh]?({DIPTONGO}|[AEIOUaeiou]|[Yy]{DELIMITADORES})+)+

CONSONANTE	    [BCDFGHJKLMNPQRSTVWXZbcdfghjklmnpqrstvwxz]|\xc3[\x91\xb1]

C_SIN_AGGS      [HJMNQVWXZhjmnqvwxz]|\xc3[\x91\xb1]

C_SIN_L_R_H     [BCDFGJKMNPQSTVWXZbcdfgjkmnpqstvwxz]|\xc3[\x91\xb1]
C_SIN_L_R       [BCDFGHJKMNPQSTVWXZbcdfghjkmnpqstvwxz]|\xc3[\x91\xb1]
C_SIN_R         [BCDFGHJKLMNPQSTVWXZbcdfghjklmnpqstvwxz]|\xc3[\x91\xb1]
C_SIN_L         [BCDFGHJKMNPQRSTVWXZbcdfghjkmnpqrstvwxz]|\xc3[\x91\xb1]
C_SIN_H         [BCDFGJKLMNPQRSTVWXZbcdfgjklmnpqrstvwxz]|\xc3[\x91\xb1]

AGG_COMUN       [BFGKPTbfgkpt]

AGG_ATAQUE      ({AGG_COMUN}|[CLcl])[Ll]|[CScs][Hh]|({AGG_COMUN}|[CDRcdr])[Rr]

ATAQUE          {AGG_ATAQUE}|{CONSONANTE}|[Yy]
NUCLEO          {VOCAL}|{DIPTONGO}|{SINALEFA}|[Yy]

/* Estructura ATAQUE-NÚCLEO-CODA. Ataque y Núcleo están contenidos en la expresión SILABA, pero */
/* dado que la coda requiere del operador /, el cual no se puede encapsular en paréntesis (y por tanto en un alias), se define directamente las reglas que requiere     */
SILABA          {ATAQUE}?{NUCLEO}



/* REGLA 1: Coda para consonante cualquiera excepto aquellas que preceden una agregación.   */
/* REGLA 2: Coda para C (excluye H, L, R)                                                   */
/* REGLA 3: Coda para D y R (excluye R)                                                     */
/* REGLA 4: Coda para L (excluye L)                                                         */                              
/* REGLA 5: Coda para S (excluye H)                                                         */
/* REGLA 6: Coda para B, F, G, K, P, T (excluye L, R)                                       */
/* REGLA 7: Coda vacía                                                                      */
/* REGLA 8: Coda seguida de S (solo dentro de una palabra)                                  */
/* REGLA 9: Coda de múltiples consonantes (solo al final de palabra)                        */
/* REGLA 10: Separación entre palabras de un mismo verso                                    */
/* REGLA 11: Salto de línea. Separación entre versos. Solo actúa ante versos no vacíos      */
/* REGLA 12: Regla por defecto. Sobreescribe ECHO                                           */
%%          /* Reglas */


{SILABA}{C_SIN_AGGS}/({DELIMITADORES}|{CONSONANTE}|\n)	    { palabraPorSilabas(YYText()); }

{SILABA}[Cc]/({DELIMITADORES}|{C_SIN_L_R_H}|\n)             { palabraPorSilabas(YYText()); }

{SILABA}[DRdr]/({DELIMITADORES}|{C_SIN_R}|\n)               { palabraPorSilabas(YYText()); }

{SILABA}[Ll]/({DELIMITADORES}|{C_SIN_L}|\n)                 { palabraPorSilabas(YYText()); }

{SILABA}[Ss]/({DELIMITADORES}|{C_SIN_H}|\n)                 { palabraPorSilabas(YYText()); }

{SILABA}{AGG_COMUN}/({DELIMITADORES}|{C_SIN_L_R}|\n)        { palabraPorSilabas(YYText()); }

{SILABA}                                                    { palabraPorSilabas(YYText()); }

{SILABA}{CONSONANTE}[Ss]/{CONSONANTE}       	            { palabraPorSilabas(YYText()); }

{SILABA}{CONSONANTE}+/({DELIMITADORES}|\n)                  { palabraPorSilabas(YYText()); }

{DELIMITADORES}+                                            { nueva_palabra = true; }

\n                                                          { finDeVerso(); }

.                                                           {}

%%          /* Procedimientos */

int main (int argc, char *argv[]) {
    if (argc == 2) {
        archivo_texto.open(argv[1]);
        if (archivo_texto.bad()) {
            std::cout << "Error en lectura de archivo" << std::endl;
            exit(1);
        }
    } else {
        std::cout << "Parámetros incorrectos. Introduzca solamente el nombre del archivo de entrada" << std::endl;
        exit(1);
    }

    yyFlexLexer flujo (&archivo_texto, 0);
    flujo.yylex();
    bool arte_menor = false;
    bool arte_mayor = false;
    bool igual_metrica = true;
    unsigned ultima_metrica = conteo_metrica.front();
    for (std::size_t i = 0; i < conteo_metrica.size(); i++) {
        if (conteo_metrica[i] > 8 && !arte_mayor) {
            arte_mayor = true;
        }
        if (conteo_metrica[i] <= 8 && !arte_menor) {
            arte_menor = true;
        }
        if ((conteo_metrica[i] != ultima_metrica) && igual_metrica) {
            igual_metrica = false;
        }
        ultima_metrica = conteo_metrica[i];
    }

    std::cout << std::endl;
    if (arte_mayor && arte_menor) {
        std::cout << "El poema contiene tanto versos de arte mayor como versos de arte menor." << std::endl;
    } else if (arte_mayor) {
        std::cout << "El poema contiene solamente versos de arte mayor." << std::endl;
    } else if (arte_menor) {
        std::cout << "El poema contiene solamente versos de arte menor." << std::endl;
    }
    if (igual_metrica) {
        std::cout << "En específico, todos sus versos son de " << ultima_metrica << " sílabas" << std::endl;
    }

	return 0;
}

void palabraPorSilabas(const char * silaba) {
    if (nueva_palabra) {
        nueva_palabra = false;
        silabas_palabra.clear();
    }
    silabas_palabra.push_back(silaba);
    palabra += silaba;
    palabra += "/";
    nro_silabas++;
}

unsigned ultimaPalabra() {
    std::string silaba;
    std::size_t posicion;
    int silaba_tonica = -1;
    for (std::size_t i = 0; i < silabas_palabra.size(); i++) {
        silaba = silabas_palabra[i];
        posicion = silaba.find_first_of("áéíóúÁÉÍÓÚ");
        if (posicion != std::string::npos) {
            silaba_tonica = silabas_palabra.size() - i - 1;
            break;
        }
    }

    std::string ultima_silaba = silabas_palabra.back();
    std::string ultima_letra(1, ultima_silaba.back());

    if (silabas_palabra.size() == 1) {
        silaba_tonica = 0;
    }

    std::string metrica_verso = std::to_string(nro_silabas);

    switch (silaba_tonica) {
        case -1 : 
            posicion = ultima_letra.find_first_of("aeiounsAEIOUNS");
            if (posicion == std::string::npos) {
                //std::cout << "AGUDA";
                metrica_verso += " + 1";
                nro_silabas++;
            } else 
                metrica_verso += " + 0";
            break;
        case 0:
            nro_silabas++;
            //std::cout << "AGUDA";
            metrica_verso += " + 1";
            break;
        case 1:
            //std::cout << "GRAVE";
            metrica_verso += " + 0";
            break;
        default:
            //std::cout << "ESDRUJULA";
            metrica_verso += " - 1";
            nro_silabas--;
            break;
    }
    metrica_verso += " = ";
    metrica_verso += std::to_string(nro_silabas);
    std::cout << std::left << std::setw(50) << palabra  << "\tNúmero de sílabas métricas: " << metrica_verso << std::endl;
    unsigned medicion = nro_silabas;
    nro_silabas = 0;
    palabra.clear();
    return medicion;
}

void finDeVerso() {
    if (nro_silabas != 0) {
        conteo_metrica.push_back(ultimaPalabra()); 
    } else {
        std::cout << std::endl;
    }
}