FROM bitnami/kubectl

COPY entrypoint.sh /kubescanner

WORKDIR /kubescanner

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]