FROM python:3.7.3

LABEL maintainer="bamibabson@gmail.com"

WORKDIR /app

COPY requirements.txt /app

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . /app

RUN export $(xargs < .env)

EXPOSE 8000/tcp