FROM jjmerelo/alpine-perl6

LABEL version="3.0.0" maintainer="Antonio Gamiz <antoniogamiz10@gmail.com>"

RUN apk add graphviz 
RUN apk add  --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.7/main/ nodejs=8.9.3-r1

COPY resources/highlights /highlights

RUN apk add --no-cache --virtual .gyp python make g++ \
    && cd /highlights \
    && git clone https://github.com/perl6/atom-language-perl6 \
    && npm install . \
    && apk del .gyp \ 
    && cd ..

RUN mkdir Documentable
COPY . /Documentable 

RUN cd Documentable \
    && zef install --deps-only --/test . \
    && zef install . \
    && cd .. \
    && mkdir /documentable

WORKDIR /documentable

ENTRYPOINT ["sh"]