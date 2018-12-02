type lambda_outcome = Success of string | Error of string

val run : (string -> lambda_outcome Lwt.t) -> 'a Lwt.t
