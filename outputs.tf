output "lambda_arn" {
  description = "Lambda that was created"
  value = aws_lambda_function.model_lambda.arn
}

output "LambdaRestAPI" {
  description = "API Gateway URL"
  value = aws_api_gateway_deployment.deployment.invoke_url
}