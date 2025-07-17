FROM python:3.11-slim AS builder

WORKDIR /app

# Install system dependencies for mysqlclient
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install uv
RUN uv venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

FROM python:3.11-slim AS gateway

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY . .
# Copy .env if it exists (for local development)
COPY .env* ./

ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 8080

CMD ["python", "server.py"]