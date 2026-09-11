# F1 Project

Pipeline de datos de Fórmula 1 sobre **Databricks**: extrae datos históricos y de temporada desde la API [Jolpica-F1](https://api.jolpi.ca/ergast/) (compatible con Ergast), los aterriza como JSON crudo en una capa **bronze**, y los transforma con **dbt** en capas **silver** (staging) y **gold** (marts) listas para análisis.

## Arquitectura

```
API Jolpica-F1  ──►  Extract (Python)  ──►  Bronze (Volumes/Delta)  ──►  dbt staging (silver)  ──►  dbt marts (gold)
```

Todo se orquesta como un **Databricks Job** definido con **Databricks Asset Bundles** (`databricks.yml` + `resources/f1_job.yml`), parametrizado por `season`.

### Capas

- **Bronze** (`/Volumes/f1/bronze/raw_files/...`): JSON crudo descargado de la API y su copia como tabla Delta (`f1.bronze.*`).
- **Silver** (`dbt/models/staging`): vistas de limpieza/normalización por entidad (`stg_drivers`, `stg_constructors`, `stg_races`, `stg_results`, `stg_sprints`, `stg_laps`, `stg_pitstops`).
- **Gold** (`dbt/models/marts`): tablas finales para análisis (`fct_driver_standings`, `fct_constructor_standings`).

## Estructura del repositorio

```
.
├── databricks.yml              # Definición del Databricks Asset Bundle
├── resources/
│   └── f1_job.yml               # Definición del Job (tareas de extract, load y dbt)
├── f1_pipeline/
│   ├── extract/                 # Descarga de datos de la API hacia bronze (JSON)
│   │   ├── core.py              # Paginación, reintentos con backoff, escritura a Volumes
│   │   ├── extract_file.py      # Extrae un endpoint simple (drivers, constructors, races, ...)
│   │   └── extract_file_by_round.py  # Extrae por ronda (laps, pitstops)
│   ├── load/                    # Carga de JSON bronze a tablas Delta
│   │   ├── core.py
│   │   └── load_bronze.py
│   └── json_utils.py
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── Dockerfile               # Imagen para correr dbt de forma standalone
│   └── models/
│       ├── staging/             # Capa silver
│       └── marts/                # Capa gold
└── notebooks/                    # Notebooks de exploración
```

## Fuente de datos

Los datos provienen de la API pública [Jolpica-F1](https://api.jolpi.ca/ergast/), un reemplazo compatible con Ergast. Endpoints usados: `seasons`, `drivers`, `constructors`, `races`, `results`, `sprint`, `laps`, `pitstops`.

## Requisitos

- Cuenta de Databricks con acceso a un workspace y a un SQL Warehouse.
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/databricks-cli.html) configurado (para desplegar el bundle).
- Python 3.11.
- Catálogo `f1` en Unity Catalog con esquemas `bronze`, `silver` y `gold`, y el volumen `f1.bronze.raw_files`.

## Despliegue y ejecución (Databricks Asset Bundles)

```bash
# Validar el bundle
databricks bundle validate

# Desplegar al target "dev"
databricks bundle deploy -t dev

# Ejecutar el job (opcionalmente indicando la temporada)
databricks bundle run dev_manuelmrojas9_f1 -t dev --params season=2026
```

El job (`resources/f1_job.yml`) encadena, por temporada:

1. **Extract**: descarga cada endpoint a `/Volumes/f1/bronze/raw_files/...` en JSON.
2. **Load**: convierte cada carpeta JSON en una tabla Delta `f1.bronze.<entidad>`.
3. **Transform (dbt)**: corre `dbt run` por modelo para poblar silver y luego gold.
4. **Test**: corre `dbt test` sobre todos los modelos transformados.

## dbt

```bash
cd dbt
cp .env.example .env   # completar DATABRICKS_HOST, DATABRICKS_HTTP_PATH y DATABRICKS_TOKEN
dbt deps
dbt run
dbt test
```

También se puede correr dentro de un contenedor con el `Dockerfile` incluido:

```bash
docker build -t f1-dbt -f dbt/Dockerfile .
docker run --env-file dbt/.env f1-dbt
```

## Convenciones

- Los modelos de staging normalizan los IDs (`driver_id`, `constructor_id`, `season`, `round`, etc.) usados por los marts.
- `fct_driver_standings` y `fct_constructor_standings` calculan el campeonato por temporada combinando resultados de carrera y sprint, con desempate estilo F1 (más victorias, luego más segundos lugares, etc.).
