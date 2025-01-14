# Utilizziamo l'immagine di squidfunk/mkdocs-material per generare le pagine
FROM squidfunk/mkdocs-material:latest as builder

# Copiamo il codice sorgente del sito
COPY . /docs

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
