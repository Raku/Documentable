FROM jjmerelo/raku-test-circleci

LABEL version="1.0.0" maintainer="Antonio Gamiz <antoniogamiz10@gmail.com>"

RUN apk add graphviz
RUN apk add  --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.7/main/ nodejs=8.9.3-r1

COPY resources/highlights /highlights

RUN apk add --no-cache --virtual .gyp python make g++ \
    && cd /highlights \
    && git clone https://github.com/perl6/atom-language-perl6 \
    && npm install . \
    && apk del .gyp \
    && cd ..

RUN npm install -g sass

ENTRYPOINT perl6 -v && zef install --deps-only . && zef test .
