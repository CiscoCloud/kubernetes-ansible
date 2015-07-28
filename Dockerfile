FROM centos:7

ENV TERRAFORM_VERSION 0.6.1
ENV TERRAFORM_STATE_ROOT /state

# install epel-release first otherwise installing pip or crypto will not be found
RUN yum install -y epel-release openssl openssh-clients unzip && \
    curl -SL -o /terraform.zip https://dl.bintray.com/mitchellh/terraform/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip /terraform.zip -d /usr/local/bin && \
    rm -rf /terraform.zip && \
    yum remove -y unzip && \
    yum -y clean all && \
    mkdir -p /state

# install all dependencies
COPY requirements.txt /kube/
RUN yum install -y python-pip python-crypto && \
    pip install -U -r /kube/requirements.txt && \
    yum -y clean all

# load kubernetes-ansible and default setup
COPY . /kube/

VOLUME /state /ssh

WORKDIR /kube/
CMD ["/kube/env_launch.sh"]
