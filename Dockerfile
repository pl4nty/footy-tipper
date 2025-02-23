# Use an official Python runtime as a parent image
# Using 3.4 for compatibility with version that Ubuntu installs with python3-dev
FROM python:3.4

# Install python3 for use by Boost.Python library, PostGres Client, and Sqlite3 for testing
RUN apt-get update && apt-get -y install postgresql-client python3-dev sqlite3 libsqlite3-dev

# Create semantic link, because python3-dev installs Python.h in /usr/include/python3.4,
# but Boost.Python looks in /usr/local/include/python3.4 for Python.h
# (From https://askubuntu.com/a/363716)
RUN cd /usr/local/include \
  && ln -s ../../include/python3.5 python3.4 \
  && cd /

# Install packages needed to install Boost library, then install Boost library for python3
# (From https://github.com/lballabio/dockerfiles/blob/master/boost/Dockerfile and
# https://eb2.co/blog/2012/03/building-boost.python-for-python-3.2/)
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential wget libbz2-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.65.0/source/boost_1_65_0.tar.gz
RUN tar xfz boost_1_65_0.tar.gz
RUN rm boost_1_65_0.tar.gz
WORKDIR boost_1_65_0
RUN ./bootstrap.sh --with-python=/usr/local/bin/python3 --with-python-version=3.4 --with-python-root=/usr/local/lib/python3.4
RUN ./b2
RUN ./b2 install
WORKDIR /
RUN rm -rf boost_1_65_0 
RUN ldconfig

ADD ./requirements.txt /app/requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip3 install --no-build-isolation --trusted-host pypi.python.org -r requirements.txt

# Add our code
ADD ./ /app
WORKDIR /app

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Run app with 1 worker process
CMD gunicorn --bind 0.0.0.0:$PORT -w=1 run:app & python3 app/worker.py
