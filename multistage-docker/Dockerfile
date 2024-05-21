# Build Stage :  [ Step 1 - 3 ]
FROM python:3.10-slim AS build 

# Install Dependencies 
RUN apt-get update && apt-get -y install libpq-dev gcc
COPY ./requirements.txt requirements.txt
RUN pip3 install --no-cache-dir --target=packages -r requirements.txt

# Runtime Stage [ Step 4 - 5 ]
FROM python:3.10-slim AS runtime
# Copying Dependencies from build stage  
COPY --from=build packages /usr/lib/python3.10/site-packages
ENV PYTHONPATH=/usr/lib/python3.10/site-packages

# Security Context 
RUN useradd -m nonroot
USER nonroot

# Env configuration [ Step 6 ]
WORKDIR /
COPY server.py /server.py
EXPOSE 8080
ENTRYPOINT ["python3","-u", "server.py"]