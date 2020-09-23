# If we have `--squash` support, then use it!
# ifneq ($(shell docker build --help 2>/dev/null | grep squash),)
# DOCKER_BUILD = docker build --squash
# else
DOCKER_BUILD = docker build
# endif

all: build

build: Makefile Dockerfile
	$(DOCKER_BUILD) -t ${MICROSOFT_ACR_SERVER}/packages/nginx.certbot.azure:latest .
	@echo "Done!  Use docker run ${MICROSOFT_ACR_SERVER}/packages/nginx.certbot.azure:latest to run"

push:
	@echo "Sign in to Container Registry via Azure CLI"
	az acr login -n ${MICROSOFT_ACR_NAME} -u ${MICROSOFT_ACR_USER} -p ${MICROSOFT_ACR_PASSWORD}
	docker push ${MICROSOFT_ACR_SERVER}/packages/nginx.certbot.azure:latest