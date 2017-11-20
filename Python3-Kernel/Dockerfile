FROM bmw/jupyter_gpu:latest

# Install base packages for python3
RUN conda create --quiet --yes -p $CONDA_DIR/envs/py35 python=3.5 \
    'numpy' \
    'scipy' \
    'numba' \
    'pandas' \
    'matplotlib' \
    'seaborn' \
    'cython' \
    'patsy' \
    'cloudpickle' \
    'dill' \
    'h5py' \
    'pyzmq' && \
    conda remove -n py35 --quiet --yes --force qt pyqt && \
    conda clean -tipsy

# Add shortcuts to distinguish for pip
RUN ln -s $CONDA_DIR/envs/py35/bin/pip $CONDA_DIR/bin/pip3

# Install remaining requirements via pip
RUN pip3 --no-cache-dir install -r requirements.txt

# Install py3 kernel spec globally to avoid permission problems when user id switches at runtime
RUN $CONDA_DIR/envs/py35/bin/python -m ipykernel install

# Install Tensorflow
RUN pip3 --no-cache-dir install \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.0.1-cp35-cp35m-linux_x86_64.whl

# install oracle
RUN pip3 install cx_oracle