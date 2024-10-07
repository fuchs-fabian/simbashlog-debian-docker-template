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

COPY install_simbashlog.sh /bin/install_simbashlog.sh
RUN chmod +x /bin/install_simbashlog.sh
RUN /bin/install_simbashlog.sh
RUN rm /bin/install_simbashlog.sh

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

COPY main.bash /bin/main.bash
RUN chmod +x /bin/main.bash

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

COPY run.bash /bin/run.bash
RUN chmod +x /bin/run.bash

CMD ["/bin/run.bash"]
