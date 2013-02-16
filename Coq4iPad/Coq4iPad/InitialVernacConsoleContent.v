Theorem id : forall P, P -> P.
Proof.
intros P p.
apply p.
Qed.

Check id.

Inductive Tree := 
    Node : Tree -> Tree -> Tree
  | Leaf : Tree
.
 
Require Import ZArith.
