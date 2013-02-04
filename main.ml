type ns_mutable_attributed_string
type parse_match_callback

external parse_matched : parse_match_callback -> int -> int * int -> unit = "caml_parse_matched"
;;

let parse strobj callbackobj = parse_matched callbackobj 123 (456, 789)

(*
  let po  = Pcoq.Gram.parsable (Stream.of_string str) in
  match Pcoq.Gram.entry_parse Pcoq.main_entry po with
    | Some last -> last
    | None -> failwith "end of input"
 *)
;;

Callback.register "parse" parse;
