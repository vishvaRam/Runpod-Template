# Use your specified NVIDIA PyTorch base image
FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-devel

# Set the working directory inside the container
WORKDIR /workspace

# Install common development tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    openssh-server \
    nginx \
    curl \
    vim \
    nano \
    wget \
    build-essential \
    tmux \
    htop \
    tree \
    unzip \
    zip \
    rsync && \
    rm -rf /var/lib/apt/lists/*

# Generate SSH host keys if they don't exist
# This is crucial for SSH to start without errors
RUN ssh-keygen -A

# Install JupyterLab, widgets, and other common Python packages
# RunPod specifies Jupyter Notebook 6.5.5, but JupyterLab is a more modern interface
# and typically includes notebook functionality. We'll install JupyterLab.
# We'll also add some common data science/ML libraries.
# I've added back `jupyterlab` and `notebook` which were missing in your last version,
# as these are core components of a Jupyter environment.
RUN pip install --no-cache-dir \
    jupyterlab \
    notebook \
    ipywidgets \
    ipykernel \
    "jupyterlab-widgets>=1.0.0" \
    numpy \
    scipy \
    pandas \
    scikit-learn \
    matplotlib \
    # Other Utilities
    tqdm \
    Pillow \
    # Optional: For specialized tasks (uncomment if needed)
    opencv-python \ 
    transformers \   
    datasets \       
    accelerate \  
    && \
    jupyter labextension enable @jupyter-widgets/jupyterlab-manager

RUN MAX_JOBS=4 pip install flash-attn --no-build-isolation

# Configure SSH. This is essential for SSH access.
# Set a default password for root (you might want to change this or use SSH keys for production)
RUN mkdir -p /var/run/sshd # Ensure parent directories exist
RUN echo 'root:runpod' | chpasswd # CHANGE 'runpod' to a strong password or remove for SSH key-only access
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH will not allow login with empty password, so ensure root has a password or disable it
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config # Disable PAM for simpler password auth

# Expose ports as per RunPod's readme
EXPOSE 8888 
EXPOSE 22  

# --- NGINX Configuration (Optional, based on your previous comments) ---
# Uncomment the following lines if you want NGINX to be installed and started.
# You'll also need to create a `default_nginx.conf` file as described previously.
#
# COPY default_nginx.conf /etc/nginx/sites-available/default
# RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Copy and set up the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use the entrypoint script to manage services
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
