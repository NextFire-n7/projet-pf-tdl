open Hashtbl
open Type

(* Définition du type des informations associées aux identifiants *)
type info =
  | InfoConst of string * int
  | InfoVar of string * typ * int * string
  | InfoFun of string * typ * typ list
  | InfoTyp of string * typ
  | InfoStruct of string * typ * int * string * info_ast list
  | InfoAttr of string * typ * int

(* Données stockées dans la tds  et dans les AST : pointeur sur une information *)
and info_ast = info ref  

(* Table des symboles hiérarchique *)
(* Les tables locales sont codées à l'aide d'une hashtable *)
type tds =
  | Nulle
  (* Table courante : la table mère - la table courante *)
  | Courante of tds * (string,info_ast) Hashtbl.t


(* Créer une information à associer à l'AST à partir d'une info *)
let info_to_info_ast i = ref i

(* Récupère l'information associée à un noeud *)
let info_ast_to_info i = !i

(* Création d'une table des symboles à la racine *)
let creerTDSMere () = Courante (Nulle, Hashtbl.create 100)

(* Création d'une table des symboles fille *)
(* Le paramètre est la table mère *)
let creerTDSFille mere = Courante (mere, Hashtbl.create 100)


(* Ajoute une information dans la table des symboles locale *)
(* tds : la tds courante *)
(* string : le nom de l'identificateur *)
(* info : l'information à associer à l'identificateur *)
(* Si l'identificateur est déjà présent dans TDS, l'information est écrasée *)
(* retour : unit *)
let ajouter tds nom info =
  match tds with
  | Nulle -> failwith "Ajout dans une table vide"
  | Courante (_,c) -> Hashtbl.add c nom info

(* Recherche les informations d'un identificateur dans la tds locale *)
(* Ne cherche que dans la tds de plus bas niveau *)
let chercherLocalement tds nom =
  match tds with
  | Nulle -> None
  | Courante (_,c) ->  find_opt c nom 

(* TESTS *)
let%test _ = chercherLocalement (creerTDSMere()) "x" = None
let%test _ = 
  let tds = creerTDSMere() in
  let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
  let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
  ajouter tds "x" ix;
  ajouter tds "y" iy;
  chercherLocalement tds "x" = Some ix
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    chercherLocalement tds "y" = Some iy
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    chercherLocalement tds "z" = None
let%test _ = 
  let tds = creerTDSMere() in
  let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
  let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
  ajouter tds "x" ix;
  ajouter tds "y" iy;
  let tdsf = creerTDSFille(tds) in
  let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
  let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
  ajouter tdsf "x" ix2;
  ajouter tdsf "z" iz;
  chercherLocalement tds "x" = Some ix
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherLocalement tds "y" = Some iy
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherLocalement tds "z" = None
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherLocalement tdsf "y" = None
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherLocalement tdsf "x" = Some ix2
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherLocalement tdsf "z" = Some iz
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherLocalement tdsf "a" = None

(* Recherche les informations d'un identificateur dans la tds globale *)
(* Si l'identificateur n'est pas présent dans la tds de plus bas niveau *)
(* la recherche est effectuée dans sa table mère et ainsi de suite *)
(* jusqu'à trouver (ou pas) l'identificateur *)
let rec chercherGlobalement tds nom =
  match tds with
  | Nulle -> None
  | Courante (m,c) ->
    match find_opt c nom with
      | Some _ as i -> i
      | None -> chercherGlobalement m nom

(* TESTS *)

let%test _ = chercherGlobalement (creerTDSMere()) "x" = None
let%test _ = 
  let tds = creerTDSMere() in
  let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
  let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
  ajouter tds "x" ix;
  ajouter tds "y" iy;
  chercherGlobalement tds "x" = Some ix
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    chercherGlobalement tds "y" = Some iy
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    chercherGlobalement tds "z" = None
let%test _ = 
  let tds = creerTDSMere() in
  let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
  let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
  ajouter tds "x" ix;
  ajouter tds "y" iy;
  let tdsf = creerTDSFille(tds) in
  let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
  let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
  ajouter tdsf "x" ix2;
  ajouter tdsf "z" iz;
  chercherGlobalement tds "x" = Some ix
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherGlobalement tds "y" = Some iy
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherGlobalement tds "z" = None
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherGlobalement tdsf "y" = Some iy
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherGlobalement tdsf "x" = Some ix2
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherGlobalement tdsf "z" = Some iz
let%test _ = 
    let tds = creerTDSMere() in
    let ix = info_to_info_ast (InfoVar ("x", Rat, 0, "SB")) in
    let iy = info_to_info_ast (InfoVar ("y", Int, 2, "SB")) in
    ajouter tds "x" ix;
    ajouter tds "y" iy;
    let tdsf = creerTDSFille(tds) in
    let ix2 = info_to_info_ast (InfoVar ("x", Bool, 3, "LB")) in
    let iz = info_to_info_ast (InfoVar ("z", Rat, 4, "LB")) in
    ajouter tdsf "x" ix2;
    ajouter tdsf "z" iz;
    chercherGlobalement tdsf "a" = None


(* Convertie une info en une chaine de caractère - pour affichage *)
let rec string_of_info info =
  match info with
  | InfoConst (n,value) -> "Constante "^n^" : "^(string_of_int value)
  | InfoVar (n,t,dep,base) -> "Variable "^n^" : "^(string_of_type t)^" "^(string_of_int dep)^"["^base^"]"
  | InfoFun (n,t,tp) -> "Fonction "^n^" : "^(List.fold_right (fun elt tq -> if tq = "" then (string_of_type elt) else (string_of_type elt)^" * "^tq) tp "" )^
                      " -> "^(string_of_type t)
  | InfoTyp (n,t) -> "Type "^n^" : "^(string_of_type t)
  | InfoAttr (n,t,o) -> "Attribut "^n^" : "^(string_of_type t)^" "^(string_of_int o)
  | InfoStruct (n, t, dep, base, champs) -> 
    "Structure "^n^" : "^(string_of_type t)^" "^(string_of_int dep)^"["^base^"]"^"\n"
    ^(List.fold_left (fun q c -> string_of_info (info_ast_to_info c)^q) "" champs )

(* Affiche la tds locale *)
let afficher_locale tds =
  match tds with
  | Nulle -> print_newline ()
  |Courante (_,c) -> Hashtbl.iter ( fun n info -> (print_string (n^" : "^(string_of_info (info_ast_to_info info))^"\n"))) c

(* Affiche la tds locale et récursivement *)
let afficher_globale tds =
  let rec afficher tds indent =
    match tds with
    | Nulle -> print_newline ()
    | Courante (m,c) -> if Hashtbl.length c = 0
                        then print_string (indent^"<empty>\n")
                        else Hashtbl.iter ( fun n info -> (print_string (indent^n^" : "^(string_of_info (info_ast_to_info info))^"\n"))) c ; afficher m (indent^"  ")
  in afficher tds ""

(* Modifie le type si c'est une InfoVar, ne fait rien sinon *)
  let modifier_type_info t i =
    match !i with
    |InfoVar (n,_,dep,base) -> i:= InfoVar (n,t,dep,base)
    |InfoStruct (n,_,dep,base,champs) -> i:= InfoStruct (n,t,dep,base,champs)
    | _ -> failwith "Appel modifier_type_info pas sur un InfoVar"

let%test _ = 
  let info = InfoVar ("x", Undefined, 4 , "SB") in
  let ia = info_to_info_ast info in
  modifier_type_info Rat ia;
  match info_ast_to_info ia with
  | InfoVar ("x", Rat, 4 , "SB") -> true
  | _ -> false
 
(* Modifie les types de retour et des paramètres si c'est une InfoFun, ne fait rien sinon *)
 let modifier_type_fonction_info t tp i =
       match !i with
       |InfoFun(n,_,_) -> i:= InfoFun(n,t,tp)
       | _ -> failwith "Appel modifier_type_fonction_info pas sur un InfoFun"

let%test _ = 
  let info = InfoFun ("f", Undefined, []) in
  let ia = info_to_info_ast info in
  modifier_type_fonction_info Rat [Int ; Int] ia;
  match info_ast_to_info ia with
  | InfoFun ("f", Rat, [Int ; Int]) -> true
  | _ -> false
 
(* Modifie l'emplacement (dépl, registre) si c'est une InfoVar, ne fait rien sinon *)
 let modifier_adresse_info d b i =
     match !i with
     |InfoVar (n,t,_,_) -> i:= InfoVar (n,t,d,b)
     |InfoStruct (n,t,_,_,c) -> i:= InfoStruct (n,t,d,b,c)
     | _ -> failwith "Appel modifier_adresse_info pas sur un InfoVar/InfoStruct"

let%test _ = 
  let info = InfoVar ("x", Rat, 4 , "SB") in
  let ia = info_to_info_ast info in
  modifier_adresse_info 10 "LB" ia;
  match info_ast_to_info ia with
  | InfoVar ("x", Rat, 10 , "LB") -> true
  | _ -> false
    
  let get_nom ia =
    let i = info_ast_to_info ia in
    match i with
    | InfoFun(n,_,_) -> n
    | InfoVar(n,_,_,_) -> n
    | InfoConst(n,_) -> n
    | InfoTyp(n,_) -> n
    | InfoAttr(n,_,_) -> n
    | InfoStruct(n,_,_,_,_) -> n

let %test _ = get_nom (ref (InfoConst ("const", 42))) = "const"
let %test _ = get_nom (ref (InfoVar ("var", Rat, 0, ""))) = "var"
let %test _ = get_nom (ref (InfoFun ("fun", Pointeur Int, []))) = "fun"

  let get_type ia =
    let i = info_ast_to_info ia in
    match i with
    | InfoVar (_,t,_,_) -> t
    | InfoFun (_,t,_) -> t
    | InfoConst _ -> Int
    | InfoTyp(_,t) -> t
    | InfoAttr(_,t,_) -> t
    | InfoStruct(_,t,_,_,_) -> t
    (* | _ -> failwith "Appel get_type pas sur un InfoVar ou InfoFun" *)

let %test _ = get_type (ref (InfoConst ("const", 42))) = Int
let %test _ = get_type (ref (InfoVar ("var", Rat, 0, ""))) = Rat
let %test _ = get_type (ref (InfoFun ("fun", Pointeur Int, []))) = Pointeur Int

  let get_types_params ia =
    let i = info_ast_to_info ia in
    match i with
    | InfoFun (_, _, t) -> t
    | _ -> failwith "Appel get_type_param pas sur un InfoFun"

  let get_taille ia =
    getTaille (get_type ia)

let %test _ = get_taille (ref (InfoConst ("const", 42))) = getTaille Int
let %test _ = get_taille (ref (InfoVar ("var", Rat, 0, ""))) = getTaille Rat
let %test _ = get_taille (ref (InfoFun ("fun", Pointeur Int, []))) = getTaille (Pointeur Int)

  let get_adresse_var ia =
    let i = info_ast_to_info ia in
    match i with
    | InfoVar(_,_,d,_) | InfoStruct(_,_,d,_,_) -> d
    | _ -> failwith "Appel get_adresse_var pas sur un InfoVar/InfoStruct"

let%test _ = try get_adresse_var (ref (InfoConst ("const", 42))) = 0 with Failure _ -> true
let%test _ = get_adresse_var (ref (InfoVar ("var", Rat, 5, ""))) = 5
let%test _ = try get_adresse_var (ref (InfoFun ("fun", Pointeur Int, []))) = 0 with Failure _ -> true

  let get_registre_var ia =
    let i = info_ast_to_info ia in
    match i with
    | InfoVar(_,_,_,r) | InfoStruct(_,_,_,r,_) -> r
    | _ -> failwith "Appel get_registre_var pas sur un InfoVar/InfoStruct"

let%test _ = try get_registre_var (ref (InfoConst ("const", 42))) = "" with Failure _ -> true
let%test _ = get_registre_var (ref (InfoVar ("var", Rat, 5, "DB"))) = "DB"
let%test _ = try get_registre_var (ref (InfoFun ("fun", Pointeur Int, []))) = "" with Failure _ -> true
