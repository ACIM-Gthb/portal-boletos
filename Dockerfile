FROM nginx:1.27-alpine

# Configuração do servidor com cabeçalhos de segurança
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Somente o conteúdo público vai para a imagem
COPY public/ /usr/share/nginx/html/

# Porta interna: não publique esta porta no Easypanel, use apenas o domínio (Traefik)
EXPOSE 80
