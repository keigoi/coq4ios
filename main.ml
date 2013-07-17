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
  let out_buff = Buffer.create 1024 (*magic number*) in
  let out_ft = Format.formatter_of_buffer out_buff in
  let deep_out_ft = Format.formatter_of_buffer out_buff in
  let inp,outp = Unix.pipe () in
  let inp_chan = Unix.in_channel_of_descr inp in
  let _ = Pp_control.set_gp deep_out_ft Pp_control.deep_gp in
  (fun () ->
     flush_all ();
     orig_stdout := Unix.out_channel_of_descr (Unix.dup Unix.stdout);
     Unix.dup2 outp Unix.stdout;
     Unix.dup2 outp Unix.stderr;
     Pp_control.std_ft := out_ft;
     Pp_control.err_ft := out_ft;
     Pp_control.deep_ft := deep_out_ft;
     set_binary_mode_out !orig_stdout true;
     set_binary_mode_in stdin true;
  ),
  (fun () -> 
    flush_all ();
    Unix.set_nonblock inp;
    begin 
      try
        let bufstr = String.create 1024 (*magic number*)
        in
        let rec loop () = 
          let count  = input inp_chan bufstr 0 (String.length bufstr) in
          Buffer.add_string out_buff (String.sub bufstr 0 count);
          if count = String.length bufstr then 
            loop () else 
            ()
        in loop ()
      with 
          End_of_file -> ()
        | Unix.Unix_error(Unix.EAGAIN,_,_) 
        | Unix.Unix_error(Unix.EWOULDBLOCK,_,_) 
        | Sys_blocked_io -> ()
    end;
    Unix.clear_nonblock inp;
    Format.pp_print_flush out_ft ();
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
    L.first_pos loc, L.last_pos loc
  with
    | _ -> (*FIXME return error msg*) -1, -1

let eval ?(raw=false) (str:string) : bool * string =
  let po = parsable_of_string str in
  try
    let last = V.parse_sentence (po, None) in
    if not raw && Vernacexpr.is_navigation_vernac (snd last) then
      false, "Please use navigation buttons instead."
    else begin
      V.eval_expr last;
      true, read_stdout ();
    end
  with
    | V.End_of_input -> (false, "end of input")
    | V.DuringCommandInterp (loc, exn) -> 
        let msg = Printf.sprintf "error at (%d,%d) %s" (L.first_pos loc) (L.last_pos loc) (Pp.string_of_ppcmds (Errors.print exn)) in
        (false, msg)
    | e -> 
        (false, Printexc.to_string e)

let rec string_of_compile_exn (file, (_,_,loc), exn) =
  let detail = 
  match exn with
  | Util.UserError(str,ppcmds) ->
    Printf.sprintf "UserError(\"%s\",\"%s\")" str (Pp.string_of_ppcmds ppcmds)
  | Util.Error_in_file (file,info,exn) -> string_of_compile_exn (file,info,exn)
  | _ -> Printexc.to_string exn
  in
  Printf.sprintf "Compile Error: (%d, %d) in %s : %s\n" (L.first_pos loc) (L.last_pos loc) file detail

let compile file = 
  try
    let file = Filename.chop_suffix file ".v" in
    States.unfreeze !saved_state;
    V.compile !verbose file
  with Util.Error_in_file (file,info,exn) ->
    print_endline (string_of_compile_exn (file,info,exn));
    raise exn

let rewind i = 
  try
    Backtrack.back i
  with 
    Backtrack.Invalid -> 0

let reset_initial () = eval ~raw:true "Reset Initial.\n"

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

  (* enumerate all .v files and make the dependency graph *)
  library_theories := Array.of_list (Pathmap.add_load_paths [root^"/theories"; root^"/plugins"; root^"/states"]);

  Declaremods.start_library (Names.make_dirpath [Names.id_of_string "Top"]);
  V.load_vernac false (!Flags.coqlib^"/states/MakeInitial.v");
  saved_state := States.freeze();

  ignore (eval ~raw:true "Inductive __:=.\n"); ignore (eval ~raw:true "Reset Initial.\n"); (* without this, Undoing of the first command fails. why?? *)
  true

let start root = 
  try
    start root
  with
    | Util.UserError(str,ppcmds) ->
        print_endline(Printf.sprintf "UserError(\"%s\",\"%s\")" str (Pp.string_of_ppcmds ppcmds));
        false
    | Util.Error_in_file (file,info,exn) ->
        print_endline (string_of_compile_exn (file,info,exn));
        false;
    | e -> 
        print_endline (Printexc.to_string e); 
        false
;;

Callback.register "start" start;
Callback.register "compile" compile;
Callback.register "eval" (fun str -> eval str);
Callback.register "library_theories" (fun _ -> !library_theories);
(* 
Callback.register "parse" parse;
*)
Callback.register "next_phranse_range" next_phrase_range;
Callback.register "rewind" rewind;
Callback.register "reset_initial" reset_initial;
