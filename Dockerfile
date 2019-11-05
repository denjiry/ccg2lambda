FROM openjdk:8-jdk-stretch AS build-env

RUN apt-get update && \
    apt-get install -y ant

WORKDIR /build
RUN git clone https://github.com/uwnlp/EasySRL && \
    cd EasySRL && \
    ant

WORKDIR /build
RUN git clone https://github.com/mikelewis0/easyccg

ADD https://github.com/mynlp/jigg/archive/v-0.4.tar.gz /build/v-0.4.tar.gz
RUN tar xzf v-0.4.tar.gz



FROM python:3.6.3-jessie

MAINTAINER Masashi Yoshikawa <yoshikawa.masashi.yh8@is.naist.jp>

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install ccg2lambda specific dependencies
RUN sed -i -s '/debian jessie-updates main/d' /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until false;" >/etc/apt/apt.conf.d/10-nocheckvalid && \
    echo 'Package: *\nPin: origin "archive.debian.org"\nPin-Priority: 500' >/etc/apt/preferences.d/10-archive-pi && \
    apt-get update && \
    apt-get install -y openjdk-8-jre && \
    apt-get update --fix-missing && \
    apt-get install -y \
        bc \
        coq=8.4pl4dfsg-1 \
        libxml2-dev \
        libxslt1-dev && \
    rm -rf /var/lib/apt/lists/* && \
    pip install -U pip && \
    pip install lxml simplejson pyyaml -I nltk==3.0.5 cython numpy chainer==4.0.0 && \
    python -c "import nltk; nltk.download('wordnet')"

WORKDIR /app

# Install Jigg
COPY --from=build-env /build/jigg-v-0.4/jar/jigg-0.4.jar /app/parsers/jigg-v-0.4/jar/jigg-0.4.jar
ADD https://github.com/mynlp/jigg/releases/download/v-0.4/ccg-models-0.4.jar /app/parsers/jigg-v-0.4/jar/
WORKDIR /app/ja
RUN echo "/app/parsers/jigg-v-0.4" > /app/ja/jigg_location.txt && \
    echo "jigg:/app/parsers/jigg-v-0.4" >> /app/ja/parser_location_ja.txt

# Install depccg
# RUN pip install depccg && \
#     python -m depccg en download && \
#     python -m depccg ja download && \
#     echo "depccg:" >> /app/en/parser_location.txt && \
#     echo "depccg:" >> /app/ja/parser_location_ja.txt
RUN pip install flask

WORKDIR /usr/local/bin
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz && gunzip elm.gz && chmod +x elm

WORKDIR /app
ADD . /app
RUN cp ./ja/coqlib_ja.v ./coqlib.v && coqc coqlib.v && \
    cp ./ja/tactics_coq_ja.txt ./tactics_coq.txt
# CMD ["/bin/bash"]

WORKDIR /app
RUN elm make elm/Main.elm --output main.html
EXPOSE 9999
CMD ["python", "server.py"]
