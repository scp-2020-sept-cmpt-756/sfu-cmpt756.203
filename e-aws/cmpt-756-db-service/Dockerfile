FROM python:3.8-slim

WORKDIR /code

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY config.json .
COPY app.py .

EXPOSE 5002

CMD ["python", "app.py", "5002"]