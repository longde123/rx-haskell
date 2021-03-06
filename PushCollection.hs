{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses #-}

module PushCollection(observablePushCollection, newPushCollection, push) where

import Rx(Observable, Observer, toObservable, consume, Event(..))
import Data.IORef
import Control.Monad

data Subscription a = Subscription (Observer a) Int
instance Eq (Subscription q) where
  (==) (Subscription _ a) (Subscription _ b) = a == b 

data PushCollection a = PushCollection (IORef ([Subscription a], Int))

observablePushCollection :: PushCollection a -> Observable a
observablePushCollection collection = toObservable (subscribe collection)

subscribe (PushCollection ref) observer = do
    (observers, id) <- readIORef ref
    let subscription = Subscription observer id
    writeIORef ref $ (subscription : observers, id+1) 
    return (removeFromListRef ref subscription)

removeFromListRef ref subscriber = do
    (observers, id) <- readIORef ref
    writeIORef ref $ (filter (/= subscriber) observers, id)
  
newPushCollection :: IO (PushCollection.PushCollection a)
newPushCollection = liftM PushCollection (newIORef ([], 1))

push :: PushCollection a -> a -> IO ()
push (PushCollection listRef) item = do
    (observers, _) <- readIORef listRef
    mapM_  (applyTo item) observers
  where applyTo item (Subscription observer _) = consume observer . Next $ item
