FROM python:3.11-slim

# Dependencias de sistema mínimas
RUN apt-get update && apt-get install -y --no-install-recursive \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instala dbt con el adaptador de Databricks
RUN pip install --no-cache-dir dbt-databricks==1.8.*

# Copia solo el proyecto dbt (no todo el repo)
COPY dbt/ /app/dbt/

WORKDIR /app/dbt

# Comando por defecto: correr los modelos
CMD ["dbt", "run"]