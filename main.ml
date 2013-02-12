type ns_mutable_attributed_string
type parse_match_callback

module L = Ploc
module V = Vernac
module VE = Vernacexpr

let saved_state = ref (States.freeze ()(*never used*))
let library_theories = ref [||]
let verbose = ref false

let orig_stdout = ref stdout

let init_stdout,read_stdout =
  let out_buff = Buffer.create 100 in
  let out_ft = Format.formatter_of_buffer out_buff in
  let deep_out_ft = Format.formatter_of_buffer out_buff in
  let _ = Pp_control.set_gp deep_out_ft Pp_control.deep_gp in
  (fun () ->
     flush_all ();
     orig_stdout := Unix.out_channel_of_descr (Unix.dup Unix.stdout);
     Unix.dup2 Unix.stderr Unix.stdout;
     Pp_control.std_ft := out_ft;
     Pp_control.err_ft := out_ft;
     Pp_control.deep_ft := deep_out_ft;
     set_binary_mode_out !orig_stdout true;
     set_binary_mode_in stdin true;
  ),
  (fun () -> Format.pp_print_flush out_ft ();
             let r = Buffer.contents out_buff in
             Buffer.clear out_buff; r)


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

let next_phrase_range str = 
  let po = parsable_of_string str in
  try
    let loc = fst (V.parse_sentence (po, None)) in
    Printf.fprintf stderr "parse range: %d %d" (L.first_pos loc) (L.last_pos loc);
    L.first_pos loc, L.last_pos loc
  with
    | V.End_of_input -> -1, -1

let eval (str:string) =
  let po = parsable_of_string str in
  try
    let last = V.parse_sentence (po, None) in
    V.eval_expr last;
    read_stdout ();
  with
    | V.End_of_input -> "end of input"
    | V.DuringCommandInterp (loc, exn) -> Printf.sprintf "DuringCommandInterp (%d,%d) %s" (L.first_pos loc) (L.last_pos loc) (Pp.string_of_ppcmds (Errors.print exn))
    | e -> Printexc.print_backtrace stderr; prerr_endline "err"; Printexc.to_string e

let compile file = 
  try
    let file = Filename.chop_suffix file ".v" in
    States.unfreeze !saved_state;
    V.compile !verbose file
  with Util.Error_in_file (file, (_,_,loc), exn) -> 
    Printf.printf "Compile Error: (%d, %d) in %s\n" (L.first_pos loc) (L.last_pos loc) file;
    raise exn

(* load MakeInitial and save snapshot, then set -top Top  *)
let load_initial () =
  States.unfreeze !saved_state;
  (* Declaremods.start_library (Names.make_dirpath [Names.id_of_string "Top"]); *)
  V.load_vernac false (!Flags.coqlib^"/states/MakeInitial.v");
  saved_state := States.freeze();
  Declaremods.start_library (Names.make_dirpath [Names.id_of_string "Top"])


(* -coqlib <dir> -boot -nois -notop *)
let start root =
  init_stdout();
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
  library_theories := Array.of_list (Pathmap.add_load_paths [root^"/theories"; root^"/plugins"; root^"/states"]);
  ()
;;

Callback.register "start" start;
Callback.register "load_initial" load_initial;
Callback.register "compile" compile;
Callback.register "eval" eval;
Callback.register "library_theories" (fun _ -> !library_theories);
(* 
Callback.register "parse" parse;
*)
Callback.register "next_phranse_range" next_phrase_range
