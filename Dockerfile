#Setting up base image
FROM python:3.9

#Setting up working directories in the containers
WORKDIR /app

#Copy the requirement to the container
COPY requirements.txt .

#Install the dependencies
RUN pip install -r requirements.txt

#Copy all the directories in the container
COPY . .

#Expose the port
EXPOSE 8000

#Command to run the application
CMD ["python", "-u" , "hello.py"]
