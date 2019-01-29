FROM python:3.7

WORKDIR /tmp
COPY . .
ENV PIPENV_VENV_IN_PROJECT true
ENV NATS_URL="nats://nats:4222"
ENV PYTHONUNBUFFERED="1"
RUN pip3 install pipenv && pipenv install
ENTRYPOINT ["pipenv", "run", "python3", "worker.py"]
