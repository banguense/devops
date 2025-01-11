FROM alpine:latest

# Atualizar pacotes e instalar dependências
RUN apk update && apk add --no-cache \
    bash \
    gcc \
    g++ \
    openmpi \
    openssh \
    musl-dev \
    make \
    && rm -rf /var/cache/apk/*

# Configurar OpenMPI
ENV PATH="/usr/lib64/openmpi/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH"

# Configurar o SSH
RUN mkdir /root/.ssh && \
    ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N "" && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]

