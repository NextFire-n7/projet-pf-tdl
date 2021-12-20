(* Module de la passe de gestion des identifiants *)
module PasseTdsRat :
  Passe.Passe
    with type t1 = Ast.AstSyntax.programme
     and type t2 = Ast.AstTds.programme = struct
  open Tds
  open Exceptions
  open Ast
  open AstTds
  open Type

  type t1 = Ast.AstSyntax.programme
  type t2 = Ast.AstTds.programme

  let rec analyse_tds_affectable tds modif a =
    match a with
    | AstSyntax.Deref a ->
        let naff = analyse_tds_affectable tds modif a in
        Deref naff
    | AstSyntax.Ident n -> (
        match chercherGlobalement tds n with
        | None -> raise (IdentifiantNonDeclare n)
        | Some ia -> (
            match info_ast_to_info ia with
            | InfoVar _ -> Ident ia
            | InfoConst _ ->
                if modif then raise (MauvaiseUtilisationIdentifiant n)
                else Ident ia
            | _ -> raise (MauvaiseUtilisationIdentifiant n)))

  let rec analyse_tds_type tds t =
    match t with
    | Pointeur t -> Pointeur (analyse_tds_type tds t)
    | NamedTyp n -> (
        match chercherGlobalement tds n with
        | None -> raise (TypeNonDeclare n)
        | Some ia -> (
            match info_ast_to_info ia with
            | InfoTyp (_, t) -> t
            | _ -> raise (MauvaiseUtilisationIdentifiant n)))
    | _ -> t

  (* analyse_tds_expression : AstSyntax.expression -> AstTds.expression *)
  (* Paramètre tds : la table des symboles courante *)
  (* Paramètre e : l'expression à analyser *)
  (* Vérifie la bonne utilisation des identifiants et tranforme l'expression
     en une expression de type AstTds.expression *)
  (* Erreur si mauvaise utilisation des identifiants *)
  let rec analyse_tds_expression tds e =
    match e with
    | AstSyntax.AppelFonction (name, el) -> (
        (* On cherche si la fonction est déjà définie *)
        match chercherGlobalement tds name with
        (* Ah ben non elle est pas def *)
        | None -> raise (IdentifiantNonDeclare name)
        | Some ia -> (
            (* Qqch porte bien ce nom, est-ce une fonction ? *)
            match info_ast_to_info ia with
            | InfoFun _ ->
                AppelFonction (ia, List.map (analyse_tds_expression tds) el)
            | _ -> raise (MauvaiseUtilisationIdentifiant name)))
    | AstSyntax.Affectable affectable ->
        Affectable (analyse_tds_affectable tds false affectable)
    | AstSyntax.Booleen value -> Booleen value
    | AstSyntax.Entier value -> Entier value
    | AstSyntax.Unaire (op, exp) -> Unaire (op, analyse_tds_expression tds exp)
    | AstSyntax.Binaire (op, exp1, exp2) ->
        Binaire
          (op, analyse_tds_expression tds exp1, analyse_tds_expression tds exp2)
    (* Pointeurs *)
    | AstSyntax.Null -> Null
    | AstSyntax.Adresse name -> (
        (* On cherche si la fonction est déjà définie *)
        match chercherGlobalement tds name with
        (* Ah ben non elle est pas def *)
        | None -> raise (IdentifiantNonDeclare name)
        | Some ia -> (
            (* Qqch porte bien ce nom, est-ce une fonction ? *)
            match info_ast_to_info ia with
            | InfoVar _ -> Adresse ia
            | _ -> raise (MauvaiseUtilisationIdentifiant name)))
    | AstSyntax.New typ -> New typ

  (* analyse_tds_instruction : AstSyntax.instruction -> tds -> AstTds.instruction *)
  (* Paramètre tds : la table des symboles courante *)
  (* Paramètre i : l'instruction à analyser *)
  (* Vérifie la bonne utilisation des identifiants et tranforme l'instruction
     en une instruction de type AstTds.instruction *)
  (* Erreur si mauvaise utilisation des identifiants *)
  let rec analyse_tds_instruction tds i =
    match i with
    | AstSyntax.Declaration (t, n, e) -> (
        match chercherLocalement tds n with
        | None ->
            (* L'identifiant n'est pas trouvé dans la tds locale,
               il n'a donc pas été déclaré dans le bloc courant *)
            (* Analyse du type *)
            let nt = analyse_tds_type tds t in
            (* Vérification de la bonne utilisation des identifiants dans l'expression *)
            (* et obtention de l'expression transformée *)
            let ne = analyse_tds_expression tds e in
            (* Création de l'information associée à l'identfiant *)
            let info = InfoVar (n, Undefined, 0, "") in
            (* Création du pointeur sur l'information *)
            let ia = info_to_info_ast info in
            (* Ajout de l'information (pointeur) dans la tds *)
            ajouter tds n ia;
            (* Renvoie de la nouvelle déclaration où le nom a été remplacé par l'information
               et l'expression remplacée par l'expression issue de l'analyse *)
            Declaration (nt, ia, ne)
        | Some _ ->
            (* L'identifiant est trouvé dans la tds locale,
               il a donc déjà été déclaré dans le bloc courant *)
            raise (DoubleDeclaration n))
    | AstSyntax.Affectation (aff, e) ->
        let naff = analyse_tds_affectable tds true aff in
        let ne = analyse_tds_expression tds e in
        Affectation (naff, ne)
    | AstSyntax.Constante (n, v) -> (
        match chercherLocalement tds n with
        | None ->
            (* L'identifiant n'est pas trouvé dans la tds locale,
               il n'a donc pas été déclaré dans le bloc courant *)
            (* Ajout dans la tds de la constante *)
            ajouter tds n (info_to_info_ast (InfoConst (n, v)));
            (* Suppression du noeud de déclaration des constantes devenu inutile *)
            Empty
        | Some _ ->
            (* L'identifiant est trouvé dans la tds locale,
               il a donc déjà été déclaré dans le bloc courant *)
            raise (DoubleDeclaration n))
    | AstSyntax.Affichage e ->
        (* Vérification de la bonne utilisation des identifiants dans l'expression *)
        (* et obtention de l'expression transformée *)
        let ne = analyse_tds_expression tds e in
        (* Renvoie du nouvel affichage où l'expression remplacée par l'expression issue de l'analyse *)
        Affichage ne
    | AstSyntax.Conditionnelle (c, t, e) ->
        (* Analyse de la condition *)
        let nc = analyse_tds_expression tds c in
        (* Analyse du bloc then *)
        let tast = analyse_tds_bloc tds t in
        (* Analyse du bloc else *)
        let east = analyse_tds_bloc tds e in
        (* Renvoie la nouvelle structure de la conditionnelle *)
        Conditionnelle (nc, tast, east)
    | AstSyntax.TantQue (c, b) ->
        (* Analyse de la condition *)
        let nc = analyse_tds_expression tds c in
        (* Analyse du bloc *)
        let bast = analyse_tds_bloc tds b in
        (* Renvoie la nouvelle structure de la boucle *)
        TantQue (nc, bast)
    | AstSyntax.Retour e ->
        (* Analyse de l'expression *)
        let ne = analyse_tds_expression tds e in
        Retour ne
    | AstSyntax.TypedefLocal (n, t) -> (
        (* Vérif double déclaration *)
        match chercherLocalement tds n with
        | Some _ -> raise (DoubleDeclaration n)
        | None ->
            (* Enregistrement du type nommé dans la tds *)
            let nt = analyse_tds_type tds t in
            let i = InfoTyp (n, nt) in
            let ia = info_to_info_ast i in
            ajouter tds n ia;
            (* Le noeud ne sert plus *)
            Empty)

  (* analyse_tds_bloc : AstSyntax.bloc -> AstTds.bloc *)
  (* Paramètre tds : la table des symboles courante *)
  (* Paramètre li : liste d'instructions à analyser *)
  (* Vérifie la bonne utilisation des identifiants et tranforme le bloc
     en un bloc de type AstTds.bloc *)
  (* Erreur si mauvaise utilisation des identifiants *)
  and analyse_tds_bloc tds li =
    (* Entrée dans un nouveau bloc, donc création d'une nouvelle tds locale
       pointant sur la table du bloc parent *)
    let tdsbloc = creerTDSFille tds in
    (* Analyse des instructions du bloc avec la tds du nouveau bloc
       Cette tds est modifiée par effet de bord *)
    let nli = List.map (analyse_tds_instruction tdsbloc) li in
    (* afficher_locale tdsbloc ; *)
    (* décommenter pour afficher la table locale *)
    nli

  (* analyse_tds_fonction : AstSyntax.fonction -> AstTds.fonction *)
  (* Paramètre tds : la table des symboles courante *)
  (* Paramètre : la fonction à analyser *)
  (* Vérifie la bonne utilisation des identifiants et tranforme la fonction
     en une fonction de type AstTds.fonction *)
  (* Erreur si mauvaise utilisation des identifiants *)
  let analyse_tds_fonction maintds (AstSyntax.Fonction (t, n, lp, li)) =
    match chercherLocalement maintds n with
    | None ->
        (* L'identifiant n'est pas trouvé dans la tds locale,
           il n'a donc pas été déclaré dans le bloc courant *)

        (* Création d'une nouvelle tds pour les paramètres locaux *)
        let tdsparam = creerTDSFille maintds in
        (* Création des informations liés aux paramètres, et ajout dans la tds *)
        let nlp =
          let nlp_inner_fun (t, n) =
            (* analyse du type du paramètre *)
            let nt = analyse_tds_type tdsparam t in
            let _ =
              (* On vérifie que la paramètre n'a pas été déclaré précédemment *)
              match chercherLocalement tdsparam n with
              | Some _ -> raise (DoubleDeclaration n)
              | None -> ()
            in
            let infovar = InfoVar (n, Undefined, 0, "") in
            let astvar = info_to_info_ast infovar in
            ajouter tdsparam n astvar;
            (nt, astvar)
          in
          List.map nlp_inner_fun lp
        in
        (* Création de l'information associée à l'identfiant *)
        let info = InfoFun (n, Undefined, List.map fst nlp) in
        (* Création du pointeur sur l'information *)
        let ia = info_to_info_ast info in
        (* Ajout du pointeur dans la TDS (pour la récursivité)*)
        let _ = ajouter maintds n ia in
        (* Vérification de la bonne utilisation des identifiants dans le bloc d'instructions *)
        (* et obtention du bloc transformé *)
        let nli = analyse_tds_bloc tdsparam li in
        (* Renvoie de la nouvelle fonction où les informations liés
           à la fonction et ses paramètres ont été ajoutés à la tds*)
        (* analyse du type du return *)
        let nt = analyse_tds_type tdsparam t in
        Fonction (nt, ia, nlp, nli)
    | Some _ ->
        (* L'identifiant est trouvé dans la tds locale,
           il a donc déjà été déclaré dans le bloc courant *)
        raise (DoubleDeclaration n)

  (* analyser : AstSyntax.ast -> AstTds.ast *)
  (* Paramètre : le programme à analyser *)
  (* Vérifie la bonne utilisation des identifiants et tranforme le programme
     en un programme de type AstTds.ast *)
  (* Erreur si mauvaise utilisation des identifiants *)
  let analyser (AstSyntax.Programme (typedefs, fonctions, prog)) =
    let tds = creerTDSMere () in
    (* rajout des types nommés en haut de la tds *)
    let _ =
      List.map
        (fun (AstSyntax.TypedefGlobal (n, t)) ->
          match chercherGlobalement tds n with
          | Some _ -> raise (DoubleDeclaration n)
          | None ->
              (* Résolution du type de base *)
              let nt = analyse_tds_type tds t in
              let i = InfoTyp (n, nt) in
              let ia = info_to_info_ast i in
              ajouter tds n ia)
        typedefs
    in
    let nf = List.map (analyse_tds_fonction tds) fonctions in
    let nb = analyse_tds_bloc tds prog in
    Programme (nf, nb)
end
