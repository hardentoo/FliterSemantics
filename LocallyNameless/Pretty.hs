{-# LANGUAGE ParallelListComp, FlexibleInstances #-}
module Pretty where

import Control.Arrow (first)
import Text.PrettyPrint.HughesPJ

import Syntax

varSupply = [ c : i | i <- "" : map show [0..], c <- "xyz"]

prettyOp Pl = text "+"
prettyOp Mi = text "-"
prettyOp Eq = text "=="
prettyOp Ne = text "/="
prettyOp Le = text "<="
prettyOp Seq = text "`seq`"

zipDrop :: [a] -> [b] -> ([(a, b)], [a])
zipDrop xs [] = ([], xs)
zipDrop (x:xs) (y:ys) = first ((x, y):) $ zipDrop xs ys

prettyVar (Fre v) = text v
prettyVar (Bnd i) = text $ '#' : show i

prettyExpr :: [String] -> Expr String -> Doc
prettyExpr fresh (Var v)     = prettyVar v
prettyExpr fresh (Fun f [])  = text $ 'f' : show f
prettyExpr fresh (Fun f vs)  = prettyExpr fresh $ Fun f [] :@ map Fre vs
prettyExpr fresh (Con c [])  = text $ c
prettyExpr fresh (Con c vs)  = prettyExpr fresh $ Con c [] :@ map Fre vs
prettyExpr fresh (PVa n)     = text $ show n
prettyExpr fresh (POp o v w) = hsep [prettyVar v, prettyOp o, prettyVar w]
prettyExpr fresh (x :@ vs)   = hsep (prettyExpr fresh x : map prettyVar vs)
prettyExpr fresh (Let xs y)  =  hang (text "let") 4 (vcat [ hsep [ text v, text "="
                                                                 , prettyExpr fresh x]
                                                            | (v, x) <- bs])
                               $$ hang (text "in")  3 (prettyExpr fresh' $ instantiate' vs y)
  where (bs, fresh') = zipDrop fresh xs
        vs = map fst bs
prettyExpr fresh (Case x as)   =  hang (text "case") 5  (prettyExpr fresh x) <+> text "of"
                               $$ (nest 2 . vcat) (map (prettyAlte fresh) as)
                               
prettyAlte :: [String] -> Alte String -> Doc
prettyAlte fresh ((c, novs) :-> y)
  = text c <+> text (unwords vs) <+> text "->" <+>
    (prettyExpr fresh' $ instantiate' vs y)
  where (vs, fresh') = splitAt novs fresh
                               
prettyFunc :: Func String -> Doc
prettyFunc (Lam novs x) = text "\\" <+> text (unwords vs) <+> text "->" <+>
                          prettyExpr fresh (instantiate' vs x)
  where (vs, fresh) = splitAt novs varSupply
        
prettyProg :: Prog String -> Doc
prettyProg (Prog p) = vcat [ text ('f' : show i) <+> text (unwords vs) <+> text "=" <+>
                             prettyExpr fresh (instantiate' vs x)
                           | Lam novs x <- p
                           , let (vs, fresh) = splitAt novs varSupply 
                           | i <- [0..] ]

wrap x = "[" ++ show x ++ "]"

instance Show a => Show (Prog a) where
  show = render . prettyProg . fmap wrap
  
instance Show a => Show (Func a) where
  show = render . prettyFunc . fmap wrap
  
instance Show a => Show (Expr a) where
  show = render . prettyExpr varSupply . fmap wrap
  
instance Show a => Show (Alte a) where
  show = render . prettyAlte varSupply . fmap wrap