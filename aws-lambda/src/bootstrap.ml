open Lwt
open Cohttp
open Cohttp_lwt_unix

type next_invocation = {request_id: string; body: string}

type lambda_outcome = Success of string | Error of string

exception UnexpectedNextInvocationResponse

exception MissingAwsLambdaRuntimeApiEnvVariable

let aws_lambda_runtime_api =
  try Sys.getenv "AWS_LAMBDA_RUNTIME_API" with _ ->
    raise MissingAwsLambdaRuntimeApiEnvVariable

let aws_lambda_next_invocation_uri =
  Uri.of_string
    ("http://" ^ aws_lambda_runtime_api ^ "/2018-06-01/runtime/invocation/next")

let make_aws_lambda_invocation_success_result_uri request_id =
  Uri.of_string
    ( "http://" ^ aws_lambda_runtime_api ^ "/2018-06-01/runtime/invocation/"
    ^ request_id ^ "/response" )

let make_aws_lambda_invocation_error_result_uri request_id =
  Uri.of_string
    ( "http://" ^ aws_lambda_runtime_api ^ "/2018-06-01/runtime/invocation/"
    ^ request_id ^ "/error" )

let get_next_invocation () =
  let%lwt response, body = Client.get aws_lambda_next_invocation_uri in
  let%lwt body' = body |> Cohttp_lwt.Body.to_string in
  let headers = response |> Response.headers in
  match Header.get headers "lambda-runtime-aws-request-id" with
  | None -> raise UnexpectedNextInvocationResponse
  | Some request_id -> return {body= body'; request_id}

let post_invocation_result request_id output =
  match output with
  | Success output ->
      Client.post ~body:(`String output)
        (make_aws_lambda_invocation_success_result_uri request_id)
  | Error output ->
      Client.post ~body:(`String output)
        (make_aws_lambda_invocation_error_result_uri request_id)

let rec run handler =
  let%lwt {request_id; body} = get_next_invocation () in
  let%lwt output = handler body in
  let%lwt _ = post_invocation_result request_id output in
  run handler
