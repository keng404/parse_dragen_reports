FROM r-base:4.2.3
RUN apt-get update -y && \
    apt-get install -y curl libxml2-dev libssl-dev libcurl4-openssl-dev
ENV SCRIPT_DIR /scripts
WORKDIR ${SCRIPT_DIR}
RUN chmod -R 777 ${SCRIPT_DIR}
COPY *.R ${SCRIPT_DIR}/
ENV PATH $PATH:${SCRIPT_DIR}
### install R packages
RUN apt-get update -y && \
    apt-get install -y libssl-dev  ca-certificates build-essential && \
        update-ca-certificates
RUN apt-get install -y libfontconfig1-dev libffi-dev  libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev 
######################
ENV PYTHON_VERSION 3.9.6
ENV PATH ${SCRIPT_DIR}/Python-${PYTHON_VERSION}:${PATH}
ENV PYTHONPATH ${SCRIPT_DIR}/Python-${PYTHON_VERSION}/Lib/
RUN wget -O ${SCRIPT_DIR}/Python-3.9.6.tgz "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" && \
    apt-get install tar && \
    tar -xvf Python-${PYTHON_VERSION}.tgz && \
    cd ${SCRIPT_DIR}/Python-${PYTHON_VERSION} && \
    ./configure && \ 
    make && \
    make install
RUN Rscript ${SCRIPT_DIR}/install_packages.R
RUN apt-get install -y  procps