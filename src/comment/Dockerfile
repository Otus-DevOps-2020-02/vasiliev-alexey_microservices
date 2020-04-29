FROM ruby:2.3-alpine
RUN apk add --no-cache build-base && \
    gem update --system && \
    gem install bundler:1.17.2 && \
    bundle install && \
    apk del build-base

RUN mkdir /app
WORKDIR /app
COPY . /app
#ENV COMMENT_DATABASE_HOST comment_db
#ENV COMMENT_DATABASE comments
CMD ["puma"]
