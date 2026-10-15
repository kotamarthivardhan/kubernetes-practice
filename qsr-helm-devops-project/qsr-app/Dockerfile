FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app
RUN groupadd --system app && useradd --system --gid app --home-dir /app app
COPY requirements.txt .
RUN pip install --no-cache-dir --no-compile -r requirements.txt
COPY app.py .
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2)"
CMD ["gunicorn", "--bind=0.0.0.0:8080", "--workers=2", "--threads=4", "--timeout=30", "app:app"]
