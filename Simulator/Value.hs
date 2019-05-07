
module Simulator.Value where

import Simulator.Util

import qualified Target as T

import qualified Data.Vector as V

import System.Random (randomRIO)

data Val = BoolVal Bool | BitvectorVal [Bool] | StructVal [(String,Val)] | ArrayVal (V.Vector Val) deriving (Eq)

-- unit val
tt :: Val
tt = BitvectorVal []

boolCoerce :: Val -> Bool
boolCoerce (BoolVal b) = b
boolCoerce _ = error "Encountered a non-boolean value when a boolean was expected."

bvCoerce :: Val -> [Bool]
bvCoerce (BitvectorVal bs) = bs
bvCoerce _ = error "Encountered a non-bitvector value when a bitvector was expected."

structCoerce :: Val -> [(String,Val)]
structCoerce (StructVal fields) = fields
structCoerce _ = error "Encountered a non-struct value when a struct was expected."

arrayCoerce :: Val -> V.Vector Val
arrayCoerce (ArrayVal vs) = vs
arrayCoerce _ = error "Encountered a non-array value when an array was expected."

struct_field_access :: String -> Val -> Val
struct_field_access fieldName v =
    case lookup fieldName $ structCoerce v of
        Just v' -> v'
        _ -> error $ "Field " ++ fieldName ++ " not found."

randVal :: T.Kind -> IO Val
randVal T.Bool = do
    k <- randomRIO (0,1)
    return $ BoolVal $ k == (1 :: Int)
randVal (T.Bit n) = do
    k <- randomRIO (0, 2^n - 1)
    return $ BitvectorVal $ list_of_int n k
randVal (T.Struct n ks names) = do
    let ks' = map ks (T.getFins n)
    let names' = map names (T.getFins n)
    vs <- mapM randVal ks'
    return $ StructVal $ zip names' vs
randVal (T.Array n k) = do
    vs <- V.mapM randVal (V.replicate n k)
    return $ ArrayVal vs

randVal_FK :: T.FullKind -> IO Val
randVal_FK (T.SyntaxKind k) = randVal k
randVal_FK (T.NativeKind) = error "Encountered a NativeKind."