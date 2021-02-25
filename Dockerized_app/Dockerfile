FROM python:3-slim

WORKDIR /app

RUN apt-get update && apt-get install -y libpq-dev gcc
# need gcc to compile psycopg2	

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt 
