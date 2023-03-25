compile: 
	cd cmd && GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ../bin/hello_world
