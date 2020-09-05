FROM debian

RUN apt-get update && apt-get upgrade -y && apt-get install -y ca-certificates curl \
    && curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv ./kubectl /usr/local/bin/ \
    && rm -r /var/lib/apt/lists /var/cache/apt/archives

COPY entrypoint.sh /kubescanner/entrypoint.sh

WORKDIR /kubescanner

RUN chmod +x /kubescanner/entrypoint.sh

ENTRYPOINT ["/kubescanner/entrypoint.sh"]
