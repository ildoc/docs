FROM squidfunk/mkdocs-material:latest
# as build

RUN \
    pip install mkdocs-rss-plugin \
&& \
    pip install mkdocs-glightbox

FROM scratch

# Copy all from build
COPY --from=build / /

# Set working directory
WORKDIR /docs

# Expose MkDocs development server port
EXPOSE 8000

# Start development server by default
ENTRYPOINT ["/sbin/tini", "--", "mkdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
