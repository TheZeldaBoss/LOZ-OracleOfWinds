local game

--====== INIT DIALOG_BOX =======
local dialog_box = {

  -- Dialog box properties.
  dialog = nil,                -- Dialog being displayed or nil.
  first = true,                -- Whether this is the first dialog of a sequence.
  style = nil,                 -- "box" or "empty".
  vertical_position = "auto",  -- "auto", "top" or "bottom".
  skip_mode = nil,             -- "none", "current", "all" or "unchanged".
  icon_index = nil,            -- Index of the 16x16 icon in hud/dialog_icons.png or nil.
  info = nil,                  -- Parameter passed to start_dialog().
  skipped = false,             -- Whether the player skipped the dialog.
  selected_answer = nil,       -- Selected answer (1 or 2) or nil if there is no question.
  next = nil,

  -- Displaying text gradually.
  current_line = nil,             -- Next line to display or nil.
  next_line = nil,
  new_lines = 0,
  line_it = nil,               -- Iterator over of all lines of the dialog.
  line_surfaces = {},          -- Array of the 3 text surfaces.
  line_index = nil,            -- Line currently being shown.
  char_index = nil,            -- Next character to show in the current line.
  char_delay = nil,            -- Delay between two characters in milliseconds.
  full = false,                -- Whether the 3 visible lines have shown all content.
  need_letter_sound = false,   -- Whether a sound should be played with the next character.
  gradual = true,              -- Whether text is displayed gradually.

  -- Graphics.
  surface = nil,
  box_surface = nil,
  icons_img = nil,
  end_arrow = nil,
  arrow_timer = nil,
  draw_arrow = false,
  box_position = {x = 0, y = 0},      -- Destination coordinates of the dialog box.
  question_dst_position = nil, -- Destination coordinates of the question icon.
  icon_dst_position = nil,     -- Destination coordinates of the icon.
  font = "oracle",
  font_size = 9,
  text_color = { 248, 208, 136 } -- Text color.

}


-- Constants.
local nb_visible_lines = 2     -- Maximum number of lines in the dialog box.
local char_delays = {          -- Delay before displaying the next character.
  slow = 60,
  medium = 40,
  fast = 20  -- Default.
}
local letter_sound_delay = 100
local box_size = {w = 144, h = 40}
local arrow_pos = {x = 136, y = 33}
local line_spacing = 16
local text_pos = {} -- Text position relative to the box
local line_transition_speed = 64

function text_pos:reset()
  self.x = 9
  self.y = 6
end


-- Initialize dialog box data.
--dialog_box.font, dialog_box.font_size = language_manager:get_dialog_font()
for i = 1, nb_visible_lines do
  dialog_box.line_surfaces[i] = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "top",
    font = dialog_box.font,
    font_size = dialog_box.font_size,
    color = dialog_box.text_color
  }
end

dialog_box.surface = sol.surface.create(sol.video.get_quest_size())
dialog_box.box_surface = sol.surface.create(box_size.w, box_size.h)
dialog_box.end_arrow = sol.surface.create("menus/dialog.png")

--dialog_box.box_img = sol.surface.create("hud/dialog_box.png")
--dialog_box.icons_img = sol.surface.create("hud/dialog_icons.png")
--dialog_box.end_lines_sprite = sol.sprite.create("hud/dialog_box_message_end")

--====== DIALOG MENU CALLBACKS ======

function dialog_box:on_started()
  --debug
  --print(dialog_box.dialog.text)
  self.char_delay = char_delays["fast"] -- à remplacer par une vraie sélection de la vitesse (settings ?)
  self.box_position:set(8, 96) --à remplacer par un vrai calcul de la position de la box en fonction de celle du joeur

  local map = game:get_map()
  local _, camera_y, _, camera_height = map:get_camera():get_bounding_box()
  local hero = map:get_entity("hero")
  if hero:is_enabled() and hero:is_visible() then
    local _, hero_y = hero:get_position()
    if hero_y - camera_y > camera_height - 56 then
      self.box_position:set(8, 24)
    end
  end

  self:show_dialog()
end

function dialog_box:on_finished()
  game:set_custom_command_effect("action", nil)
  game:stop_dialog()
end

function dialog_box:on_draw(dst_surface)
  local x, y = self.box_position:get()
  self.box_surface:fill_color({0, 0, 0})

  if self:is_full() and self.draw_arrow then
    self.end_arrow:draw(self.box_surface, arrow_pos.x, arrow_pos.y)
  end
  
  local text_y = text_pos.y
  local text_x = text_pos.x
  for i = 1, nb_visible_lines do
    self.line_surfaces[i]:draw(self.box_surface, text_x, text_y)
    text_y = text_y + line_spacing
  end
  
  self.box_surface:draw(self.surface, x, y)
  self.surface:draw(dst_surface)
end

function dialog_box:on_command_pressed(command)
  if command == "action" and dialog_box:is_full() then
    dialog_box:advance()
  end
end

--====== DIALOG MENU FUNCTIONS ======

function dialog_box:quit()
  if sol.menu.is_started(self) then
    sol.menu.stop(self)
  end
end

function dialog_box.box_position:get()
  return self.x, self.y
end

function dialog_box.box_position:set(x, y)
  self.x = x
  self.y = y
end

function dialog_box:is_line_full()
  return self.char_index > #self.current_line
end

-- Updates the result of is_full().
function dialog_box:check_full()
  if self.new_lines > 1 or 
   not self:has_more_lines() then
    self.full = true
  else
    self.full = false
  end
end

function dialog_box:is_full()
  return self.full
end

function dialog_box:start_arrow_blinking()
  self.draw_arrow = true
  self.arrow_timer = sol.timer.start(self, 500, function()
    dialog_box.draw_arrow = not dialog_box.draw_arrow
    return true
  end)
end

function dialog_box:stop_arrow_blinking()
  self.draw_arrow = false
  self.arrow_timer:stop()
end

function dialog_box:show_dialog()
-- Initialize this dialog.
  local dialog = self.dialog

  local text = dialog.text
  if dialog_box.info ~= nil then
    -- There is a "$v" sequence to substitute.
    text = text:gsub("%$v", dialog_box.info)
  end
  -- Split the text in lines.
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  self.line_it = text:gmatch("([^\n]*)\n")  -- Each line including empty ones.
  self.next_line = self.line_it()
  self.line_index = 0
  
  for i = 1, nb_visible_lines do
    self.line_surfaces[i]:set_text("")
  end
  
  self:advance()
end

function dialog_box:advance()
  self.new_lines = 0
  if self:has_more_lines() then
    self:pre_next_line()
  else
    self:show_next_dialog()
  end
end

function dialog_box:pre_next_line()
  self:check_full()
  if self:is_full() then
    self:start_arrow_blinking()
    return --on ne fait rien : on laisse la suite à :advance(), call par le callback on_command_pressed
  end

  if self.line_index > 1 then
    self:start_next_line_animation()
    return
  end  

  self.line_index = self.line_index + 1   
  self:start_next_line()
end

function dialog_box:start_next_line()
  text_pos:reset()

  self.current_line = self.next_line
  self.next_line = self.line_it()  

  self.new_lines = self.new_lines + 1

  self.char_index = 1
  self:show_next_char()
end

function dialog_box:start_next_line_animation()
  local line_movement = sol.movement.create("straight")
  line_movement:set_speed(line_transition_speed)
  line_movement:set_angle(math.pi / 2)
  line_movement.dbox = dialog_box
  line_movement:set_max_distance(16)
  function line_movement:on_finished()
    self.dbox.line_surfaces[1]:set_text( self.dbox.line_surfaces[2]:get_text() )
    self.dbox.line_surfaces[2]:set_text("")
    self.dbox:start_next_line()
  end

  line_movement:start(text_pos)
end

function dialog_box:show_next_char()
  local current_char = self.current_line:sub(self.char_index, self.char_index)
  local tsurface = self.line_surfaces[self.line_index]

  tsurface:set_text(tsurface:get_text()..current_char)
  self.char_index = self.char_index + 1
  if self:is_line_full() then
    self:pre_next_line()
  else
    sol.timer.start(self, self.char_delay, function() self:show_next_char() end)
  end
end

function dialog_box:show_next_dialog()
  if self.next_dialog then
    dialog_box.dialog = dialog
    dialog_box.info = info 
    self:show_dialog()
  else
    self:quit()
  end
end

function dialog_box:has_more_lines()
  return self.next_line ~= nil
end


--====== BINDING THE DIALOG TO THE GAME ======

local function dialog_start_callback(game, dialog, info)
  dialog_box.dialog = dialog
  dialog_box.info = info
  sol.menu.start(game, dialog_box)
end

local function get_dialog_box(game)
  return dialog_box
end

local function bind_to_game(game_)
  game = game_
  game:register_event("on_dialog_started", dialog_start_callback)
  game.get_dialog_box = get_dialog_box
end


--When the game starts, binds everything to it.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", bind_to_game)