FROM ruby:2.2-alpine
RUN mkdir /app
WORKDIR /app
ADD . /app
RUN apk add --no-cache build-base && \
    gem install bundler:1.17.2 &&  \
    bundle install && \
    apk del build-base



ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
