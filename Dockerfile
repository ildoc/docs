FROM squidfunk/mkdocs-material:latest AS builder

COPY . /docs

ARG SITE_URL
ARG REPO_URL
ARG REPO_ICON

RUN \
    pip install mkdocs-rss-plugin \
&& \
    pip install mkdocs-glightbox
    
RUN mkdocs build --site-dir /app/site

FROM nginx:latest

COPY --from=builder /app/site /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
