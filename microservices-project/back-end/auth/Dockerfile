FROM python:3.11-slim AS builder

WORKDIR /app

# Install system dependencies for mysqlclient
RUN apt-get update && apt-get install -y \
    pkg-config \
    default-libmysqlclient-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install uv
RUN uv venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

FROM python:3.11-slim AS auth

WORKDIR /app

# Install runtime dependencies for mysqlclient
RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
COPY ./server.py ./server.py
COPY ./init.sql ./init.sql
# Copy .env if it exists (for local development)
COPY .env* ./

ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 8000

CMD ["python", "server.py"]