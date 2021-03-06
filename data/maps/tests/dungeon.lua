-- Lua script of map tests/dungeon.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
gen.import(map, mpg, "init_dungeon_features")
-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  map:init_dungeon_features()
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
