FROM python:3.12-alpine3.20
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY static/ ./static
COPY templates/ ./templates
COPY hello.py ./
CMD ["python", "hello.py"]
