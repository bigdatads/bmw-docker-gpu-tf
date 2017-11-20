FROM nvidia/cuda:cudnn

USER root

# Configure environment
RUN mkdir /jupyter
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV HOME /jupyter
ENV DEBIAN_FRONTEND noninteractive
# this is the version for 'Ubuntu/Linux 64-bit, GPU enabled, Python 2.7/3.5'

ENV MINICONDA_VERSION 4.3.11
ENV MINICONDA_URL http://repo.continuum.io/miniconda/Miniconda2-$MINICONDA_VERSION-Linux-x86_64.sh
ENV TINI_VERSION v0.10.0

# Install base packages
RUN apt-get update && apt-get install -yq --no-install-recommends \
    sudo \
    wget \
    bzip2 \
    unzip \
    locales \
    ca-certificates \
    make \
    build-essential \
    python-dev \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    libpq-dev \
    gcc \
    g++ \
    libatlas-base-dev \
    gfortran \ 
    liblapack-dev \
    libopenblas-dev \
    default-jre \
    && apt-get clean all && \
    rm -rf /var/lib/apt/lists/*

# Set locale
RUN echo "en_US.UTF-8" > /etc/locale.gen && \
    locale-gen

# Setup certificate
RUN echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /root/.curlrc

# Add Tini (process subreaper for jupyter) to prevents kernel crashes
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini
ENTRYPOINT ["/usr/local/bin/tini", "--"]

# Install (mini)conda
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --output-document miniconda.sh --quiet $MINICONDA_URL && \
    /bin/bash miniconda.sh -f -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda install --quiet --yes conda==$MINICONDA_VERSION && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    conda clean -tipsy

# Install pip and setuptools
RUN conda install -f pip setuptools

# Install base packages for python2
RUN conda install --quiet --yes \
    'ipython=4.2*' \
    'ipywidgets=5.1*' \
    'pandas=0.18*' \
    'numexpr=2.5*' \
    'matplotlib=1.5*' \
    'scipy=0.17*' \
    'sympy=1.0*' \
    'cython=0.23*' \
    'patsy=0.4*' \
    'statsmodels=0.6*' \
    'cloudpickle=0.1*' \
    'dill=0.2*' \
    'numba=0.23*' \
    'bokeh=0.11*' \
    'h5py=2.5*' \
    'pyzmq' \
    'mkl' && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy

# Add shortcuts to distinguish for pip
RUN ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip2

# Install remaining requirements via pip
COPY requirements/requirements.txt requirements.txt
RUN pip --no-cache-dir install -r requirements.txt

# Install clipper
RUN apt-get update && apt-get install -yq --no-install-recommends git \
    && apt-get clean all && \
    rm -rf /var/lib/apt/lists/*
RUN pip install git+https://github.com/ucbrise/clipper.git@release-0.2#subdirectory=clipper_admin

# Install nbextensions
RUN pip install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master
RUN jupyter contrib nbextension install --user

# Install py2 kernel spec globally to avoid permission problems when user id switches at runtime
RUN $CONDA_DIR/bin/python -m ipykernel install

# Set environment variables for cuda
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}
ENV CUDA_ROOT /usr/local/cuda/bin
ENV CUDA_CUDA_LIBRARY /usr/local/cuda/lib64/stubs/libcuda.so
ENV CUDA_VISIBLE_DEVICES 0

# Install Tensorflow and set Keras backend
RUN pip --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.0.1-cp27-none-linux_x86_64.whl
ENV KERAS_BACKEND tensorflow

# Install Jupyter lab
RUN pip install jupyterlab

VOLUME /notebooks
VOLUME /misc
VOLUME /data

# Port for TensorBoard
EXPOSE 6006

# Port for Jupyter 
EXPOSE 8888

# install oracle and set it up with py
COPY oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm /
COPY oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm /
COPY oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm /
RUN apt-get update && apt-get install -yq --no-install-recommends apt-utils libaio1 alien && apt-get clean all && rm -rf /var/lib/apt/lists/* && ldconfig
RUN alien -i oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
RUN alien -i oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
RUN alien -i oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm
ENV ORACLE_HOME /usr/lib/oracle/12.1/client64
ENV LD_LIBRARY_PATH $ORACLE_HOME/lib/:$LD_LIBRARY_PATH
ENV PATH $ORACLE_HOME/bin:$PATH
RUN export ORACLE_HOME=$ORACLE_HOME
RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
RUN export PATH=$PATH
RUN ldconfig
# RUN ln -s /usr/include/oracle/12.1/client64 $ORACLE_HOME/include
RUN pip install cx_oracle

# Configure container startup
ENTRYPOINT ["usr/local/bin/tini", "--"]
CMD ["start-notebook.sh"]

# Set ipython profiles
RUN mkdir -p $HOME/.ipython/profile_default/startup
COPY conf/mplimporthook.py $HOME/.ipython/profile_default/startup/
COPY conf.templates conf.templates
COPY conf/jupyter_notebook_config.py $HOME/.jupyter/
COPY conf/notebook.json $HOME/.jupyter/nbconfig/

# Add startup script
COPY start-notebook.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-notebook.sh

# Add boilerplate
ADD api api
COPY config.yml /
COPY example.ipynb /
COPY hive-jdbc-0.14.0-standalone.jar /
