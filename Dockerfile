FROM debian:stretch-slim
MAINTAINER Kamil Madac (kamil.madac@gmail.com)

# Source codes to download
ENV repo="https://github.com/openstack/tempest" branch="master" commit="16.1.0"

# Download nova source codes
RUN if [ -z $commit ]; then \
       git clone $repo --single-branch --depth=1 --branch $branch; \
    else \
       git clone $repo --single-branch --branch $branch; \
       cd tempest && git checkout $commit; \
    fi

# some cleanup
RUN apt update; \
    apt install nano; \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Apply source code patches
RUN mkdir -p /patches
COPY patches/* /patches/
RUN /patches/patch.sh

# Install keystone with dependencies
RUN cd tempest; pip install .

# copy heat configs
COPY configs/tempest/* /etc/tempest/

# external volume
VOLUME /tempest-override

# copy startup scripts
COPY scripts /app

# Define workdir
WORKDIR /app
RUN chmod +x /app/*

#ENTRYPOINT ["/app/entrypoint.sh"]

# Define default command.
#CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]

