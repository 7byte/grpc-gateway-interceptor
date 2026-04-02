# grpc-gateway-interceptor

`protoc-gen-grpc-gateway-interceptor` 是一个 `protoc` 插件，用于为 gRPC `service` 生成“带拦截器包装”的服务实现。

生成后的代码会为每个 service 创建一个 `XXXWithInterceptor` 结构体，并提供 `RegisterXXX(...)` 方法，让你在注册服务前将业务实现包装成支持 unary/stream 拦截器的实现。

## 适用场景

- 你已经有标准的 `RouteGuideServer`（或任意 `XXXServer`）实现。
- 你希望通过统一入口注入 `grpc.UnaryServerInterceptor` 和 `grpc.StreamServerInterceptor`。
- 你不想手写每个 RPC 方法的拦截器透传逻辑（尤其是流式 RPC）。
- 你不想使用 `RegisterXXXHandlerFromEndpoint` 这种 gRPC 转发的方式来使用拦截器。

## 工作方式

插件会为每个 proto service 生成类似文件：

- `*.pb.gw.inter.go`

在该文件中：

- 生成 `XXXWithInterceptor`（实现原始 `XXXServer` 接口）。
- 生成 `RegisterXXX(srv, unaryInter, streamInter) XXXServer`。
- 对 Unary RPC 调用 `unaryInter(ctx, req, info, handler)`。
- 对 Streaming RPC 调用 `streamInter(srv, stream, info, handler)`。
- 当拦截器为 `nil` 时，直接回退到原始服务方法调用。

## 环境要求

- Go 1.20+
- `protoc`
- `protoc-gen-go`
- `protoc-gen-go-grpc`

## 安装与构建

### 方式一：本地构建（当前仓库）

```bash
go build -o protoc-gen-grpc-gateway-interceptor
```

### 方式二：使用 Makefile

```bash
make build
```

## 生成代码

仓库已提供示例命令（见 `Makefile` 中 `plugin` 目标）：

```bash
protoc \
	--plugin=$(PWD)/protoc-gen-grpc-gateway-interceptor \
	--grpc-gateway-interceptor_out=. \
	--grpc-gateway-interceptor_opt=require_unimplemented_servers=false \
	--grpc-gateway-interceptor_opt=paths=source_relative \
	--go_out=. --go_opt=paths=source_relative \
	--go-grpc_out=. --go-grpc_opt=require_unimplemented_servers=false --go-grpc_opt=paths=source_relative \
	./example/routeguide/route_guide.proto
```

也可以直接执行：

```bash
make plugin
```

## 插件参数

- `require_unimplemented_servers`
	- 默认值：`true`
	- 作用：生成的 `XXXWithInterceptor` 是否嵌入 `UnimplementedXXXServer`
- `paths=source_relative`
	- 与标准 Go 插件一致，控制输出路径策略

## 服务端接入方式

以示例中的 `RouteGuide` 为例：

```go
func newServer() pb.RouteGuideServer {
		s := &routeGuideServer{routeNotes: make(map[string][]*pb.RouteNote)}
		s.loadFeatures(*jsonDBFile)

		// 由插件生成：RegisterRouteGuide
		return pb.RegisterRouteGuide(s, grpcUnaryInterceptor(), grpcStreamInterceptor())
}

func main() {
		// ...
		grpcServer := grpc.NewServer(opts...)
		pb.RegisterRouteGuideServer(grpcServer, newServer())
		grpcServer.Serve(lis)
}
```

## 示例运行

先启动服务端：

```bash
go run ./example/server/server.go
```

再启动客户端：

```bash
go run ./example/client/client.go
```

启用 TLS（可选）：

```bash
go run ./example/server/server.go -tls=true
go run ./example/client/client.go -tls=true
```

## 项目结构

```text
.
├── main.go                         # protoc 插件入口
├── Makefile
├── example
│   ├── client/client.go            # 示例客户端
│   ├── server/server.go            # 示例服务端（演示拦截器接入）
│   └── routeguide
│       ├── route_guide.proto
│       ├── route_guide.pb.go
│       ├── route_guide_grpc.pb.go
│       └── route_guide.pb.gw.inter.go  # 本插件生成文件
└── README.md
```

## 版本

当前插件版本常量：`v1.0.0`（见 `main.go`）。

可通过以下命令查看：

```bash
go run . --version
```

输出示例：

```text
protoc-gen-grpc-gateway-interceptor 1.0.0
```

## 致谢

`example` 目录中的 route guide 示例基于 gRPC 官方示例改造。
