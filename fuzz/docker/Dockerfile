FROM aflplusplus/aflplusplus

ARG USERNAME=prism
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ENV MAKEFLAGS=-j8

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt update && apt install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME


RUN wget https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz
RUN tar -xvf ruby-3.2.2.tar.gz
RUN apt update && apt -y install libyaml-dev libz-dev libssl-dev
RUN cd ruby-3.2.2 && ./configure --disable-install-doc && make && make install
RUN gem install rake-compiler ruby_memcheck
RUN git clone https://github.com/pwndbg/pwndbg && cd pwndbg && ./setup.sh
ENV LC_CTYPE=C.UTF-8
RUN apt install -y libglib2.0-dev bsdmainutils
RUN git clone https://github.com/googleprojectzero/halfempty
RUN cd halfempty && make && cp halfempty /usr/bin/
RUN apt install -y valgrind uuid-dev default-jre python3 unzip
RUN wget https://www.antlr.org/download/antlr-4.8-complete.jar \
    && cp -f antlr-4.8-complete.jar /usr/local/lib
RUN git clone https://github.com/AFLplusplus/Grammar-Mutator
RUN cd Grammar-Mutator && make GRAMMAR_FILE=grammars/ruby.json && \
    cp libgrammarmutator-ruby.so /usr/local/lib
RUN apt install -y screen

USER $USERNAME
WORKDIR /prism


