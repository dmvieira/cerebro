.PHONY: install run test deploy deploy_prod dep_install

ROOT_PATH=$(shell pwd)

PROJECT_PATH=$(ROOT_PATH)/src/github.com/globocom/cerebro

export GOPATH=$(ROOT_PATH)

dep_install:
	@cd $(PROJECT_PATH) && dep ensure -add $(DEP)

install:
	@cd $(PROJECT_PATH) && dep ensure && go install

es:
	@docker-compose -f "docker-compose.yml" up -d --build --scale elasticsearch_data=2

es_logs:
	@docker-compose logs -f

es_down:
	@curl -X DELETE http://localhost:9200/_all -H 'cache-control: no-cache'
	@docker-compose down

run: install es_down es
	./bin/cerebro

test: install
	@cd $(PROJECT_PATH) && go test ./... -coverprofile=$(ROOT_PATH)/coverage.out | go-junit-report > $(ROOT_PATH)/test.xml

install_linux:
	@cd $(PROJECT_PATH) && GOOS=linux GOARCH=amd64 go install

prepare_deploy:
	@cp -f $(ROOT_PATH)/bin/linux_amd64/cerebro $(ROOT_PATH)/deploy/
	@chmod a+x $(ROOT_PATH)/deploy/cerebro

deploy_prod: install_linux prepare_deploy
	@cd $(ROOT_PATH)/deploy/ && tsuru app-deploy -a cerebro .

deploy: install_linux prepare_deploy
	@cd $(ROOT_PATH)/deploy/ && tsuru app-deploy -a cerebro-qa .
