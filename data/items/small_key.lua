local item = ...

function item:on_created()

  self:set_shadow("small")
  self:set_brandish_when_picked(true)
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("picked_small_key")
end

function item:on_obtaining(variant, savegame_variable)

end

