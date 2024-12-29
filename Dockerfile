
# Taking python as base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# create a user appuser and make it default
RUN  groupadd -r appuser && useradd -r -m -g appuser appuser
USER appuser

# Copy the requirements.txt and install dependencies
COPY requirements.txt .

# Upgrading the pip and setting the path

RUN pip install --upgrade pip
ENV PATH="/home/appuser/.local/bin:$PATH"

# Installing the required library for project
RUN pip install --no-cache-dir -r requirements.txt

# Copy the full application code in docker image
COPY . .

# Set environment variables from the .env file
ENV ENVIRONMENT=${ENVIRONMENT}
ENV HOST=${HOST}
ENV PORT=${PORT}
ENV REDIS_HOST=${REDIS_HOST}
ENV REDIS_PORT=${REDIS_PORT}
ENV REDIS_DB=${REDIS_DB}

# Expose the port the app runs on.
EXPOSE ${PORT}

# Run the application
CMD ["python", "hello.py"]