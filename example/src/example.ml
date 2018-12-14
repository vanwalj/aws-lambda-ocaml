open Lwt

let handler _ = return (Ok (Some "{}"))

let () = Lwt_main.run (AwsLambdaRuntime.Bootstrap.run handler)
