#!/bin/bash

# Instalar o SDKMAN!
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Instalar o Java 21 usando o SDKMAN!
sdk install java 21.0.1-oracle

# Verificar a instalação do Java
java -version

# Clonar os repositórios
git clone https://github.com/banguense/backend.git
git clone https://github.com/banguense/frontend.git

# Tornar o mvnw executável e compilar o backend
cd backend/app
chmod +x mvnw
./mvnw clean package

# Subir o container do MySQL
cd ../infra
docker-compose up -d mysql

# Mover o arquivo .jar e application.properties para a pasta home
mv app/target/*.jar ~/
mv app/src/main/resources/application.properties ~/

# Instalar o Nginx
sudo apt update
sudo apt install -y nginx nfs-common

# Configurar o Nginx para servir o frontend
sudo mkdir -p /var/www/mpi
sudo cp -r ../../frontend/* /var/www/mpi/

# Configurar o arquivo de configuração do Nginx
sudo tee /etc/nginx/sites-available/mpi <<EOF
server {
    listen 80;
    #server_name immune-raptor-deadly.ngrok-free.app;

    proxy_set_header ngrok-skip-browser-warning "true";

    # Configuração para servir o frontend
    root /var/www/mpi;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~* ^/pages/ {
        try_files \$uri \$uri/ =404;
    }

    location = /execution_results/ {
        deny all;
        return 403;
    }

    location /execution_results/ {
        alias /mnt/nfs_mount/;
        autoindex on;
    }

    location /admin/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Configuração da API
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    error_log /var/log/nginx/mpi_error.log;
    access_log /var/log/nginx/mpi_access.log;
}
EOF

# Ativar a configuração do site e reiniciar o Nginx
sudo ln -s /etc/nginx/sites-available/mpi /etc/nginx/sites-enabled/
sudo systemctl restart nginx

echo "Por favor, edite o arquivo application.properties em ~/ antes de continuar."
read -p "Pressione Enter quando terminar..."

# Solicitar o IP do servidor NFS
read -p "Digite o IP do servidor NFS: " NFS_SERVER_IP

# Montar o diretório NFS
sudo mkdir -p /mnt/nfs_mount
sudo mount -t nfs "${NFS_SERVER_IP}:/srv/nfs" /mnt/nfs_mount
echo "${NFS_SERVER_IP}:/srv/nfs /mnt/nfs_mount nfs defaults 0 0" | sudo tee -a /etc/fstab

# Criar o diretório para o MPI Server e mover os arquivos necessários
sudo mkdir -p /opt/mpi-server/config
sudo mv ~/application.properties /opt/mpi-server/config/
sudo mv ~/*.jar /opt/mpi-server/app.jar

# Criar o serviço do sistema para o MPI Server
sudo tee /etc/systemd/system/mpi-server.service <<EOF
[Unit]
Description=MPI Server Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/mpi-server
Environment="SPRING_CONFIG_LOCATION=/opt/mpi-server/config/application.properties"
ExecStart=/home/ubuntu/.sdkman/candidates/java/current/bin/java -jar /opt/mpi-server/app.jar
Restart=always
RestartSec=10

# Configurações de log:
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mpi-server

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mpi-server
sudo systemctl start mpi-server

echo "Script concluído!"
