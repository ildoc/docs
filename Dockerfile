FROM squidfunk/mkdocs-material:latest AS builder

COPY . /docs

# ARG SITE_URL
# ARG REPO_URL
# ARG REPO_ICON
# ENV SITE_URL=${SITE_URL}
# ENV REPO_URL=${REPO_URL}
# ENV REPO_ICON=${REPO_ICON}

ENV SITE_URL=
ENV REPO_URL=
ENV REPO_ICON=

RUN mkdocs build --site-dir /app/site

FROM nginx:latest

COPY --from=builder /app/site /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
