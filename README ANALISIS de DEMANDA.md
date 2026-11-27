# Informe Técnico: Análisis de Demanda Eléctrica en Alimentadores de Media Tensión mediante Integración de Telemetría CSV y Base de Datos Relacional

## 1. Introducción
En la gestión operativa de sistemas de distribución eléctrica, el monitoreo continuo de la demanda activa en alimentadores de media tensión permite evaluar el nivel de carga de las subestaciones, identificar patrones horarios de consumo y detectar contingencias o interrupciones de suministro. Sin embargo, en entornos reales de operación SCADA/OT, los registros telemétricos suelen exportarse en archivos planos de serie temporal (`CSV`) que contienen únicamente códigos de circuito y mediciones crudas, mientras que los atributos estructurales de la red —como la subestación de origen, el nivel de tensión, el tipo de carga predominante y la capacidad nominal— residen en bases de datos relacionales independientes.

El presente trabajo integra ambas fuentes heterogéneas en un flujo reproducible ejecutado en **Google Colab** utilizando **Python**, **Pandas**, **SQLite3** y **Matplotlib**. A partir de 2,880 intervalos de 15 minutos correspondientes al mes de septiembre de 2026 para 12 alimentadores (`O-141` a `O-284`) y una base de datos relacional normalizada con el catálogo de tres subestaciones, se construyó un dataset unificado de 34,560 registros para analizar el desempeño energético y el factor de utilización de cada circuito.

---

## 2. Marco teórico de las tecnologías y librerías usadas
* **Google Colaboratory (Colab):** Entorno interactivo basado en cuadernos Jupyter ejecutado en la nube de Google, que permite combinar código Python ejecutable, documentación en Markdown y salidas gráficas sin requerir configuración local de dependencias.
* **Pandas (`pandas`):** Biblioteca fundamental de Python para manipulación y análisis de datos tabulares mediante estructuras `DataFrame`. En este proyecto se empleó para la ingesta de archivos CSV con delimitadores personalizados (`read_csv`), remodelación de formato ancho a largo (`melt`), consultas SQL (`read_sql_query`), unión relacional (`merge`) y agregaciones estadísticas (`groupby`).
* **SQLite3 (`sqlite3`):** Motor de base de datos relacional transaccional embebido, ligero y autocontenido compatible con el estándar SQL. Permitió materializar el modelo relacional (`subestaciones` y `alimentadores`) a partir de un script `.sql` y ejecutar consultas con integridad referencial (`INNER JOIN`).
* **NumPy (`numpy`):** Librería de computación numérica vectorizada que sirve de soporte matemático para el cálculo de métricas energéticas y estadísticas descriptivas.
* **Matplotlib (`matplotlib.pyplot`):** Biblioteca estándar de visualización científica en Python utilizada para generar gráficos de barras horizontales comparativas, perfiles horarios multi-serie, series temporales con media móvil y diagramas de caja (*boxplots*).

---

## 3. Descripción del dataset usado
El proyecto articula **dos fuentes de datos** complementarias:

1. **Dataset 1 — Telemetría de Potencia Activa (`dataset.csv`):**
   * **Origen y formato:** Archivo plano separado por punto y coma (`;`) con 2,882 líneas totales (cabecera de códigos de alimentador, fila descriptiva de magnitud `KW-DEL` y 2,880 registros válidos).
   * **Cobertura temporal:** Del `01/09/2026 00:15` al `01/10/2026 00:00` con resolución de 15 minutos (96 muestras diarias × 30 días = 2,880 intervalos sin valores nulos).
   * **Variables:** Columna temporal `FECHA` y 12 columnas numéricas (`float64`) correspondientes a la potencia activa entregada en kilovatios (`kW`) de los circuitos `O-141`, `O-142`, `O-143`, `O-144`, `O-145`, `O-146`, `O-242`, `O-244`, `O-281`, `O-282`, `O-283` y `O-284`.

2. **Dataset 2 — Catálogo Técnico Relacional (`base_datos_subestaciones.sql` / `subestaciones_ot.db`):**
   * **Estructura:** Dos tablas relacionadas mediante clave foránea (`id_subestacion`):
     * `subestaciones` (3 registros): `SE-01` (*Subestación Parque Industrial*, 10.0 kV, Zona Norte), `SE-02` (*Subestación Centro Histórico*, 10.0 kV, Zona Centro) y `SE-03` (*Subestación Viñani - Cono Sur*, 22.9 kV, Zona Sur).
     * `alimentadores` (12 registros): vincula cada código de circuito con su subestación, nombre descriptivo, clasificación de carga (`Industrial`, `Residencial`, `Comercial`, `Mixto`, `Institucional`) y `capacidad_nominal_kw`.

3. **Dataset Final Integrado (`dataset_final_integrado.csv`):**
   * Producto de la normalización e integración de ambas fuentes, compuesto por **34,560 filas y 14 columnas**, incorporando variables derivadas como `energia_kwh`, `factor_utilizacion_pct`, `hora`, `dia_semana` y `es_hora_punta`.

---

## 4. Descripción de los pasos realizados en el proyecto
1. **Ingesta y depuración del CSV:** Se cargó `dataset.csv` especificando `sep=';'` y omitiendo la segunda fila redundante (`skiprows=[1]`). Se estandarizó el nombre de la columna temporal a `FECHA` y se convirtió al tipo `datetime64[ns]`, verificando la ausencia de registros faltantes (`0` nulos).
2. **Despliegue y consulta de la base de datos SQL:** Mediante `sqlite3`, se ejecutó el archivo `base_datos_subestaciones.sql` para crear las tablas `subestaciones` y `alimentadores` con sus registros maestros. Luego, se extrajo el catálogo consolidado hacia un `DataFrame` usando `pd.read_sql_query()` con una sentencia `INNER JOIN`.
3. **Normalización e integración (`melt` + `merge`):** Se transformó la tabla telemétrica de formato ancho (12 columnas de circuitos) a formato largo (`codigo_alimentador`, `potencia_kw`) mediante `pd.melt()`, logrando una estructura relacional apta para cruzarla con `df_catalogo` a través de `pd.merge()`.
4. **Ingeniería de características y análisis exploratorio:** Se calculó la energía activa por intervalo ($E = P \times 0.25\text{ h}$), el porcentaje de utilización respecto a la capacidad nominal de cada circuito y los indicadores horarios. Asimismo, se identificaron 16 intervalos con lectura igual a `0 kW` asociados a cortes operativos puntuales (destacando una interrupción de 2 horas en el alimentador `O-281` el `07/09/2026` entre las `21:30` y las `23:15`).
5. **Generación de visualizaciones y exportación:** Se elaboraron cuatro visualizaciones analíticas con Matplotlib y se exportó el archivo consolidado `dataset_final_integrado.csv`.

### 4.1. Breve descripción de las visualizaciones generadas
* **Visualización 1 (`viz1_energia_utilizacion.png`) — Energía acumulada y factor de utilización máximo:** Gráfico doble de barras horizontales que compara los megavatios-hora (`MWh`) suministrados en el mes y el pico porcentual de carga respecto a la capacidad nominal. Evidencia que el alimentador `O-281` lideró el suministro energético (`2,993.0 MWh`) y registró el mayor estrés operativo (`93.3 %` de utilización), seguido por `O-282` (`91.2 %`) y `O-283` (`90.1 %`), todos pertenecientes a la Subestación Viñani - Cono Sur.
* **Visualización 2 (`viz2_perfil_horario.png`) — Curva de carga diaria promedio por tipo de carga:** Gráfico de líneas de 24 horas que contrasta el comportamiento horario de los cinco segmentos de usuarios. Se observa que los circuitos `Residenciales` y `Mixtos` alcanzan su máximo durante el bloque de hora punta nocturna (`18:00` a `22:00`), mientras que los circuitos `Comerciales` e `Institucionales` concentran su mayor demanda en horario diurno laboral (`09:00` a `17:00`).
* **Visualización 3 (`viz3_serie_temporal.png`) — Evolución temporal de la demanda agregada del sistema:** Serie de tiempo completa de septiembre de 2026 en megavatios (`MW`) superpuesta con una media móvil de 24 horas (96 intervalos). Permite distinguir la ciclicidad semanal (reducción de demanda los domingos) y visualizar el descenso abrupto provocado por la salida de servicio del alimentador `O-281` la noche del 7 de septiembre.
* **Visualización 4 (`viz4_boxplot_alimentadores.png`) — Distribución estadística de demanda por alimentador:** Diagrama de caja y bigotes (*boxplot*) agrupado por subestación que muestra la mediana, el rango intercuartílico y los valores atípicos de potencia activa (`kW`) de los 12 circuitos, facilitando la comparación de dispersión entre alimentadores industriales de alta carga (`O-141`, `O-284`) y circuitos auxiliares (`O-146`).

---

## 5. Conclusiones
1. **Valor de la integración CSV + SQL:** Cruzar series temporales crudos de telemetría con metadatos técnicos almacenados en una base de datos relacional enriquece significativamente el análisis energético, permitiendo segmentar indicadores por subestación, nivel de tensión, tipo de usuario y margen de capacidad instalada.
2. **Diagnóstico operativo de la red:** La Subestación Viñani - Cono Sur (`SE-03`) concentra la mayor demanda energética del sistema, con tres de sus cuatro alimentadores (`O-281`, `O-282` y `O-283`) superando el umbral del `90 %` de utilización nominal en horas punta, lo que sugiere priorizar estudios de expansión o transferencia de carga en dicha zona.
3. **Detección de anomalías:** El análisis exploratorio permitió aislar 16 intervalos con demanda nula (`0 kW`) en cinco circuitos (`O-142`, `O-146`, `O-244`, `O-281` y `O-284`), demostrando la utilidad de Pandas para auditar continuidad de suministro y calidad de datos SCADA.

---

## 6. Bibliografía
* Hunter, J. D. (2007). Matplotlib: A 2D graphics environment. *Computing in Science & Engineering*, 9(3), 90–95. https://doi.org/10.1109/MCSE.2007.55
* McKinney, W. (2010). Data structures for statistical computing in Python. *Proceedings of the 9th Python in Science Conference*, 56–61. https://doi.org/10.25080/Majora-92bf1922-00a
* McKinney, W. (2022). *Python for data analysis: Data wrangling with pandas, NumPy, and Jupyter* (3.ª ed.). O'Reilly Media.
* Pandas Development Team. (2026). *pandas documentation: Merging, joining, concatenating and reshaping*. https://pandas.pydata.org/docs/
* Python Software Foundation. (2026). *sqlite3 — DB-API 2.0 interface for SQLite databases*. https://docs.python.org/3/library/sqlite3.html
