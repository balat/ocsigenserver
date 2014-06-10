module Cookie = struct
  let of_headers header =
    let open Ocsigen_cookies in
    let open Ocsigen_lib in
    let set_cookies = Cohttp.Cookie.Set_cookie_hdr.extract header in
    List.fold_left (fun acc (name, data) ->
        let time = match Cohttp.Cookie.Set_cookie_hdr.expiration data with
          | `Session -> None
          | `Max_age n -> Some (Int64.to_float n)
        in let key, value = Cohttp.Cookie.Set_cookie_hdr.cookie data
        in let secure = Cohttp.Cookie.Set_cookie_hdr.secure data
        in let url = match
            Cohttp.Cookie.Set_cookie_hdr.domain data,
            Cohttp.Cookie.Set_cookie_hdr.path data with
        | Some domain, Some path -> domain ^ "/" ^ path
        | None, Some path -> path
        | Some domain, None -> domain
        | None, None ->
          raise (Invalid_argument "Ocsigen_cookies_server.of_cohttp_header")
        in
        let (_, _, _, _, path, _, _) = Url.parse url in
        Ocsigen_cookies.add_cookie path key (OSet (time, value, secure)) acc)
      Ocsigen_cookies.empty_cookieset set_cookies
end

let of_version vrs =
  let open Ocsigen_http_frame.Http_header in
  match vrs with
  | `HTTP_1_0 -> HTTP10
  | `HTTP_1_1 -> HTTP11
  | _ -> raise (Invalid_argument "Http_header.proto_of_cohttp_version")

let of_meth meth =
  let open Ocsigen_http_frame.Http_header in
  match meth with
  | `GET -> GET
  | `POST -> POST
  | `HEAD -> HEAD
  | `PUT -> PUT
  | `DELETE -> DELETE
  | `OPTIONS -> OPTIONS
  | `PATCH -> PATCH
  | `Other "TRACE" -> TRACE
  | `Other "CONNECT" -> CONNECT
  | `Other "LINK" -> LINK
  | `Other "UNLINK" -> UNLINK
  | `Other _ -> raise (Invalid_argument "Http_header.meth_of_cohttp_meth")

let of_headers headers =
  Cohttp.Header.fold
    (fun key value acc -> Http_headers.add (Http_headers.name key) value acc)
    headers Http_headers.empty

let of_request req =
  let open Ocsigen_http_frame.Http_header in
  {
    mode = Query
        (of_meth @@ Cohttp.Request.meth req,
         Uri.to_string @@ Cohttp.Request.uri req);
    proto = of_version @@ Cohttp.Request.version req;
    headers = of_headers @@ Cohttp.Request.headers req;
  }

let of_response resp =
  let open Ocsigen_http_frame.Http_header in
  {
    mode = Answer (Cohttp.Code.code_of_status @@ Cohttp.Response.status resp);
    proto = of_version @@ Cohttp.Response.version resp;
    headers = of_headers @@ Cohttp.Response.headers resp;
  }

let of_request_and_body (req, body) =
  let open Ocsigen_http_frame in
  {
    frame_header = of_request req;
    frame_content = Some
        (Ocsigen_stream.of_lwt_stream
           (fun x -> x)
           (Cohttp_lwt_body.to_stream body));
    frame_abort = (fun () -> Lwt.return ());
    (* XXX: It's obsolete ! *)
  }

let of_date str =
  (* XXX: handle of GMT ? (see. To_cohttp.to_date) *)
  Netdate.parse_epoch ~localzone:true ~zone:0 str

let of_charset =
  let re = Re_emacs.re ~case:true ".*charset=\\(.*\\)" in
  let ca = Re.(compile (seq ([start; re]))) in
  fun str ->
    try
      let subs = Re.exec ~pos:0 ca str in
      let (start, stop) = Re.get_ofs subs 1 in
      Some (String.sub str start (stop - start))
    with Not_found -> None

let of_response_and_body (resp, body) =
  let res_cookies =
    Cookie.of_headers @@ Cohttp.Response.headers resp in
  let res_lastmodified =
    match Cohttp.Header.get (Cohttp.Response.headers resp) "Last-Modified" with
    | None -> None
    | Some date -> Some (of_date date) in
  let res_etag =
    match Cohttp.Header.get (Cohttp.Response.headers resp) "ETag" with
    | None -> None
    | Some tag -> Scanf.sscanf tag "\"%s\"" (fun x -> Some x) in
  let res_code = Cohttp.Code.code_of_status @@ Cohttp.Response.status resp in
  let res_stream =
    (Ocsigen_stream.of_lwt_stream (fun x -> x)
       (Cohttp_lwt_body.to_stream body), None) in
  (* XXX: I don't want to know what the second value! None! *)
  let res_content_length =
    let open Cohttp.Transfer in
    match Cohttp.Response.encoding resp with
    | Fixed i -> Some (Int64.of_int i)
    | _  -> None in
  let res_content_type = Cohttp.Header.get_media_type
    @@ Cohttp.Response.headers resp in
  let res_headers = of_headers @@ Cohttp.Response.headers resp in
  let res_charset =
    match Cohttp.Header.get (Cohttp.Response.headers resp) "Content-Type" with
    | None -> None
    | Some ct -> of_charset ct in
  let res_location =
    Cohttp.Header.get (Cohttp.Response.headers resp) "Location" in
  let open Ocsigen_http_frame in
  {
    res_cookies;
    res_lastmodified;
    res_etag;
    res_code;
    res_stream;
    res_content_length;
    res_content_type;
    res_headers;
    res_charset;
    res_location;
  }

let of_response_and_body' (resp, body) =
  let open Ocsigen_http_frame in
  {
    frame_header = of_response resp;
    frame_content = Some
        (Ocsigen_stream.of_lwt_stream
           (fun x -> x)
           (Cohttp_lwt_body.to_stream body));
    frame_abort = (fun () -> Lwt.return ());
  }
