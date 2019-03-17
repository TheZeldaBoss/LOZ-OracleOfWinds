local item = ...

function item:on_created()

  self:set_shadow("small")
  self:set_brandish_when_picked(true)
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("picked_small_key")
  self:set_amount_savegame_variable("small_keys")
  
end

function item:on_obtained()
  self:add_amount(1)
end