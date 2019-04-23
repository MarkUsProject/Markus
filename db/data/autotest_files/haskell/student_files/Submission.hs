
module Submission (celsiusToFarenheit, nCopies, numEvens, numManyEvens) where

import Test.QuickCheck (Property, quickCheck, (==>))


celsiusToFarenheit :: Float -> Int
celsiusToFarenheit temp =
    32 + round ((9.0/5.0) * temp)

prop_celsius0 :: Bool
prop_celsius0 =
    celsiusToFarenheit 0 == 32

prop_celsius37 :: Bool
prop_celsius37 =
    celsiusToFarenheit 37 == 99

-------------------------------------------------------------------------------


nCopies :: String -> Int -> String
nCopies _ 0 = ""
nCopies s n = s ++ nCopies s (n - 1)


prop_nCopiesLength :: [Char] -> Int -> Property
prop_nCopiesLength s n =
    n >= 0 ==> (length (nCopies s n) == (length s) * n)

-------------------------------------------------------------------------------


numEvens :: [Int] -> Int
numEvens numbers =
    if null numbers
    then
        0
    else
        let firstNumber = head numbers
            numEvensInRest = numEvens (tail numbers)
        in
            if firstNumber `mod` 2 == 0
            then
                1 + numEvensInRest
            else
                numEvensInRest


numManyEvens :: [[Int]] -> Int
numManyEvens [] = 0
numManyEvens (firstList : rest) =
    let numManyEvensInRest = numManyEvens rest
    in
        if numEvens firstList >= 3
        then
            1 + numManyEvensInRest
        else
            numManyEvensInRest


prop_numEvensLength :: [Int] -> Bool
prop_numEvensLength nums =
    numEvens nums <= length nums


prop_numManyEvensDoubled :: [[Int]] -> Bool
prop_numManyEvensDoubled listsOfNums =
    let doubled = listsOfNums ++ listsOfNums
    in
        numManyEvens doubled == 2 * (numManyEvens listsOfNums)

-------------------------------------------------------------------------------

main :: IO ()
main = do
    quickCheck prop_celsius0
    quickCheck prop_celsius37
    quickCheck prop_nCopiesLength
    quickCheck prop_numEvensLength
    quickCheck prop_numManyEvensDoubled