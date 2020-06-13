FROM python:3.6.0-alpine
COPY . /app
WORKDIR /app
RUN set -ex &&   apk   --no-cache --update add  gcc musl-dev &&  pip install -r /app/requirements.txt &&  apk del gcc musl-dev
ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts
ENTRYPOINT ["python3", "post_app.py"]
