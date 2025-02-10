// AUTO-GENERATED FILE.
// This file is auto-generated by the Ballerina OpenAPI tool.

import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/uuid;
import ballerinax/openai.chat;

configurable string OPENAI_KEY = ?;

configurable string host = "localhost";
configurable int port = 8080;

// Constants
final int MAX_BASE64_STRING_SIZE = 100;

listener http:Listener main_endpoint = new (port, config = {host});

service / on new http:Listener(9090) {
    # Returns the client IP address.
    # + return - returns IP message or error messahe 
    #
    # http:Ok (Get the client IP address.)
    # http:NotFound (Response for any error)
    resource function get ip(@http:CallerInfo {respondType: ip_response} http:Caller hc) returns error? {
        ip_response response;
        do {
            response = {"origin": hc.remoteAddress.ip};
        } on fail {
            response = {"origin": "unknown"};
        }
        check hc->respond(response);
    }

    # Returns the value of the user-agent header
    # the http:header annotation ensures that a default error message will be automatically
    # created and returned if the header can't be found.
    # + return - returns can be any of following types 
    # http:Ok (Get a UUID V4.)
    resource function get user\-agent(@http:Header string user\-agent) returns ua_response {
        ua_response response = {user\-agent};
        return response;
    }

    # Returns a unique ID as per UUID v4 spec
    #
    # + return - returns can be any of following types 
    # http:Ok (Get a UUID V4.)
    # http:DefaultStatusCodeResponse (Response for any error)
    resource function get uuid() returns uuid_response|error_response {

        do {
            string tempUuid = uuid:createRandomUuid();
            uuid_response response = {"uuid": tempUuid};
            return response;
        } on fail {
            error_response response = {"message": "failed to create UUID", "code": "x356"};
            return response;
        }
    }

    resource function post 'base64/decode/[string value]() returns Base64_responseOk|Error_responseBadRequest {
        // Validate incoming string 
        if (value.length() > MAX_BASE64_STRING_SIZE) {
            Error_responseBadRequest response = {body: {"message": "String is too large. Sorry.", "code": "x155"}};
            return response;
        }
        string:RegExp pattern = re `^[0-9a-zA-Z=]+$`;

        if ((value.matches(pattern)) is false) {
            Error_responseBadRequest response = {body: {"message": "Invalid characters. Sorry.", "code": "x156"}};
            return response;
        }
        log:printDebug("Inbound Value  " + value);
        string|error decodedValue = mime:base64Decode(value).ensureType(string);

        if (decodedValue is string) {
            Base64_responseOk response = {body: {"value": decodedValue}};
            log:printDebug("Decoded Value OK  " + decodedValue);
            return response;
        } else {
            Error_responseBadRequest response = {body: {"message": "unable to decode", "code": "x124"}};
            log:printDebug("Error text " + decodedValue.toString());
            return response;
        }
    }

    resource function post 'base64/encode/[string value]() returns Base64_responseOk|Error_responseBadRequest {
        log:printDebug("Inbound Value  " + value);

        // Validate incoming string 
        if (value.length() > MAX_BASE64_STRING_SIZE) {
            Error_responseBadRequest response = {body: {"message": "String is too large. Sorry.", "code": "x155"}};
            return response;
        }
        string:RegExp pattern = re `^[0-9a-zA-Z\\s!$-_]+$`;

        if (pattern.isFullMatch(value) is false) {
            Error_responseBadRequest response = {body: {"message": "Invalid characters. Sorry.", "code": "x157"}};
            return response;
        }

        string|error encodedValue = mime:base64Encode(value).ensureType(string);

        if (encodedValue is string) {
            Base64_responseOk response = {body: {"value": encodedValue}};
            log:printDebug("Encoded Value OK  " + encodedValue);
            return response;
        }
        else {
            Error_responseBadRequest response = {body: {"message": "unable to encode", "code": "x123"}};
            log:printDebug("Error text  " + encodedValue.toString());
            return response;
        }
    }

    resource function post ai/spelling(@http:Payload ai_spelling_payload data) returns error|ai_spelling_responseOk|Error_responseBadRequest {
        http:RetryConfig retryConfig = {
            interval: 5, // Initial retry interval in seconds.
            count: 3, // Number of retry attempts before stopping.
            backOffFactor: 2.0 // Multiplier of the retry interval.
        };

        final chat:Client openAIChat = check new ({auth: {token: OPENAI_KEY}, retryConfig});

        // Extract body contents
        string basePrompt = "Fix grammar and spelling mistakes of this content: ";

        chat:CreateChatCompletionRequest request = {
            model: "gpt-4o-mini",
            messages: [
                {
                    "role": "user",
                    "content": basePrompt.concat(data.text)
                }
            ]
        };
            chat:CreateChatCompletionResponse ai_response = check openAIChat->/chat/completions.post(request);
            string? correctedText = ai_response.choices[0].message.content;

            if (correctedText is ()) {
                Error_responseBadRequest http_response = {body: {"message": "Could not correct grammar/spelling", "code": "x500"}}; 
                return http_response;   
            } else {
                ai_spelling_responseOk http_response = {body: {correctedText} };
                return  http_response;
            }

    }

}
