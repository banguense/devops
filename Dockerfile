FROM alpine:latest

# Instalar dependências
RUN apk update && apk add --no-cache \
  bash \
  gcc \
  g++ \
  openmpi \
  openmpi-dev \
  openssh \
  musl-dev \
  make \
  && rm -rf /var/cache/apk/*

# Configurar OpenMPI
ENV PATH="/usr/lib64/openmpi/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH"

# Gerar chaves de host SSH e configurar SSH
RUN mkdir -p /root/.ssh && \
  ssh-keygen -A && \
  ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N "" && \
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
  chmod 600 /root/.ssh/authorized_keys && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# Permitir login root via SSH e desabilitar autenticação por senha
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# Expor a porta 22
EXPOSE 22

# Iniciar o serviço SSH
CMD ["/usr/sbin/sshd", "-D"]
