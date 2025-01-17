# Utilizziamo l'immagine di squidfunk/mkdocs-material per generare le pagine
FROM squidfunk/mkdocs-material:latest AS builder

# Copiamo il codice sorgente del sito
COPY . /docs

# ARG SITE_URL
# ARG REPO_URL
# ENV SITE_URL=${SITE_URL}
# ENV REPO_URL=${REPO_URL}
ENV SITE_URL=
ENV REPO_URL=
ENV REPO_ICON=

# Generiamo le pagine HTML
RUN mkdocs build --site-dir /app/site

# Utilizziamo l'immagine di Nginx per il deployment
FROM nginx:latest

# Copiamo i file generati dalla fase precedente
COPY --from=builder /app/site /usr/share/nginx/html

# Esponiamo la porta 80
EXPOSE 80

# Avviamo Nginx
CMD ["nginx", "-g", "daemon off;"]
