type ns_mutable_attributed_string
type parse_match_callback

module L = Ploc
module V = Vernac
module VE = Vernacexpr

external parse_matched : parse_match_callback -> int -> int * int -> unit = "caml_parse_matched"
;;

let parsable_of_string str = Pcoq.Gram.parsable (Stream.of_string str)

let traverse_vernac callbackobj = function
  | loc, VE.VernacEndProof _ -> parse_matched callbackobj (-1) (L.first_pos loc, L.last_pos loc)
  | _ -> ()

let parse (str:string) (callbackobj:parse_match_callback) = 
  let po  = parsable_of_string str in
  try
    let last = V.parse_sentence (po, None) in
    traverse_vernac callbackobj last
  with 
      V.End_of_input -> ()

let eval (str:string) =
  let po = parsable_of_string str in
  try
    V.eval_expr (V.parse_sentence (po, None))
  with
      V.End_of_input -> ()

let compile (filename:string) =
  V.compile false filename

let start () =
  print_endline "coq4ios: initializing...";
  Coqtop.init_toplevel (List.tl (Array.to_list Sys.argv))
;;


start ();
Callback.register "parse" parse;
Callback.register "eval" eval;
