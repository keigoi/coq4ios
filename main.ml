type ns_mutable_attributed_string
type parse_match_callback

module L = Ploc
module V = Vernac
module VE = Vernacexpr

let saved_state = ref (States.freeze ())
let init_theories = ref [||]
let rest_theories = ref [||]
let verbose = ref false

let parsable_of_string str = Pcoq.Gram.parsable (Stream.of_string str)
(*
external parse_matched : parse_match_callback -> int -> int * int -> unit = "caml_parse_matched"
;;

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
*)

let eval (str:string) =
  let po = parsable_of_string str in
  try
    V.eval_expr (V.parse_sentence (po, None))
  with
      V.End_of_input -> ()

let compile file = 
  try
    let file = Filename.chop_suffix file ".v" in
    States.unfreeze !saved_state;
    V.compile !verbose file
  with Util.Error_in_file (file, (_,_,loc), exn) -> 
    Printf.printf "Compile Error: (%d, %d) in %s\n" (L.first_pos loc) (L.last_pos loc) file;
    raise exn

(* load MakeInitial and save snapshot  *)
let load_initial () =
  States.unfreeze !saved_state;
  (* Declaremods.start_library (Names.make_dirpath [Names.id_of_string "Top"]); *)
  V.load_vernac false (!Flags.coqlib^"/states/MakeInitial.v");
  saved_state := States.freeze()


(* -coqlib <dir> -boot -nois -notop *)
let start root =
  Lib.init();
  Goptions.set_string_option_value ["Default";"Proof";"Mode"] "Classic";

  Flags.coqlib_spec:=true; 
  Flags.coqlib:=root;
  Flags.boot:=true; 

  Coqinit.init_load_path ();
  Mltop.init_known_plugins ();
  Vm.set_transp_values true;
  Vconv.set_use_vm false;
  (* engage (); *)
  Syntax_def.set_verbose_compat_notations false;
  Syntax_def.set_compat_notations true;
  Coqinit.init_library_roots ();

  saved_state := States.freeze();

  (* enumerate all .v files and make the dependency graph *)
  print_endline "calculating dependencies.";
  let all_theories = Pathmap.add_load_paths [root^"/theories"; root^"/plugins"; root^"/states"] in

  let initfile = Hashtbl.find Pathmap.pathmap ["MakeInitial"] in
  let init = Pathmap.all_dep_files [initfile] in
  init_theories := Array.of_list init;

  let rest = List.filter (fun f -> not (List.mem f init)) all_theories in
  let rest = Pathmap.all_dep_files rest in
  rest_theories := Array.of_list rest
;;

Callback.register "start" start;
Callback.register "load_initial" load_initial;
Callback.register "compile" compile;
Callback.register "eval" eval;
Callback.register "init_theories" (fun _ -> !init_theories);
Callback.register "rest_theories" (fun _ -> !rest_theories);
(* 
Callback.register "parse" parse;
*)
