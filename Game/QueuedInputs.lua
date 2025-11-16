-- QueuedInputs module.
local QueuedInputs = {}

-- This module will have two actions (Dodge + Block) which will be processed seperately.
-- These will all be queued up and executed in order.

-- BLOCK QUEUE --
-- Simply store block start entries with a dead time.
-- When the block start dead time is reached, we kill it.
-- As long as we have one block start queued, we will step through the normal blocking routine.
-- Else, we stop blocking as long as we have the blocking effect.
-- If not, we do nothing.

-- DODGE QUEUE --
