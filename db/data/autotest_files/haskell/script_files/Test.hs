module Test where
import Test.QuickCheck (Property, (==>))
import Submission (celsiusToFarenheit, nCopies, numEvens, numManyEvens)
import qualified Submission as Soln (celsiusToFarenheit, nCopies, numEvens, numManyEvens)

prop_celsius0 :: Bool
prop_celsius0 =
    celsiusToFarenheit 0 == 32

prop_celsius37 :: Bool
prop_celsius37 =
    celsiusToFarenheit 37 == 99


prop_nCopiesLength :: [Char] -> Int -> Property
prop_nCopiesLength s n =
    n >= 0 ==> (length (nCopies s n) == (length s) * n)


prop_numEvensLength :: [Int] -> Bool
prop_numEvensLength nums =
    numEvens nums <= length nums


-- | What do you think this property says?
prop_numManyEvensDoubled :: [[Int]] -> Bool
prop_numManyEvensDoubled listsOfNums =
    let doubled = listsOfNums ++ listsOfNums
    in
        numManyEvens doubled == 2 * (numManyEvens listsOfNums)


prop_celsiusAgainstReference :: Float -> Bool
prop_celsiusAgainstReference x = celsiusToFarenheit x == Soln.celsiusToFarenheit x


prop_nCopiesAgainstReference :: [Char] -> Int -> Property
prop_nCopiesAgainstReference s x =
    x >= 0 ==> nCopies s x == Soln.nCopies s x


prop_numEvensAgainstReference :: [Int] -> Bool
prop_numEvensAgainstReference x = numEvens x == Soln.numEvens x


prop_numManyEvensAgainstReference :: [[Int]] -> Bool
prop_numManyEvensAgainstReference x = numManyEvens x == Soln.numManyEvens x


-- main :: IO ()
-- main = do
  -- quickCheck prop_celsius0
  -- quickCheck prop_celsius37
  -- quickCheck prop_nCopiesLength
  -- quickCheck prop_numEvensLength
  -- quickCheck prop_numManyEvensDoubled
  -- quickCheck prop_celsiusAgainstReference
  -- quickCheck prop_nCopiesAgainstReference
  -- quickCheck prop_numEvensAgainstReference
  -- quickCheck prop_numManyEvensAgainstReference
