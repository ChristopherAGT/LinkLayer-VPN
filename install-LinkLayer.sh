#!/bin/bash

# ╔════════════════════════════════════════════════════════════════╗
# ║           🚀 INSTALADOR AUTOMÁTICO LINKLAYER DASHBOARD        ║
# ╚════════════════════════════════════════════════════════════════╝

set -e

# Variables personalizables
INSTALL_PATH="/opt"
USERNAME="admin"
PASSWORD="123456"
BACKEND_PORT="8000"
FRONTEND_PORT="3000"
DOMAIN="br1.draplus.store"  # Cambia esto si usarás dominio + nginx

# Colores
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NEUTRO='\e[0m'

echo -e "${CYAN}🔧 Instalando dependencias...${NEUTRO}"
apt update && apt install -y python3 python3-venv python3-pip git curl nginx

# Node.js y Yarn
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
npm install -g yarn pm2

# ╭──────────────────────────────────────────────────────────────╮
# │                     INSTALAR BACKEND                         │
# ╰──────────────────────────────────────────────────────────────╯

echo -e "${CYAN}📦 Instalando Backend...${NEUTRO}"
cd "$INSTALL_PATH"
git clone https://github.com/NewToolsWorks/linklayer-backend-dashboard.git
cd linklayer-backend-dashboard

python3 -m venv dashweb
source dashweb/bin/activate
pip install -r requeriments.txt

echo -e "${CYAN}🚀 Iniciando Backend con PM2...${NEUTRO}"
pm2 start python3 --name linklayer-backend -- install.py \
  --port "$BACKEND_PORT" \
  --host 0.0.0.0 \
  --username "$USERNAME" \
  --password "$PASSWORD"

# ╭──────────────────────────────────────────────────────────────╮
# │                     INSTALAR FRONTEND                        │
# ╰──────────────────────────────────────────────────────────────╯

echo -e "${CYAN}📦 Instalando Frontend...${NEUTRO}"
cd "$INSTALL_PATH"
git clone https://github.com/NewToolsWorks/linklayer-frontend-dashboard.git
cd linklayer-frontend-dashboard
yarn install

echo -e "${CYAN}🚀 Iniciando Frontend con PM2...${NEUTRO}"
pm2 start yarn --name linklayer-frontend -- dev

# ╭──────────────────────────────────────────────────────────────╮
# │                      CONFIGURAR NGINX                        │
# ╰──────────────────────────────────────────────────────────────╯

echo -e "${CYAN}🌐 Configurando NGINX...${NEUTRO}"
cat > /etc/nginx/sites-available/linklayer <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /api/ {
        proxy_pass http://localhost:$BACKEND_PORT/;
        proxy_set_header Host \$host;
    }

    location / {
        proxy_pass http://localhost:$FRONTEND_PORT;
        proxy_set_header Host \$host;
    }
}
EOF

ln -sf /etc/nginx/sites-available/linklayer /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# ╭──────────────────────────────────────────────────────────────╮
# │                        PM2 PERSISTENCIA                      │
# ╰──────────────────────────────────────────────────────────────╯

pm2 save
pm2 startup | bash

# ╭──────────────────────────────────────────────────────────────╮
# │                         FINALIZADO                           │
# ╰──────────────────────────────────────────────────────────────╯

echo -e "${GREEN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ INSTALACIÓN COMPLETA"
echo "🔗 Frontend: http://$DOMAIN"
echo "🔗 Backend API: http://$DOMAIN/api/"
echo "👤 Usuario: $USERNAME"
echo "🔐 Contraseña: $PASSWORD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NEUTRO}"
