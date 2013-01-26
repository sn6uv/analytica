InductionVariables := {};

TryInduction[s_] := 
	TryInductionOn[s, VariablesIn[s]];

TryInductionOn[s_, {}] = False;

TryInductionOn[s_, {x_, rest___}] :=
	orelse[SucceedWith[InductionOn[x, DeriveInductScheme[x, s]]], 
	       TryInductionOn[s, {rest}]];

InductionOn[x_, {}] := False;

InductionOn[x_, {-Infinity, {main_, others_}}] := False;

InductionOn[x_, {n_, {main_, others_}}] := Block[{temp}, (


	If[!FreeQ[InductionVariables, x], Return[False]];

	temp = EvaluateAssuming[And[n<=x, integer[x]], WeakSimplify[main]];

	AppendTo[InductionVariables, x];

	print["prove"];

	PrintSequent[temp];

	print["by induction on ", ToString[x], "\n"];

	print["base case with ", ToString[x], " = ", ToString[n]];

	(* if one of the bases fails, return with fail *)

	If[FalseQ[Verify[Or[others, temp /. x -> n]]], 

		PrintResult["RESULT", Fail];
		InductionVariables = Drop[InductionVariables, -1];
		Return[False]];

	(* the induction steps *)
	
	print["induction step"];
	temp = Verify[Or[others, seq[And[integer[x], n<=x, temp], temp/.x->x+1]]];
	InductionVariables = Drop[InductionVariables, -1];
	Return[temp];
)];


DeriveInductScheme[x_, f_] :=
	{GetBase[x, f], SeperateMain[x, f, {False, False}]};

SeperateMain[x_, seq[True, Or[a_, b__]], {main_, others_}] := 
	If[FreeQ[a, x],
	   SeperateMain[x, seq[True, Or[b]], {main, Or[others, a]}],
	   SeperateMain[x, seq[True, Or[b]], {Or[a, main], others}]];

SeperateMain[x_, seq[True, c_], {main_, others_}] := 
	If[FreeQ[c, x],
	   {main, Or[others, c]},
	   {Or[c, main], others}];

SeperateMain[x_, seq[And[a_, b__], c_], {main_, others_}] := 
	If[FreeQ[a, x],
	   SeperateMain[x, seq[And[b], c], {main, seq[a, others]}],
	   SeperateMain[x, seq[And[b], c], {seq[a, main], others}]];

SeperateMain[x_, seq[h_, c_], {main_, others_}] := 
	If[FreeQ[h, x],
	   SeperateMain[x, seq[True, c], {main, seq[h, others]}],
	   SeperateMain[x, seq[True, c], {seq[h, main], others}]];

SeperateMain[x_, a_, {main_, others_}] := 
	If[FreeQ[a, x],
	   {main, Or[others, a]},
	   {Or[a, main], others}];

GetBase[x_, f_] :=
	EvaluateAssuming[Not[f], 
	  If[!TrueQ[WeakSimplify[integer[x]]] 
	       || !useful[x, f, StrongSimplify[f/.x->x+1]], 
	     -Infinity,
	     SelectBase[Lower[x]]]];

	
useful[x_, f1_, seq[h_, c_]] := useful[x, seq[h, f1], c];

useful[x_, f1_, Or[a_, b__]] := useful[x, f1, a] && useful[x, f2, Or[b]];

useful[x_, f1_, And[a_, b__]] := useful[x, f1, a] && useful[x, f2, And[b]];

useful[x_, f1_, imp[a_, b_]] := useful[x, f1, a] && useful[x, f1, b];

useful[x_, f1_, a_ <= b_] := useful[x, f1, a] && useful[x, f1, b];

useful[x_, f1_, a_ < b_] := useful[x, f1, a] && useful[x, f1, b];

useful[x_, f1_, a_ == b_] := useful[x, f1, a] && useful[x, f1, b];

useful[x_, f1_, a_ + b_] := useful[x, f1, a] && useful[x, f1, b];

useful[x_, f1_, a_ b_] := useful[x, f1, a] && useful[x, f1, b];

useful[x_, f1_, a_^b_] := useful[x, f1, a] && useful[x, f1, b];

useful[x_, f1_, f2_] := FreeQ[f2, x] || PolynomialQ[f2, x] || !FreeQ[f1, f2];


SelectBase[{S[a_], b___}] := SelectBase[{a, b}];

SelectBase[{a_?NumberQ, b___}] := 
	Max[Ceiling[a], SelectBase[{b}]];

SelectBase[{a_, b___}] := 
	SelectBase[{b}];

SelectBase[{}] := -Infinity;

