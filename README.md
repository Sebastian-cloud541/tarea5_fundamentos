# A5 — Do-file de limpieza y descriptivos en Stata

**Fundamentos de Programación para Análisis Económico · UdeC-EAN**
Semana 12

Autor: Sebastián Navarrete Poblete

---

## Descripción

Do-file que limpia la base `casen_reducido.csv` (60 personas de la CASEN), crea
variables derivadas, las etiqueta y produce descriptivos. Corre de principio a fin
sin intervención y deja una bitácora (`.log`) con todos los resultados.

## Estructura del repositorio

```
.
├── data/
│   └── raw/
│       └── casen_reducido.csv     # datos de entrada (60 filas, 6 variables)
├── scripts/
│   └── tarea_a5.do                # do-file de la tarea
├── output/
│   └── tarea_a5.log               # bitácora generada al correr el do-file
└── README.md
```

## Cómo correrlo

1. Clonar o descargar este repositorio.
2. Abrir Stata (versión 16 o superior) y pararse en la carpeta del repositorio:
   ```stata
   cd "ruta/a/este/repositorio"
   pwd
   ```
3. Correr el do-file completo:
   ```stata
   do "scripts/tarea_a5.do"
   ```
4. El resultado queda en `output/tarea_a5.log`.

El do-file usa rutas relativas (`data/raw/...`, `output/...`), así que funciona en
cualquier computador siempre que Stata esté en la carpeta raíz del repositorio.

## Qué hace el do-file

| Paso | Contenido |
|------|-----------|
| 1. Carga | `import delimited` con `encoding("utf-8")` para leer bien tildes y ñ |
| 2. Variables | `experiencia` (Mincer: edad − educ − 6, con mínimo 0 vía `replace`), `mujer`, `alta_educ` (13+ años), `pobre` |
| 3. Etiquetas | Etiquetas de variables y de valores (`label define` + `label values`), `encode sector`, `recode educ` en niveles |
| 4. Missing | `count if missing(ingreso)` y comentario sobre el *gotcha* del missing en Stata |
| 5. Descriptivos | `summarize`, `tabulate` (simple y cruzado), `summarize ... if` por grupo, `tabstat`, `correlate`, resultados guardados con `scalar` |
| 6. Interpretación | Comentario final con las cifras principales, en pesos |

## Principales resultados

- 55 de 60 personas reportan ingreso; el ingreso medio es **$655.291** mensuales.
- Con 13 o más años de educación el ingreso medio es **$777.926**, frente a
  **$537.036** con menos de 13 años (diferencia de $240.890).
- Correlación ingreso–educación: **0,68**; ingreso–experiencia: **−0,09**.

Son asociaciones descriptivas en una muestra pequeña; no implican causalidad.

## Declaración de autoría y uso de IA

```markdown
## Declaración de autoría y uso de IA
- Herramienta utilizada: Claude code
- Para qué la usé: Explicarme que hacen ciertos comandos del codigo y revisar que corra bien el .do
- Qué hice yo: Escribir el script y el readme
- Verificación: confirmo que entiendo y puedo explicar todo lo que entrego.
```
**Uso razonable aquí:** preguntar el equivalente en Stata de algo que ya sabes
hacer en R («¿cómo es `group_by` + `summarise` en Stata?»). Eso es exactamente el
«mapa R ↔ Stata» del curso y es un buen uso.
**Uso no permitido:** pedir el do-file completo. Si no puedes explicar por qué
pusiste `capture log close` o qué hace tu `if`, no aprendiste lo que esta
actividad busca — y la T5 se construye encima de esto.
