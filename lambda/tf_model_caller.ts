import { BedrockRuntimeClient, InvokeModelCommand, InvokeModelCommandInput, Trace } from "@aws-sdk/client-bedrock-runtime";
import { Handler } from "aws-lambda";

export const handler: Handler = async (event, context) => {

    const badResponse = {
        statusCode: 400,
        body: JSON.stringify('Invalid request.  Ask me a question!')
    }

    if (event.body && event.body !== "") {
        let body = JSON.parse(event.body);
        if (body.question && body.question !== "") {
            let question = body.question;

            const modelId = process.env.MODEL_ID;
            const contentType = 'application/json';
            const rockerRuntimeClient = new BedrockRuntimeClient({region: process.env.REGION});

            const inputCommand: InvokeModelCommandInput = { 
                modelId,
                contentType,
                accept: contentType,
                body: JSON.stringify({
                    anthropic_version: 'bedrock-2023-05-31',
                    max_tokens: 1024,
                    messages: [
                        {role: 'user', 'content': question}
                    ]
                }),
                guardrailIdentifier: process.env.GUARDRAIL_ID,
                guardrailVersion: `${process.env.GUARDRAIL_VERSION}`,
                trace: Trace.ENABLED
            }
            
            const command = new InvokeModelCommand(inputCommand);
            const response = await rockerRuntimeClient.send(command);

            const modelResponse = JSON.parse(new TextDecoder().decode(response.body)).content[0].text;
            
            return {
                statusCode: 200,
                body: modelResponse
            }
        } else {
            return badResponse;
        }
    } else {
        return badResponse;
    }
}