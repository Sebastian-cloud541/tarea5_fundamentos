* ============================================================
* A5 — Limpieza y descriptivos de CASEN
* Autor: Sebastián Navarrete      Fecha: 17-11-2026
* Curso: Fundamentos de Programación para Análisis Económico · UdeC-EAN
* Propósito: limpiar casen_reducido.csv, crear variables y describirlas
* ============================================================

version 16            
clear all             // empezar sin datos ni resultados previos
set more off          
capture mkdir "output"            // crea output
capture log close                 // cierra un log que haya quedado abierto
log using "output/tarea_a5.log", replace text

* Comprobar que Stata ve el archivo 
confirm file "data/raw/casen_reducido.csv" 
* Si no funciona usar cd


* 1. Cargar los datos
* encoding("utf-8"): para que "Construcción" y "Ñuble" se lean bien.
import delimited "data/raw/casen_reducido.csv", clear varnames(1) encoding("utf-8")

describe              // estructura de la base 
summarize             // primer vistazo: ingreso tiene Obs 55, no 60
list in 1/5



* 2. Crear variables con generate y replace
* Experiencia potencial de Mincer: años desde que la persona dejó de estudiar.
generate experiencia = edad - educ - 6
replace  experiencia = 0 if experiencia < 0     // nadie tiene experiencia negativa


* Indicadora de mujer
generate mujer = (genero == "F")

* Indicadora de educación alta (13 años o más). 
generate alta_educ = (educ >= 13) if !missing(educ)

* Indicadora de pobreza: si ingreso falta, pobre queda sin dato (no "no pobre").
generate pobre = (ingreso < 216000) if !missing(ingreso)   



* 3. Etiquetas (variables y valores)
label variable ingreso     "Ingreso mensual ($)"
label variable experiencia "Experiencia potencial (años)"
label variable mujer       "Mujer (1 = sí)"
label variable alta_educ   "Educación alta: 13+ años (1 = sí)"
label variable pobre       "Ingreso bajo el umbral de pobreza (1 = sí)"

label define mujer_lbl 0 "Hombre" 1 "Mujer"
label values mujer mujer_lbl

label define alta_lbl 0 "Menos de 13 años" 1 "13 años o más"
label values alta_educ alta_lbl

label define sino 0 "No pobre" 1 "Pobre"
label values pobre sino

* Categórica a partir de texto
encode sector, generate(sector_n)

* Agrupar educación en niveles
recode educ (0/8 = 1 "Básica") (9/12 = 2 "Media") (13/max = 3 "Superior"), ///
    generate(nivel_educ)
label variable nivel_educ "Nivel educacional"

label list



* 4. Cuidado con los missing
count if missing(ingreso)                         // 5 personas sin ingreso

count if ingreso > 500000                         // MAL: cuenta 46
count if ingreso > 500000 & !missing(ingreso)     // BIEN: cuenta 41

* ¿Por qué summarize ingreso no se equivoca con los missing, pero
* count if ingreso > 500000 sí puede equivocarse?
* - summarize calcula sus estadísticas solo con los valores observados:
* deja fuera los missing por sí solo (por eso muestra Obs 55, no 60).
* - count if ingreso > 500000 evalúa una COMPARACIÓN, y para Stata el
* missing (.) es un número más grande que cualquier otro. Entonces
* ". > 500000" es VERDADERO y las 5 personas sin ingreso se cuentan
* como si tuvieran ingresos altos (46 en vez de 41).





* 5. Descriptivos
* Variables numéricas
summarize ingreso educ edad experiencia

* Frecuencias de una categórica
tabulate sector
tabulate sector_n, nolabel        

* Tabla cruzada con % por fila
tabulate alta_educ mujer, row
tabulate mujer pobre, row         

* Ingreso por grupo con summarize ... if
summarize ingreso if alta_educ == 0
summarize ingreso if alta_educ == 1

* Lo mismo para todos los grupos de una vez
tabstat ingreso, by(sector) stat(mean sd n)
tabstat ingreso, by(nivel_educ) stat(mean n)

* Correlación (usa solo las filas completas en las tres variables: obs = 55)
correlate ingreso educ experiencia

* Guardar resultados con scalar ANTES de que r() se sobrescriba
summarize ingreso
scalar media_ing = r(mean)
display "Ingreso medio de la muestra: " %9.0fc media_ing

summarize ingreso if alta_educ == 1
scalar media_alta = r(mean)
summarize ingreso if alta_educ == 0
scalar media_baja = r(mean)
display "Diferencia de ingreso medio (13+ años menos <13 años): " %9.0fc media_alta - media_baja

scalar list media_ing media_alta media_baja



* 6. Cerrar la bitácora
log close



* 7. Interpretación
* De 60 personas, 55 reportan ingreso; su ingreso medio es $655.291 al mes
* (entre $180.000 y $1.093.000), con 12,7 años de educación y 25,8 años de
* experiencia potencial en promedio. Quienes tienen 13 o más años de estudio
* ganan en promedio $777.926, unos $240.890 más que quienes tienen menos
* ($537.036). El ingreso se asocia positivamente con la educación (r = 0,68)
* y casi nada con la experiencia (r = -0,09).