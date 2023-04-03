compile: 
	cd cmd && GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ../assets/go_lambda
