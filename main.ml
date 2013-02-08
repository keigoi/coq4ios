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

type mod_id = string list
type filepath = string

let rec suffixes = function
  | [] -> assert false
  | [name] -> [[name]]
  | dir::suffix as l -> l::suffixes suffix

let all_theories roots : (mod_id, filepath) Hashtbl.t * filepath list =
  let hash = Hashtbl.create 12 in
  let files = ref [] in
  let add_known physi logi fn = 
    if not (Filename.check_suffix fn ".v") then () else 
    if List.exists (fun n -> n="test") logi then () else
    let basename = Filename.chop_suffix fn ".v" in
    let fullpath = physi^"/"^fn in
    files := fullpath :: !files; (* add filename *)
    let suff = suffixes (logi @ [basename]) in
    List.iter (fun n -> Hashtbl.add hash n fullpath) suff (* update mapping *)
  in
  List.iter (fun root -> Coqdep_common.add_rec_dir add_known root ["Coq"]) roots;
  hash, List.rev !files

let coqdep pathmap file : filepath list =
  let module L = Coqdep_lexer in
  let find m = try Hashtbl.find pathmap m with _ -> failwith (String.concat "." m) in
  try
    let chan = open_in file in
    let buf = Lexing.from_channel chan in
    let addQueue q v = q := v :: !q in
    let deja_vu_v = ref ([]: filepath list)
    (*and deja_vu_ml = ref ([] : string list)*) in
    begin try
      while true do
      	let tok = L.coq_action buf in
	match tok with
	  | L.Require strl ->
	      List.iter (fun str ->
                let path = find str in
		if not (List.mem path !deja_vu_v) then begin
	          addQueue deja_vu_v path
       		end) strl
	  | L.RequireString s ->
	      let str = Filename.basename s in
              let path = find [str] in
	      if not (List.mem path !deja_vu_v) then begin
	        addQueue deja_vu_v path;
       	      end
	  | L.Load _ -> () (* ignore *)
          | L.Declare _ -> () (* ignore *)
          | L.AddLoadPath _ | L.AddRecLoadPath _ -> (* TODO *) ()
      done
    with L.Fin_fichier -> close_in chan
       | L.Syntax_error (i,j) -> close_in chan; failwith (Printf.sprintf "cannot parse %s at (%d, %d)" file i j)
    end;
    List.rev !deja_vu_v
  with Sys_error _ -> []

let coqdep_all pathmap all_files : (filepath, filepath list) Hashtbl.t =
  let hash = Hashtbl.create 19 in
  List.iter (fun file -> 
    Hashtbl.add hash file (coqdep pathmap file)) all_files;
  hash

let compile state file = 
  let file = Filename.chop_suffix file ".v" in
  States.unfreeze state;
  (* Dumpglob.coqdoc_unfreeze clean_coqdoc_init_state; *)
  V.compile false file

let compile_all state files = 
  try
    List.iter (fun file ->
      print_endline ("compiling: "^ file);
      compile state file) files
  with Util.Error_in_file (file, (_,_,loc), exn) -> 
    Printf.printf "Compile Error: (%d, %d) in %s\n" (L.first_pos loc) (L.last_pos loc) file;
    raise exn

let toposort graph start_nodes = 
  let rec explore check visited node = 
    if List.mem node check then failwith (Printf.sprintf "cycle found at %s" node) else
    if List.mem node visited then visited else     
      let check = node :: check in 
      let edges    = try Hashtbl.find graph node with Not_found -> failwith (Printf.sprintf "edges not found for %s" node) in
      let visited  = List.fold_left (explore check) visited edges in
      node :: visited
  in 
  let rev = List.fold_left (explore []) [] start_nodes in
  List.rev rev

let make_pathmap root = 
  all_theories [root^"/theories"; root^"/plugins"; root^"/states"]

let compile_theories () = 
  let raw_state = States.freeze() in

  (* enumerate all .v files *)
  let pathmap, all_files = make_pathmap !Flags.coqlib in
  print_endline "got stdlibs.";
  (* make a dependency graph *)
  let deps = coqdep_all pathmap all_files in

  let initfile = Hashtbl.find pathmap ["MakeInitial"] in
  let initsorted = toposort deps [initfile] in
  compile_all raw_state initsorted;
  
  States.unfreeze raw_state;
  (* Declaremods.start_library (Names.make_dirpath [Names.id_of_string "Top"]); *)
  V.load_vernac false (!Flags.coqlib^"/states/MakeInitial.v");
  let init_state = States.freeze() 
  in

  let all_sorted = toposort deps all_files in
  let all_sorted = List.filter (fun f -> not (List.mem f initsorted)) all_sorted in
  compile_all init_state all_sorted


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
;;


Callback.register "start" start;
Callback.register "compile_theories" compile_theories;
Callback.register "eval" eval;
Callback.register "parse" parse;
