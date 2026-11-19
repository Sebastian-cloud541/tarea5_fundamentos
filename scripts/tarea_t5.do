* ============================================================
* T5 — Do-file automatizado: CASEN
* Autor: Sebastián Navarrete      Fecha: 19-11-2026
* Curso: Fundamentos de Programación para Análisis Económico · UdeC-EAN
* Propósito: la A5 automatizada con macros, loops, un programa, modelos
*            guardados y resultados exportados a Excel.
* ============================================================
* Antes de correr: Stata debe estar en la carpeta del proyecto (pwd / cd).
* Este do-file se corre COMPLETO de una vez: las macros locales mueren
* cuando termina la ejecución, así que no sirve correrlo por partes.
* ============================================================

version 14            
clear all             // empezar sin datos
set more off
capture mkdir "output"
capture log close
log using "output/tarea_t5.log", replace text



* 1. PARÁMETROS (lo único que se edita)
* local: viven solo mientras corre este do-file.
local datos      "data/raw/casen_reducido.csv"
local depvar     "ingreso"                         // variable dependiente
local xprin      "educ"                            // regresor principal 
local controles  "experiencia"                     // controles adicionales
local numericas  "ingreso educ edad experiencia"   // variables para los descriptivos
local grupos     "sector region genero"            // grupos para el programa de descriptivos
local grupo_reg  "sector"                          // grupo para las regresiones por separado
local var_tramos "educ"                            // variable que se corta en tramos
local t_ini      = 4                               // primer tramo
local t_paso     = 4                               // ancho de cada tramo
local t_fin      = 20                              // último tramo
local excel      "output/tarea_t5_por_sector.xlsx"

* --- global: viven en toda la sesión de Stata. Las uso solo para lo que
*     quisiera compartir con otros do-files del proyecto (el umbral de
*     ingreso y la fuente de los datos son los mismos en todo el análisis).
global umbral = 500000
global fuente "CASEN, muestra del curso (60 personas)"


* 2. CARGAR Y PREPARAR LOS DATOS
import delimited "`datos'", clear varnames(1) encoding("utf-8")
describe, short

* Experiencia potencial de Mincer 
generate experiencia = max(edad - educ - 6, 0)
label variable experiencia "Experiencia potencial (años)"

* Indicadora 0/1 de sexo con etiquetas de valores.
generate mujer = (genero == "F")
label variable mujer "Mujer (1 = sí)"
label define mujer_lbl 0 "Hombre" 1 "Mujer"
label values mujer mujer_lbl

label variable ingreso "Ingreso mensual ($)"
label variable educ    "Años de educación"

tabulate mujer



* 3. foreach SOBRE UNA LISTA DE VARIABLES
* Reemplaza los summarize repetidos
foreach v of local numericas {
    display _newline "===== `v' ====="
    summarize `v', detail
}



* 4. forvalues: CUÁNTAS PERSONAS HAY EN CADA TRAMO
* Tramos de educación de 4 años: ¿cuántas personas tienen educación
* básica incompleta, media, superior...? count deja el número en r(N).
forvalues t = `t_ini'(`t_paso')`t_fin' {
    quietly count if `var_tramos' >= `t' & `var_tramos' < `t' + `t_paso'
    display "`var_tramos' de `t' a " `t' + `t_paso' - 1 ": " r(N) " personas"
}



* 5. UN PROGRAMA REUTILIZABLE CON ARGUMENTOS
* descriptivos_grupo  grupo  var1  var2
*   `1' = variable de grupo; `2' y `3' = variables que se describen.
* Las variables se pasan como argumentos y no se leen de las macros del
* do-file: dentro de un programa las locales de afuera no existen y se
* evalúan como vacías, sin dar error.
capture program drop descriptivos_grupo
program define descriptivos_grupo
    display _newline "=== Descriptivos por `1' ==="
    tabulate `1'
    tabstat `2' `3', by(`1') statistics(mean sd n)
end

* Un solo bloque sirve para todos los grupos de la lista.
foreach g of local grupos {
    descriptivos_grupo `g' `depvar' `xprin'
}



* 6. tempvar: UNA VARIABLE INTERMEDIA QUE NO QUEDA EN LOS DATOS
tempvar dep_miles
generate `dep_miles' = `depvar' / 1000
summarize `dep_miles'
display "Media de `depvar' en miles: " %9.1fc r(mean)

/*
   ¿Por qué tempvar es más seguro que crear una variable y borrarla?
   - Stata le da un nombre único (tipo __000000), así que nunca choca con una
     variable que ya existe en la base: un generate ingreso_miles fallaría
     si ingreso_miles ya estuviera.
   - Se borra sola al terminar el do-file, aunque se corte a
     la mitad por un error.
*/



* 7. MISSING AL FILTRAR POR EL UMBRAL

count if missing(`depvar')

count if `depvar' > $umbral                        // MAL: incluye a los missing
count if `depvar' > $umbral & !missing(`depvar')   // BIEN

/*
   Sin & !missing(ingreso), las 5 personas sin ingreso se contarían como si
   ganaran más que el umbral. Con el umbral de
   500000 el primer count da 46 y el correcto 41.
*/


* 8. MODELOS GUARDADOS Y COMPARADOS

quietly regress `depvar' `xprin' `controles'
estimates store m1

quietly regress `depvar' `xprin' `controles' i.mujer
estimates store m2

estimates dir
estimates table m1 m2, b(%9.0f) se stats(N r2) stfmt(%5.3f)

* El coeficiente se lee de e().
estimates restore m1
display "m1: cada año de `xprin' se asocia a " %9.0fc _b[`xprin'] ///
    " pesos más de `depvar' (ee = " %7.0fc _se[`xprin'] ", N = " e(N) ")"

estimates restore m2
display "m2: cada año de `xprin' se asocia a " %9.0fc _b[`xprin'] ///
    " pesos más de `depvar' (ee = " %7.0fc _se[`xprin'] ", N = " e(N) ")"
display "m2: brecha mujer - hombre = " %9.0fc _b[1.mujer] ///
    " pesos (ee = " %7.0fc _se[1.mujer] ")"



* 9. UNA REGRESIÓN POR GRUPO, EN UNA MATRIZ, EXPORTADA A EXCEL

levelsof `grupo_reg', local(niveles)
local k : word count `niveles'          // cuántos grupos hay
matrix R = J(`k', 3, .)                 // k filas, 3 columnas, todo missing

local i = 1
foreach s of local niveles {
    quietly regress `depvar' `xprin' if `grupo_reg' == "`s'"
    matrix R[`i', 1] = _b[`xprin']      // coeficiente
    matrix R[`i', 2] = _se[`xprin']     // error estándar
    matrix R[`i', 3] = e(N)             // cuántas personas
    local i = `i' + 1
}

matrix colnames R = beta_`xprin' ee n
matrix rownames R = `niveles'
matrix list R, format(%9.0f)

* A Excel: encabezados, la matriz desde B2 y los nombres en la columna A.
putexcel set "`excel'", replace
putexcel A1 = ("`grupo_reg'") B1 = ("Beta `xprin'") C1 = ("Error est.") D1 = ("n")
putexcel B2 = matrix(R)

local fila = 2
foreach s of local niveles {
    putexcel A`fila' = ("`s'")
    local fila = `fila' + 1
}
local fila = `fila' + 1                 // una fila en blanco antes de la nota
putexcel A`fila' = ("Fuente: $fuente. Regresión de `depvar' en `xprin' por `grupo_reg'.")



* 10. CERRAR LA BITÁCORA

log close



* INTERPRETACIÓN 

* En m1, cada año adicional de educación se asocia a unos $42019 más de
* ingreso mensual, con la experiencia fija (N = 55, R2 = 0,458). Al agregar
* el sexo (m2) el coeficiente casi no cambia ($42246) y el R2 sube poco
* (0,475); las mujeres ganan en promedio $55686 menos que los hombres con
* igual educación y experiencia, pero esa brecha no es estadísticamente
* distinta de cero (ee = $43302). Por sector el coeficiente va de $23783
* (Construcción) a $42.713 (Industria), pero con solo 5 a 15 personas por
* sector esas estimaciones son muy imprecisas. Limitación: son 60 personas
* y 5 sin ingreso, y faltan variables (habilidad, horas trabajadas), así que
* son asociaciones, no efectos causales de la educación.
