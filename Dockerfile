FROM python:3.8-slim-buster
COPY . /work
WORKDIR /work
CMD [ "python", "./hello.py"]
RUN  pip install -r requirements.txt
