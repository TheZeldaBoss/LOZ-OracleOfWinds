-- Sets up all non built-in gameplay features specific to this quest.

-- Usage: require("scripts/features")

-- Features can be enabled to disabled independently by commenting
-- or uncommenting lines below.

sol.features = {}

require("scripts/meta/hero")
require("scripts/hud/hud")
require("enemies/movement_generic")
require("enemies/enemy_generic")

return true
