FROM ubuntu:focal

RUN apt-get update
# For making API calls
RUN apt-get install -y curl

# Install Node.JS
RUN curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt install nodejs -y

# Install git
RUN apt install git -y

# Setting working directory
WORKDIR /home/app

# Copy the required files
COPY script.sh script.sh
COPY .env .env
COPY app.js app.js
COPY package*.json .

RUN npm install

# Give executable permission
RUN chmod +x script.sh
RUN chmod +x app.js


ENTRYPOINT [ "/home/app/script.sh" ]