FROM jjmerelo/raku-test-circleci

LABEL version="1.0.0" maintainer="Antonio Gamiz <antoniogamiz10@gmail.com>"

USER root
RUN apk update && apk upgrade && apk add python2
RUN apk add  --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.7/main/ nodejs=8.9.3-r1
RUN apk add --no-cache --virtual .gyp graphviz make g++ rsync

USER raku
WORKDIR /home/raku
COPY --chown=raku resources/highlights highlights
ADD https://github.com/perl6/atom-language-perl6/blob/master/package.json higlights/package.json
COPY META6.json META6.json

RUN cd highlights \
    && npm config set unsafe-perm true \
    && npm install . \
    && cd .. && zef install --deps-only . \
    && npm install -g sass

USER raku

ENTRYPOINT raku -v && zef test .
