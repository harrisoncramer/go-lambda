package main

import (
	"encoding/json"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
	Name string `json:"name"`
}

type Response struct {
	StatusCode int               `json:"statusCode"`
	Headers    map[string]string `json:"headers"`
	Body       string            `json:"body"`
}

func makeResponse(response string, status int) Response {
	return Response{
		StatusCode: status,
		Headers:    map[string]string{"Content-Type": "application/json"},
		Body:       response,
	}
}

func HandleRequest(req events.APIGatewayProxyRequest) (Response, error) {
	fmt.Println("Request body is", req.Body)
	var event MyEvent

	err := json.Unmarshal([]byte(req.Body), &event)
	if err != nil {
		return makeResponse("Unable to unmarshal JSON", 400), nil
	}

	if event.Name == "" {
		return makeResponse("Please provide a name", 400), nil
	}

	return makeResponse(fmt.Sprintf("Hello there, %s", event.Name), 200), nil
}

func main() {
	lambda.Start(HandleRequest)
}
