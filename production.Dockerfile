FROM antoniogamiz/documentable-testing

LABEL version="1.0.0" maintainer="Antonio Gamiz <antoniogamiz10@gmail.com>"

RUN git clone https://github.com/Raku/Documentable.git \
    && cd Documentable \
    && zef install --deps-only --/test . \
    && zef install . \
    && cd .. \
    && mkdir /documentable

WORKDIR /documentable

ENTRYPOINT ["sh"]