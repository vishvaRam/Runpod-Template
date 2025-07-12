# Use your specified NVIDIA PyTorch base image
FROM pytorch/pytorch:2.7.1-cuda12.6-cudnn9-devel

# Set the working directory inside the container
WORKDIR /workspace

ENV PATH="/opt/conda/bin:/usr/local/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

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
    tensorboard \
    evaluate \
    rich \
    cryptography \
    bitsandbytes \
    datasets \
    hf_transfer && \
    jupyter labextension enable @jupyter-widgets/jupyterlab-manager

RUN MAX_JOBS=4 pip install flash-attn --no-build-isolation

# Configure SSH for key-based authentication only
RUN mkdir -p /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config # Disable password authentication
RUN sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# Expose ports as per RunPod's readme
EXPOSE 8888
EXPOSE 22

# --- NGINX Configuration (Optional, based on your previous comments) ---
# COPY default_nginx.conf /etc/nginx/sites-available/default
# RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Copy and set up the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use the entrypoint script to manage services
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
