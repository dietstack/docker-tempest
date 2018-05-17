FROM debian:stretch-slim
MAINTAINER Kamil Madac (kamil.madac@gmail.com)

RUN mkdir -p /patches
COPY patches/* /patches/

#Source codes to download
ENV REPO="https://github.com/openstack/tempest" BRANCH="master" COMMIT="16.1.0"

RUN echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf && \                               
    echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf && \                            
    apt update; apt install -y ca-certificates wget python && \
    update-ca-certificates; \                                                                       
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py; \                             
    python get-pip.py; \                                                                            
    rm get-pip.py; \                                                                                
    wget https://raw.githubusercontent.com/openstack/requirements/stable/pike/upper-constraints.txt -P /app && \
    /patches/stretch-crypto.sh && \                                                                 
    apt-get clean && apt autoremove && \                                                            
    rm -rf /var/lib/apt/lists/*; rm -rf /root/.cache

ENV SVC_NAME=tempest
ENV BUILD_PACKAGES="git build-essential libssl-dev libffi-dev python-dev"

RUN apt update; apt install -y $BUILD_PACKAGES && \                                                 
    if [ -n $COMMIT ]; then \                                                                     
      cd /; git clone $REPO --single-branch --branch $BRANCH; \                                   
      cd /$SVC_NAME && git checkout $COMMIT; \                                                    
    else \                                                                                        
      git clone $REPO --single-branch --depth=1 --branch $BRANCH; \                               
    fi; \                                                                                         
    cd /$SVC_NAME; pip install .; \                                                                       
    apt remove -y --auto-remove $BUILD_PACKAGES &&  \                                               
    apt-get clean && apt autoremove && \                                                            
    rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache            

# some cleanup
RUN apt update; \
    apt install nano; \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Apply source code patches
RUN /patches/patch.sh

# copy heat configs
COPY configs/tempest/* /etc/tempest/

# external volume
VOLUME /tempest-override

# copy startup scripts
COPY scripts /app

# Define workdir
WORKDIR /app
RUN chmod +x /app/*

ENTRYPOINT ["/app/entrypoint.sh"]

