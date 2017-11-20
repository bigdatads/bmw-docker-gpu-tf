FROM bmw/jupyter_gpu:latest

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install R and R packages via conda (see https://github.com/jupyter/docker-stacks/blob/master/r-notebook/Dockerfile)
RUN conda install --quiet --yes \
    'readline' \
    'r-base=3.4.1' \
    'r-irkernel' \
    'r-plyr' \
    'r-devtools' \
    'r-tidyverse' \
    'r-shiny' \
    'r-rmarkdown' \
    'r-forecast' \
    'r-rsqlite' \
    'r-reshape2' \
    'r-caret' \
    'r-rcurl' \
    'r-crayon' \
## install R tensorflow conda env
    'r-tensorflow' \
    'r-randomforest' && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy

## Add fav CRAN to obtain latest R packages
RUN echo "deb http://ftp5.gwdg.de/pub/misc/cran/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list
RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E084DAB9

## Add a default CRAN mirror
RUN mkdir -p /usr/lib/R/etc \
  && echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/lib/R/etc/Rprofile.site \
## Add a library directory (for user-installed packages)
  && mkdir -p /usr/lib/R/site-library \
  && chown root:staff /usr/lib/R/site-library \
  && chmod g+wx /usr/lib/R/site-library \
## Fix library path
  && echo "R_LIBS_USER='/usr/lib/R/site-library'" >> /usr/lib/R/etc/Renviron \
  && echo "R_LIBS=\${R_LIBS-'/usr/lib/R/site-library:/usr/lib/R/library:/usr/lib/R/library'}" >> /usr/lib/R/etc/Renviron \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_US.utf8 \
  && /usr/sbin/update-locale LANG=en_US.UTF-8