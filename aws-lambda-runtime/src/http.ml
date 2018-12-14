open Lwt.Infix

let get_address uri =
  let host = Uri.host_with_default uri in
  let port =
    match Uri.port uri with None -> "80" | Some p -> string_of_int p
  in
  Lwt_unix.getaddrinfo host port [Unix.(AI_FAMILY PF_INET)]
  >>= fun addresses ->
  Lwt.return (List.hd addresses)

let request ?(meth = `GET) ?(headers = []) ?body address uri =
  let open Httpaf in
  let open Httpaf_lwt in
  let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Lwt_unix.connect socket address.Unix.ai_addr 
  >>= fun () ->
  let host = Uri.host_with_default uri in
  let content_length =
    match body with
    | None -> "0"
    | Some body -> string_of_int (String.length body)
  in
  let request_headers =
    Request.create meth (Uri.path_and_query uri)
      ~headers:
        (Headers.of_list
           ([("Host", host); ("Content-Length", content_length)] @ headers))
  in
  let response_received, notify_response_received = Lwt.wait () in
  let response_handler notify_response_received response response_body =
    Lwt.wakeup_later notify_response_received (Ok (response, response_body))
  in
  let error_handler notify_response_received error =
    Lwt.wakeup_later notify_response_received (Error error)
  in
  let response_handler = response_handler notify_response_received in
  let error_handler = error_handler notify_response_received in
  let request_body =
    Client.request socket request_headers ~error_handler ~response_handler
  in
  ( match body with
  | Some body -> Body.write_string request_body body
  | None -> () ) ;
  Body.close_writer request_body ;
  response_received 

let read_body response_body =
  let buf = Buffer.create 1024 in
  let body_read, notify_body_read = Lwt.wait () in
  let rec read_fn () =
    Httpaf.Body.schedule_read response_body
      ~on_eof:(fun () ->
        Lwt.wakeup_later notify_body_read (Buffer.contents buf) )
      ~on_read:(fun response_fragment ~off ~len ->
        let response_fragment_bytes = Bytes.create len in
        Lwt_bytes.blit_to_bytes response_fragment off response_fragment_bytes 0
          len ;
        Buffer.add_bytes buf response_fragment_bytes ;
        read_fn () )
  in
  read_fn () ; body_read
