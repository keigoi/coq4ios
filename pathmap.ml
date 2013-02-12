type mod_id = string list
type filepath = string

let rec suffixes : mod_id -> mod_id list = function
  | [] -> assert false
  | [name] -> [[name]]
  | dir::suffix as l -> l::suffixes suffix

(* map from logical path to real path *)
type pathmap = (mod_id, filepath) Hashtbl.t
let pathmap : pathmap = Hashtbl.create 19 (* magic number *)

(* update load paths and return .v files found under that dirs. *)
let read_dir_and_update_pathmap (root : filepath) : filepath list =
  let files = ref [] in
  let add_known physi logi fn = 
    if not (Filename.check_suffix fn ".v") then () else (* add only .v files*)
    if List.exists (fun n -> n="test") logi then () else (* ignore dirs named 'test' *)
    let basename = Filename.chop_suffix fn ".v" in
    let fullpath = physi^"/"^fn in
    files := fullpath :: !files;
    let suff = suffixes (logi @ [basename]) in
    List.iter (fun n -> Hashtbl.add pathmap n fullpath) suff (* add all suffixes to maps *)
  in
  (* recurse into dirs. Coqdep_common.add_rec_dir calls add_known for each .v files *)
  Coqdep_common.add_rec_dir add_known root ["Coq"];
  !files

(* dependency graph for .v files *)
type dep_graph = (filepath, filepath list) Hashtbl.t
let dep_graph : dep_graph = Hashtbl.create 19


(* read a .v file and returns paths of files depends on it [pure] *)
let coqdep pathmap (file:filepath) : filepath list =
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

let add_load_paths dirs : filepath list =
  let all_files = List.fold_left (fun files dir -> read_dir_and_update_pathmap dir @ files) [] dirs in
  List.iter (fun file -> 
    Hashtbl.add dep_graph file (coqdep pathmap file)) all_files;
  List.rev all_files

let all_dep_files filepath = 
  let rec dfs check visited node = 
    if List.mem node check then failwith (Printf.sprintf "cycle found at %s" node) else
    if List.mem node visited then visited else     
      let check = node :: check in 
      let edges    = try Hashtbl.find dep_graph node with Not_found -> failwith (Printf.sprintf "edges not found for %s" node) in
      let visited  = List.fold_left (dfs check) visited edges in
      node :: visited
  in 
  let rev = List.fold_left (dfs []) [] filepath in
  List.rev rev
