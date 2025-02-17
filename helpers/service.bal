// AUTO-GENERATED FILE.
// This file is auto-generated by the Ballerina OpenAPI tool.

import ballerina/http;
import ballerina/log;
import ballerina/mime;
import ballerina/uuid;
import ballerinax/openai.chat;

configurable string OPENAI_KEY = ?;

configurable string host = "localhost";
configurable int port = 8081;

configurable string aiModel = "gpt-4o-mini";

// Constants
final int MAX_BASE64_STRING_SIZE = 100;

service / on new http:Listener(port) {

    function init() {
        log:printInfo(string `Service started on port ${port}`);
    }

    # Returns the client IP address.
    # + return - returns IP message or unknown if the remote IP can't be found in the remoteAddress block.
    #
    # http:Ok (Get the client IP address.)
    # If the hc-respond call fails, a 500 error will be generated automatically.
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
    # The http:header annotation ensures that a default error message will be automatically
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
    # http:Error_serverFailure (Response for any error)
    resource function get uuid() returns uuid_response|Error_serverFailure {

        do {
            string tempUuid = uuid:createRandomUuid();
            log:printDebug("Generated UUID: " + tempUuid);
            uuid_response response = {"uuid": tempUuid};
            return response;
        } on fail error e {
            log:printDebug("UUID Generated failed: " + e.toString());
            Error_serverFailure response = {body: {"message": "failed to create UUID", "code": "err_001"}};
            return response;
        }
    }

    resource function post 'base64/decode/[string value]() returns Base64_responseOk|Error_responseBadRequest {
        // Validate incoming string 
        log:printDebug("Incoming text: " + value);

        if (value.length() > MAX_BASE64_STRING_SIZE) {
            Error_responseBadRequest response = {body: {"message": "String is too large. Sorry.", "code": "err_002"}};
            return response;
        }
        string:RegExp pattern = re `^[0-9a-zA-Z=]+$`;

        if ((value.matches(pattern)) is false) {
            Error_responseBadRequest response = {body: {"message": "Invalid characters. Sorry.", "code": "err_003"}};
            return response;
        }
        string|error decodedValue = mime:base64Decode(value).ensureType(string);

        if (decodedValue is string) {
            Base64_responseOk response = {body: {"value": decodedValue}};
            log:printDebug("Decoded Value OK  " + decodedValue);
            return response;
        } else {
            Error_responseBadRequest response = {body: {"message": "unable to decode", "code": "err_004"}};
            log:printDebug("Error decoding text: " + decodedValue.toString());
            return response;
        }
    }

    resource function post 'base64/encode/[string value]() returns Base64_responseOk|Error_responseBadRequest {
        log:printDebug("Inbound Value  " + value);

        // Validate incoming string 
        if (value.length() > MAX_BASE64_STRING_SIZE) {
            Error_responseBadRequest response = {body: {"message": "String is too large. Sorry.", "code": "err_002"}};
            return response;
        }
        string:RegExp pattern = re `^[0-9a-zA-Z\\s!$-_]+$`;

        if (pattern.isFullMatch(value) is false) {
            Error_responseBadRequest response = {body: {"message": "Invalid characters. Sorry.", "code": "err_003"}};
            return response;
        }

        string|error encodedValue = mime:base64Encode(value).ensureType(string);

        if (encodedValue is string) {
            Base64_responseOk response = {body: {"value": encodedValue}};
            log:printDebug("Encoded Value: " + encodedValue);
            return response;
        }
        else {
            Error_responseBadRequest response = {body: {"message": "unable to encode", "code": "err_006"}};
            log:printDebug("Error encoding text:  " + encodedValue.toString());
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
            model: aiModel,
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
            Error_responseBadRequest http_response = {body: {"message": "Could not correct grammar/spelling", "code": "err_008"}};
            return http_response;
        } else {
            ai_spelling_responseOk http_response = {body: {correctedText}};
            return http_response;
        }

    }

}
