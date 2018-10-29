FROM python:3.7-stretch

WORKDIR /syntribos
COPY . .
RUN pip3 install pipenv && PBR_VERSION=0.6 pipenv install && pipenv run syntribos init --force
RUN ./docker-setup.sh
ENTRYPOINT ["pipenv", "run", "python3", "worker.py"]
