all: sit/target/x86_64-unknown-linux-musl/release/sit
	docker build -t sit-inbox .

sit/target/x86_64-unknown-linux-musl/release/sit: $(wildcard sit/**/*.rs) 
	git submodule update --init
	docker build -t sit-inbox-test-build-container sit/build-tools/linux-build-container
	docker run -v $(shell pwd)/sit:/sit -w /sit sit-inbox-test-build-container cargo build --release --target=x86_64-unknown-linux-musl

test: sit/target/x86_64-unknown-linux-musl/release/sit
	docker build -t sit-inbox-test .
	@echo "======[ sit: release ]"
	docker run -v $(shell pwd)/tests:/tests -ti sit-inbox-test bash -ic "source /tests/init.bash && bats /tests"
	@echo "======[ sit: master ]"
	docker run -v $(shell pwd)/tests:/tests -ti sit-inbox-test bash -ic "cp /root/.sit-install/master/sit /root/.sit-install/ && source /tests/init.bash && bats /tests"


install:
	mkdir -p /usr/local/bin
	install sit-inbox /usr/local/bin/sit-inbox
