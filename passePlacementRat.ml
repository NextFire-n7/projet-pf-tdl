module PassePlacementRat :
  Passe.Passe
    with type t1 = Ast.AstType.programme
     and type t2 = Ast.AstPlacement.programme = struct
  open Tds
  open Exceptions
  open Ast
  open AstPlacement
  open Type

  type t1 = Ast.AstType.programme

  type t2 = Ast.AstPlacement.programme

  (* analyse_placement_instruction : string -> int -> AstType.instruction -> int *)
  (* Paramètre reg: le registre mémoire *)
  (* Paramètre dep: la profondeur actuelle dans le registre *)
  (* Paramètre i: l'instruction à analyser *)
  (* Réserve dans le registre la place nécéssaire aux variables déclarée
     et analyse les bloc des structures de contrôle *)
  (* Renvoie la nouvelle position dans le registre *)
  let rec analyse_placement_instruction reg dep i =
    (* On récupère l'incrément de profondeur lié à l'instruction *)
    let inc =
      match i with
      (* Déclaration: il faut réserver la place de la nouvelle variable *)
      | AstType.Declaration (ia, _) ->
          (* Place la variable à l'adresse dep du registre reg *)
          modifier_adresse_info dep reg ia;
          (* renvoie la taille du type déclaré *)
          getTaille (get_type ia)
      | AstType.Conditionnelle (_, bt, be) ->
          (* On analyse les deux blocs, la conditionnelle en tant que telle
             ne consomme aucun espace mémoire à la fin *)
          analyse_placement_bloc reg dep bt;
          analyse_placement_bloc reg dep be;
          0
      | AstType.TantQue (_, b) ->
          (* De même avec le tant que *)
          analyse_placement_bloc reg dep b;
          0
      | _ -> 0
    in
    (* nouvelle profondeur (pour la prochaine déclaration) *)
    dep + inc

  (* analyse_placement_params: int -> info_ast list -> unit = <fun> *)
  (* Place les paramètres en mémoire par effet de bord.
     Params:
       - reg: string = le nom du registre mémoire dans lequel stocker les variables
       - dep: int = le déplacement de base dans notre registre
       - li: instruction list = la liste des instructions dont on va gérer la placement mémoire
     Retour: unit *)
  and analyse_placement_bloc reg dep li =
    match li with
    | [] -> ()
    | i :: q ->
        (* On gère le placement mémoire de l'instruction et on récupère le nouveau déplacement *)
        let ndep = analyse_placement_instruction reg dep i in
        (* On analyse le reste du bloc avec ce nouveau déplacement *)
        analyse_placement_bloc reg ndep q

  (* analyse_placement_fonction: AstType.Fonction -> AstPlacement.Fonction = <fun> *)
  (* Par effet de bord, gère le placement mémoire des paramètres et des variables du bloc de la fonction *)
  let rec analyse_placement_fonction (AstType.Fonction (ia, liap, li)) =
    analyse_placement_params 0 (List.rev liap);
    analyse_placement_bloc "LB" 3 li;
    Fonction (ia, liap, li)

  (* analyse_placement_params: int -> info_ast list -> unit = <fun> *)
  (* Place les paramètres en mémoire par effet de bord.
     Params:
        - dep: int = le déplacement de base de notre paramètre
        - lp: info_ast list = la liste des paramètres à placer dans la mémoire
     Retour: unit *)
  and analyse_placement_params dep lp =
    match lp with
    | [] -> ()
    | ia :: q ->
        let t = getTaille (get_type ia) in
        modifier_adresse_info (dep - t) "LB" ia;
        analyse_placement_params (dep - t) q

  (* analyser : AstType.Programme -> AstPlacement.Programme *)
  (* Paramètre : le programme à analyser *)
  let analyser (AstType.Programme (fonctions, prog)) =
    let nf = List.map analyse_placement_fonction fonctions in
    analyse_placement_bloc "SB" 0 prog;
    Programme (nf, prog)
end
