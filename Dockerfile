# Use your specified NVIDIA PyTorch base image
FROM pytorch/pytorch:2.6.0-cuda12.6-cudnn9-devel

# Set the working directory inside the container
WORKDIR /workspace

# --- CRITICAL FIX: Set the PATH environment variable ---
# This ensures that Python, pip, and other executables installed by Conda (from the base image)
# or pip are correctly found by the shell, especially for SSH sessions.
# /opt/conda/bin is where 'python' and 'pip' were found.
ENV PATH="/opt/conda/bin:/usr/local/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Install common development tools and dependencies
# Using 'apt-get clean' and 'rm -rf /var/lib/apt/lists/*' for smaller image size
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
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Generate SSH host keys if they don't exist
# This is crucial for SSH to start without errors
RUN ssh-keygen -A

# Install JupyterLab, widgets, and other common Python packages
# Consolidating pip installs to optimize Docker layers
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
    tqdm \
    Pillow \
    opencv-python \
    transformers \
    datasets \
    accelerate \
    tensorboard \
    evaluate \
    rich \
    cryptography \
    bitsandbytes \
    hf_transfer && \
    jupyter labextension enable @jupyter-widgets/jupyterlab-manager

# Install flash-attn separately due to MAX_JOBS flag and potential build complexity
RUN MAX_JOBS=4 pip install flash-attn --no-build-isolation

# Configure SSH. This is essential for SSH access.
# Set a default password for root (CHANGE 'runpod' to a strong password or use SSH keys for production)
RUN mkdir -p /var/run/sshd && \
    echo 'root:runpod' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# --- NEW ADDITION: Ensure PATH is set for interactive SSH sessions ---
# This appends the conda bin directory to the PATH in .bashrc for the root user.
# It ensures that python and pip are found when you SSH in.
RUN echo 'export PATH="/opt/conda/bin:$PATH"' >> /root/.bashrc

# Expose ports as per RunPod's readme
EXPOSE 8888
EXPOSE 22

# --- NGINX Configuration (Optional, uncomment if needed) ---
# If you enable NGINX, ensure you have a 'default_nginx.conf' file
# in the same directory as your Dockerfile.
#
# COPY default_nginx.conf /etc/nginx/sites-available/default
# RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Copy and set up the entrypoint script
# Ensure entrypoint.sh is in the same directory as your Dockerfile
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use the entrypoint script to manage services
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
