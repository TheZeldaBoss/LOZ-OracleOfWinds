-- Initialize hero behavior specific to this quest.

local hero_meta = sol.main.get_metatable("hero")

local function initialize_hero_features(game)

  local hero = game:get_hero()
  
  local hero_sprite = hero:get_sprite("tunic")
  
  hero.get_corner_position = eg.get_corner_position
  
  --Méthodes / Callbacks
  function hero:start_hurt_oow(damage, knockback_angle, knockback_distance)
    
    if hero.on_taking_damage then
     handled = hero:on_taking_damage(damage)
    end  
    if (not handled) and damage then hero:remove_life(damage) end
 
    sol.audio.play_sound("hero_hurt")
    hero:set_invincible(true, 2000)
    sprite:set_animation("hurt")
    hero:set_blinking(true, 2000)
    
    local m = sol.movement.create("straight")
    m:set_angle(knockback_angle)
    m:set_speed(120)
    m:set_max_distance(knockback_distance)
    function m:on_obstacle_reached()
      m.finished = true
      if m.timer_end then
        hero:unfreeze()
      end
    end

    hero:freeze()
    sol.timer.start(hero, 200, function()
      m.timer_end = true
      
    end)

    m:start(hero)
  end

  hero.is_on_nonsolid_ground = false
  
  function hero:on_position_changed()   
    hero.is_on_nonsolid_ground = false
  end


  function hero:start_jumping_oow(dir, dist)
    dir = dir % 8
    if not hero:get_map().is_side_view then
      hero:start_jumping(dir, dist)
      return true
    end

    if dir == 2 or dir == 6 then
     -- return false
    end

    if not self.pObject or not self.pObject.on_ground then return false end

    self.pObject.speed = -4
    print(self.pObject.on_ground)
  end

  function hero:on_state_changed(s)
    local map = game:get_map()
    if not map then return false end
    
    s = s:gsub(" ", "_")
    for e in map:get_entities() do
      if e["on_hero_state_" .. s] then
        e["on_hero_state_" .. s](e, hero)
      end
    end  
    if s == "plunging" then
      if self.pObject then self.pObject:freeze() end
      hero_sprite:set_animation("plunging_water", function()
        hero:set_position(hero:get_solid_ground_position())
        hero:start_hurt(1)
        if hero.pObject then hero.pObject:unfreeze() end
      end)
    elseif s == "sword_tapping" then
     local m = sol.movement.create("straight")
     m:set_speed(100)
     m:set_angle(hero_sprite:get_direction() * (math.pi / 2))
     m:set_max_distance(2)
     m:start(self)
     --sol.audio.play_sound("sword_tapping")
    end

  end

end

local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_hero_features)
return true
