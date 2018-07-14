all:
	docker build -t sit-inbox .

test:
	docker build -qt sit-inbox-test .
	docker run -v $(shell pwd)/tests:/tests -ti sit-inbox-test bash -ic "source /tests/init.bash && bats /tests"

install:
	mkdir -p /usr/local/bin
	install sit-inbox /usr/local/bin/sit-inbox
