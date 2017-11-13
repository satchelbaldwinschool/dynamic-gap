{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.Maybe
import GHC.IO.Handle
import ReadArgs
import System.Environment
import System.IO
import System.Process

type Padding = [Int]

main :: IO ()
main = do
    (gap :: Int, top :: Int, left :: Int, right :: Int, bottom :: Int, slope :: Maybe Float) <-
        readArgs
    (_, Just hout, _, _) <-
        createProcess (proc "bspc" ["subscribe", "all"]) {std_out = CreatePipe}
    setBorder gap [top, left, right, bottom] (fromMaybe 2.0 slope)
    forever $
        hGetLine hout >>=
        (handleEvent gap [top, left, right, bottom] (fromMaybe 2.0 slope))
  where
    handleEvent gap padding slope event =
        when
            (isNodeEvent event || isDesktopEvent event)
            (setBorder gap padding slope)

paddingSides :: [String]
paddingSides = ["top", "left", "right", "bottom"]

getNodes :: IO [String]
getNodes = lines . either (const "") id <$> result
  where
    result :: IO (Either IOError String)
    result = try $ readProcess "bspc" ["query", "-d", "focused", "-N"] ""

getVisibleCount :: [String] -> Int
getVisibleCount nodes = quot (length nodes) 2 + 1

windowGap :: Int -> Float -> Int -> Int
windowGap _ _ 1 = 0
windowGap target slope nodes = floor slope * fromIntegral target `quot` nodes

windowPadding :: Padding -> Int -> Padding
windowPadding target gap = map (\x -> x - gap) target

setBorder :: Int -> Padding -> Float -> IO ()
setBorder target padding slope = do
    gapValue <- windowGap target slope <$> (getVisibleCount <$> getNodes)
    let paddingValues = windowPadding padding gapValue
    zipWithM_ setPadding paddingSides paddingValues
    callCommand $ "bspc config window_gap " ++ show gapValue
  where
    setPadding :: String -> Int -> IO ThreadId
    setPadding side value =
        forkIO $
        callCommand $ "bspc config " ++ show side ++ "_padding " ++ show value

matchFirst s n = take (length n) s == n

isNodeEvent s = matchFirst s "node_manage" || matchFirst s "node_unmanage"

isDesktopEvent s = matchFirst s "desktop_focus"
