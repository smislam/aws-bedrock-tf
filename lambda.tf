data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "model_lambda_role" {
  name               = "model_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "bedrock_invoke_policy" {
  statement {
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.MODEL_ID}"]
  }
}

resource "aws_iam_policy" "bedrock_policy" {
  name        = "bedrock_policy"
  description = "Policy to invoke bedrock"
  policy      = data.aws_iam_policy_document.bedrock_invoke_policy.json
}

data "aws_iam_policy_document" "guardrail_invoke_policy" {
  statement {
    effect  = "Allow"
    actions = ["bedrock:ApplyGuardrail"]
    # resources = ["arn:aws:bedrock:${data.aws_region.current.name}::guardrail/${aws_bedrock_guardrail.guardrail.}"]
    resources = [aws_bedrock_guardrail.guardrail.guardrail_arn]
  }
}

resource "aws_iam_policy" "guardrail_policy" {
  name        = "guardrail_policy"
  description = "Policy to invoke guardrail"
  policy      = data.aws_iam_policy_document.guardrail_invoke_policy.json
}

resource "aws_iam_role_policy_attachment" "bedrock_lambda_policy" {
  role       = aws_iam_role.model_lambda_role.name
  policy_arn = aws_iam_policy.bedrock_policy.arn
}

resource "aws_iam_role_policy_attachment" "guardrail_lambda_policy" {
  role       = aws_iam_role.model_lambda_role.name
  policy_arn = aws_iam_policy.guardrail_policy.arn
}

data "archive_file" "model_lambda_archive" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dist"
  output_path = "${path.module}/files/lambda.zip"
}

resource "aws_cloudwatch_log_group" "log_group" {
  retention_in_days = 1
}
data "aws_iam_policy_document" "log_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_cloudwatch_log_group.log_group.arn]
  }
}
resource "aws_iam_policy" "log_policy" {
  name   = "log_policy"
  policy = data.aws_iam_policy_document.log_policy_document.json
}
resource "aws_iam_role_policy_attachment" "log_attachment" {
  role       = aws_iam_role.model_lambda_role.name
  policy_arn = aws_iam_policy.log_policy.arn
}

resource "aws_lambda_function" "model_lambda" {
  filename      = "${path.module}/files/lambda.zip"
  function_name = "ModelCaller"
  role          = aws_iam_role.model_lambda_role.arn
  handler       = "tf_model_caller.handler"
  runtime       = "nodejs20.x"
  memory_size   = 256
  timeout       = 30
  environment {
    variables = {
      MODEL_ID          = var.MODEL_ID,
      GUARDRAIL_ID      = aws_bedrock_guardrail.guardrail.guardrail_arn,
      GUARDRAIL_VERSION = aws_bedrock_guardrail_version.guardrail_version.version
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.log_attachment,
    aws_cloudwatch_log_group.log_group
  ]
}