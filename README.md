# Stata · CASEN — Fundamentos de Programación para Análisis Económico

**UdeC-EAN · Módulo IV (Semanas 12 y 13)**
Autor: Sebastián Navarrete Poblete

---

## Estructura del repositorio

```
.
├── data/
│   └── raw/
│       └── casen_reducido.csv          # datos de entrada (60 personas, 6 variables)
├── scripts/
│   ├── tarea_a5.do                     # A5 (S12): limpieza y descriptivos "a mano"
│   └── tarea_t5.do                     # T5 (S13): el mismo análisis, automatizado
├── output/
│   ├── tarea_a5.log
│   ├── tarea_t5.log
│   └── tarea_t5_por_sector.xlsx        # regresión por sector exportada con putexcel
└── README.md
```

## Cómo correr los do-files

1. Clonar o descargar este repositorio.
2. Abrir Stata (versión 14 o superior) y pararse en la carpeta raíz del repositorio:
   ```stata
   cd "ruta/a/este/repositorio"
   pwd
   ```
3. Correr el do-file **completo** (no por partes: las macros locales se pierden):
   ```stata
   do "scripts/tarea_t5.do"
   ```
4. Los resultados quedan en `output/`.

Los do-files usan rutas relativas, así que funcionan en cualquier computador si
Stata está en la carpeta raíz del repositorio.

---

## A5 — Limpieza y descriptivos (Semana 12)

Do-file escrito «a mano»: carga `casen_reducido.csv`, crea `experiencia` (Mincer),
`mujer`, `alta_educ` y `pobre`, etiqueta variables y valores, explica el *gotcha*
de los missing en Stata y produce `summarize`, `tabulate`, `tabstat` y `correlate`.

---

## T5 — Do-file automatizado (Semana 13)

### Qué automaticé

| Antes (A5) | Ahora (T5) |
|---|---|
| Nombres de variables y rutas escritos en cada línea | Un bloque de **parámetros** al inicio (`local` y `global`); el cuerpo solo usa macros |
| Un `summarize` por variable | `foreach` sobre la lista `numericas` |
| Conteos por tramo escritos uno a uno | `forvalues` sobre tramos de educación, usando `r(N)` |
| Un `tabulate` + `tabstat` por cada grupo | El programa `descriptivos_grupo`, llamado desde un loop sobre `grupos` |
| Variables auxiliares creadas y borradas a mano | `tempvar` |
| Coeficientes copiados de la pantalla | Modelos guardados con `estimates store`, comparados con `estimates table`, y `_b[]` mostrado con `display` |
| Una regresión por sector, una por una | `levelsof` + `foreach`, resultados en una matriz `J()` y exportados a Excel con `putexcel` |

### Qué editar para reutilizarlo con otros datos

Solo el bloque **1. PARÁMETROS** de `scripts/tarea_t5.do`:

| Parámetro | Qué controla |
|---|---|
| `local datos` | Ruta del CSV de entrada |
| `local depvar` | Variable dependiente |
| `local xprin` | Regresor principal (su coeficiente se reporta y se exporta) |
| `local controles` | Controles adicionales del modelo (puede quedar vacío) |
| `local numericas` | Variables de los descriptivos |
| `local grupos` | Grupos para el programa de descriptivos |
| `local grupo_reg` | Grupo de las regresiones por separado (debe ser una variable de texto) |
| `local var_tramos`, `t_ini`, `t_paso`, `t_fin` | Variable y rango de los tramos |
| `local excel` | Nombre del Excel de salida |
| `global umbral` | Umbral de ingreso para los conteos |
| `global fuente` | Nota de fuente que va en el Excel |

Con otra base hay que revisar también el paso 2 (preparación de datos): ahí se crean
`experiencia` y `mujer` a partir de `edad`, `educ` y `genero`. Si la nueva base no
tiene esas columnas, ese paso se adapta.

### Principales resultados

- Cada año de educación se asocia a unos **$42019** más de ingreso mensual (m1)
  y **$42246** al controlar por sexo (m2); N = 55.
- La brecha mujer–hombre en m2 (−$55.686) no es estadísticamente distinta de cero.
- Por sector, el coeficiente de educación va de $23783 a $42713, con 5 a 15
  personas por sector: estimaciones muy imprecisas.

Son asociaciones descriptivas en una muestra pequeña; no implican causalidad.

## Declaración de autoría y uso de IA

Copia al final de tu `README.md`:

```markdown
## Declaración de autoría y uso de IA
- Herramienta utilizada: Claude code 
- Para qué la usé: Explicarme que hacen ciertos comandos del codigo y revisar que corra bien el .do 
- Qué hice yo: Escribir el script (.do) y el readme
- Verificación: confirmo que entiendo y puedo explicar todo lo que entrego.
```

**Uso permitido:** depurar un loop que no corre, entender un mensaje de error,
preguntar la diferencia entre `local` y `global`, pedir alternativas a un bloque
que ya escribiste.

**Uso no permitido:** pedir el do-file completo. En esta tarea se pregunta en
particular por el **diseño**: por qué esa macro, por qué un programa y no un loop,
qué pasa si cambia el argumento. Si el diseño no es tuyo, no podrás responder.

Declarar el uso de IA **no baja la nota**. No saber o no entender tu código, **sí**.
Ocultar el uso constituye falta a la ética académica (Guía de uso ético de
tecnologías digitales, UdeC).
