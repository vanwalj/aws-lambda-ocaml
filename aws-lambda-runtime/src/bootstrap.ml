let rec run handler =
  let%lwt next_invocation = LambdaClient.get_next_invocation () in
  let%lwt output = handler next_invocation.get_body in
  let%lwt _ = next_invocation.reply output in
  run handler
