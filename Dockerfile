FROM python:3.7-alpine

COPY . /tradebyte-devops-app1
WORKDIR /tradebyte-devops-app1

RUN pip install -r requirements.txt

CMD ["python", "hello.py"]