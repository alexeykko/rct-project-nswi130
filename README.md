Bash command for run Structurizr:
```bash
docker run -it --rm -p 8080:8080 --mount type=bind,source="$(pwd)/structurizr",target=/usr/local/structurizr structurizr/structurizr local
```