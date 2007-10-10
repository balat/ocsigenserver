
let buffer_size = 4096

type channel =
  { perform_io : string -> int -> int -> int Lwt.t;
    mutable curr : int;
    mutable max : int;
    buf : string }

let make_channel perform_io =
  { perform_io = perform_io; curr = 0; max = 0; buf = String.create 4096 }

(****)

type in_channel = channel

let make_in_channel = make_channel

let refill ic =
  assert (ic.curr = ic.max);
  Lwt.bind (ic.perform_io ic.buf 0 (String.length ic.buf)) (fun n ->
  if n = 0 then
    Lwt.fail End_of_file
  else begin
    ic.curr <- 1;
    ic.max <- n;
    Lwt.return ic.buf.[0]
  end)

let input_char ic =
  let curr = ic.curr in
  if curr = ic.max then
    refill ic
  else begin
    ic.curr <- curr + 1;
    Lwt.return ic.buf.[curr]
  end

let unsafe_input ic s ofs len =
  if len = 0 then
    Lwt.return 0
  else
    let avail = ic.max - ic.curr in
    if avail > 0 then begin
      let len = min len avail in
      String.blit ic.buf ic.curr s ofs len;
      ic.curr <- ic.curr + len;
      Lwt.return len
    end else begin
      Lwt.bind (ic.perform_io ic.buf 0 (String.length ic.buf)) (fun n ->
      let len = min len n in
      String.blit ic.buf ic.curr s ofs len;
      ic.curr <- len;
      ic.max <- n;
      Lwt.return len)
    end

let input ic s ofs len =
  if ofs < 0 || len < 0 || ofs > String.length s - len then
    Lwt.fail (Invalid_argument "input")
  else
    unsafe_input ic s ofs len

let rec unsafe_really_input ic s ofs len =
  if len <= 0 then
    Lwt.return ()
  else begin
    Lwt.bind (input ic s ofs len) (fun r ->
    if r = 0 then
      Lwt.fail End_of_file
    else
      unsafe_really_input ic s (ofs + r) (len - r))
  end

let really_input ic s ofs len =
  if ofs < 0 || len < 0 || ofs > String.length s - len then
    Lwt.fail (Invalid_argument "really_input")
  else
    unsafe_really_input ic s ofs len

let input_value ic =
  let header = String.create 20 in
  Lwt.bind
    (really_input ic header 0 20)
    (fun () ->
      let bsize = Marshal.data_size header 0 in
      let buffer = String.create (20 + bsize) in
      String.blit header 0 buffer 0 20;
      Lwt.bind
        (really_input ic buffer 20 bsize)
        (fun () -> Lwt.return (Marshal.from_string buffer 0)))

(*XXX We could (should?) make this faster *)
let input_line ic =
  let buf = ref (String.create 128) in
  let pos = ref 0 in
  let rec loop () =
    if !pos = String.length !buf then begin
      let newbuf = String.create (2 * !pos) in
      String.blit !buf 0 newbuf 0 !pos;
      buf := newbuf
    end;
    Lwt.bind (input_char ic) (fun c ->
    if c = '\n' then
      Lwt.return ()
    else begin
      !buf.[!pos] <- c;
      incr pos;
      loop ()
    end)
  in
  Lwt.bind
    (Lwt.catch loop
       (fun e ->
          match e with
            End_of_file when !pos <> 0 ->
              Lwt.return ()
          | _ ->
              Lwt.fail e))
    (fun () ->
       let res = String.create !pos in
       String.blit !buf 0 res 0 !pos;
       Lwt.return res)

(****)

type out_channel = channel

let make_out_channel = make_channel

let flush_partial oc =
  if oc.curr = 0 then
    Lwt.return ()
  else begin
    Lwt.bind (oc.perform_io oc.buf 0 oc.curr) (fun n ->
      if n < oc.curr then
        String.blit oc.buf n oc.buf 0 (oc.curr - n);
      oc.curr <- oc.curr - n;
      Lwt.return ())
  end

let rec unsafe_output oc s ofs len =
  if len = 0 then
    Lwt.return ()
  else begin
    let buf_size = String.length oc.buf in
    let avail = buf_size - oc.curr in
    if avail >= len then begin
      String.blit s ofs oc.buf oc.curr len;
      oc.curr <- oc.curr + len;
      Lwt.return ()
    end else begin
      String.blit s ofs oc.buf oc.curr avail;
      oc.curr <- buf_size;
      Lwt.bind (flush_partial oc) (fun () ->
      unsafe_output oc s (ofs + avail) (len - avail))
    end
  end

let output oc s ofs len =
  if ofs < 0 || len < 0 || ofs > String.length s - len then
    Lwt.fail (Invalid_argument "output")
  else
    unsafe_output oc s ofs len

let rec flush oc =
  Lwt.bind (flush_partial oc) (fun () ->
  if oc.curr = 0 then
    Lwt.return ()
  else
    flush oc)

let output_string oc s =
  unsafe_output oc s 0 (String.length s)

let output_value oc v = output_string oc (Marshal.to_string v [])