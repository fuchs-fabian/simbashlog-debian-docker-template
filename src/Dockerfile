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

RUN echo "Installing 'simbashlog' core..."

RUN apt-get install -y \
    procps \
    jq

RUN /tmp/repo_script_installer.bash "https://github.com/fuchs-fabian/simbashlog.git" "v1.1.3"

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                   MAIN                     ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Adding main script..."

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
