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

RUN echo "Adding script to install scripts from git repositories..."

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
# ║                MAIN SCRIPT                 ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Adding main script for cron job..."

COPY main.bash /usr/bin/main.bash
RUN chmod +x /usr/bin/main.bash

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                  CLEANUP                   ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Cleanup..."

RUN apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# ╔═════════════════════╦══════════════════════╗
# ║                                            ║
# ║                INIT SCRIPT                 ║
# ║                                            ║
# ╚═════════════════════╩══════════════════════╝

RUN echo "Adding init script..."

COPY init.bash /usr/bin/init.bash
RUN chmod +x /usr/bin/init.bash

CMD ["/usr/bin/init.bash"]
