FROM debian:latest

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║             BASIC IMAGE SETUP              ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Basic image setup..."

RUN apt-get update -y

RUN apt-get install -y \
    git \
    cron

ENV SHELL /bin/bash
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ┌─────────────────────┬──────────────────────┐
# │            REPO SCRIPT INSTALLER           │
# └─────────────────────┴──────────────────────┘

COPY repo_script_installer.bash /tmp/repo_script_installer.bash
RUN chmod +x /tmp/repo_script_installer.bash

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                 SIMBASHLOG                 ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

# ┌─────────────────────┬──────────────────────┐
# │         INSTALL SIMBASHLOG (CORE)          │
# └─────────────────────┴──────────────────────┘

RUN echo "Installing 'simbashlog' core..."

RUN apt-get install -y \
    procps \
    jq

RUN /tmp/repo_script_installer.bash "https://github.com/fuchs-fabian/simbashlog.git" "v1.1.3"

# ┌─────────────────────┬──────────────────────┐
# │ SETUP ENVIRONMENT FOR SIMBASHLOG NOTIFIERS │
# └─────────────────────┴──────────────────────┘

RUN echo "Setting up python environment for 'simbashlog' notifiers..."

# Install python3
RUN apt-get install -y \
    python3 \
    python3-venv \
    python3-pip

# Create venv
RUN python3 -m venv /opt/venv

# Add venv to PATH
ENV PATH /opt/venv/bin:$PATH

# Create simbashlog-notifier config directory due to volume mount
RUN mkdir -p /root/.config/simbashlog-notifier

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                   MAIN                     ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Installing 'main'..."

COPY main.bash /usr/bin/main.bash
RUN chmod +x /usr/bin/main.bash

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║               CLEAN UP IMAGE               ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Clean up image..."

RUN apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║              SETUP RUN SCRIPT              ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Setup run script..."

COPY run.bash /usr/bin/run.bash
RUN chmod +x /usr/bin/run.bash

CMD ["/usr/bin/run.bash"]
