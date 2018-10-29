FROM python:3.7

WORKDIR /tmp
COPY . .
RUN pip3 install pipenv && pipenv install
ENTRYPOINT ["pipenv", "run", "python3", "worker.py"]
