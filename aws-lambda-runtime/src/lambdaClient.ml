open Lwt.Infix

module RequestHeaders = struct
  let request_id = "Lambda-Runtime-Aws-Request-Id"

  let function_arn = "Lambda-Runtime-Invoked-Function-Arn"

  let trace_id = "Lambda-Runtime-Trace-Id"

  let deadline = "Lambda-Runtime-Deadline-Ms"

  let client_context = "Lambda-Runtime-Client-Context"

  let cognito_identity = "Lambda-Runtime-Cognito-Identity"
end

let aws_lambda_runtime_api =
  try Sys.getenv "AWS_LAMBDA_RUNTIME_API" with _ ->
    failwith "Missing AWS_LAMBDA_RUNTIME_API env variable"

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

let address = Lwt_main.run (Http.get_address aws_lambda_next_invocation_uri)

let send_response request_id = function
  | Ok body ->
      Http.request ~meth:`POST ?body address
        (make_aws_lambda_invocation_success_result_uri request_id)
      >>= fun _ -> Lwt.return ()
  | Error body ->
      Http.request ~meth:`POST ?body address
        (make_aws_lambda_invocation_error_result_uri request_id)
      >>= fun _ -> Lwt.return ()

type next_invocation =
  { get_body: unit -> string Lwt.t
  ; reply: (string option, string option) result -> unit Lwt.t }

let get_next_invocation () =
  let open Httpaf in
  Http.request ~meth:`GET address aws_lambda_next_invocation_uri
  >>= function
  | Ok ({headers; _}, body) ->
      let request_id = Headers.get_exn headers RequestHeaders.request_id in
      Lwt.return
        { get_body= (fun () -> Http.read_body body)
        ; reply= send_response request_id }
  | Error _ -> failwith "Failed to get next invocation"
