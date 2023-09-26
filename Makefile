.PONY: all build plugin clean

all: build plugin

build:
	go build -o protoc-gen-grpc-gateway-interceptor

plugin:
	protoc \
	--plugin=$(PWD)/protoc-gen-grpc-gateway-interceptor \
	--grpc-gateway-interceptor_out=. --grpc-gateway-interceptor_opt=require_unimplemented_servers=false --grpc-gateway-interceptor_opt=paths=source_relative \
	--go_out=. --go_opt=paths=source_relative \
	--go-grpc_out=. --go-grpc_opt=require_unimplemented_servers=false --go-grpc_opt=paths=source_relative \
	./example/routeguide/route_guide.proto;

clean:
	rm -f protoc-gen-grpc-gateway-interceptor