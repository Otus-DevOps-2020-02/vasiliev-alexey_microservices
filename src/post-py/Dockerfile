FROM python:3.6.0-alpine
RUN set -ex &&   apk add --no-cache gcc musl-dev
COPY . /app
WORKDIR /app
RUN pip install -r /app/requirements.txt
#ENV POST_DATABASE_HOST post_db
#ENV POST_DATABASE posts
CMD ["python3", "post_app.py"]
