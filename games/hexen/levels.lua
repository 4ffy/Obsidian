------------------------------------------------------------------------
--  HEXEN LEVELS
------------------------------------------------------------------------
--
--  Copyright (C) 2006-2011 Andrew Apted
--  Copyright (C) 2011-2012 Jared Blackburn
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2,
--  of the License, or (at your option) any later version.
--
------------------------------------------------------------------------

HEXEN.SECRET_EXITS =
{
}

HEXEN.EPISODES =
{
  episode1 =
  {
    ep_index = 1,

    theme = "forest",
    sky_light = 0.65,
  },

  episode2 =
  {
    ep_index = 2,

    theme = "village",
    sky_light = 0.75,
  },

  episode3 =
  {
    ep_index = 3,

    theme = "steel",
    sky_light = 0.65,
  },

  episode4 =
  {
    ep_index = 4,

    theme = "dungeon",
    sky_light = 0.60,
  },

  episode5 =
  {
    ep_index = 5,

    theme = "swamp",
    sky_light = 0.50,
  },
}


HEXEN.PREBUILT_LEVELS =
{
}


function HEXEN.get_levels()
  local MAP_LEN_TAB = { few=4, episode=6, game=30 }

  local MAP_NUM = MAP_LEN_TAB[OB_CONFIG.length] or 1

  local EP_NUM = 1
  if MAP_NUM > 6 then EP_NUM = 2 end
  if MAP_NUM > 12 then EP_NUM = 3 end
  if MAP_NUM > 18 then EP_NUM = 4 end
  if MAP_NUM > 24 then EP_NUM = 5 end

  -- create episode info...

  for ep_index = 1,5 do
    local ep_info = HEXEN.EPISODES["episode" .. ep_index]
    assert(ep_info)

    local EPI = table.copy(ep_info)

    EPI.levels = { }

    table.insert(GAME.episodes, EPI)
  end

  -- create level info...

  for map = 1,MAP_NUM do
    -- determine episode from map number
    local ep_index
    local ep_along

    local game_along = map / MAP_NUM

    if map > 24 then
      ep_index = 5 ; ep_along = (map - 24) / 10
    elseif map > 18 then
      ep_index = 4 ; ep_along = (map - 18) / 9
    elseif map > 12 then
      ep_index = 3 ; ep_along = (map - 12) / 10
    elseif map > 6 then
      ep_index = 2 ; ep_along = (map - 6) / 9
    else
      ep_index = 1 ; ep_along = map / 6
    end

    if OB_CONFIG.length == "single" then
      game_along = 0.57
      ep_along   = 0.75

    elseif OB_CONFIG.length == "few" then
      ep_along = game_along
    end

    assert(ep_along <= 1.0)
    assert(game_along <= 1.0)

    local EPI = GAME.episodes[ep_index]
    assert(EPI)

    local LEV =
    {
      episode = EPI,
      name  = string.format("MAP%02d", map),
      ep_along = ep_along,
      game_along = game_along
    }

    table.insert( EPI.levels, LEV)
    table.insert(GAME.levels, LEV)

    -- prebuilt levels
    --[[local pb_name = LEV.name

    if PARAM.bool_prebuilt_levels == 1 then
      LEV.prebuilt = GAME.PREBUILT_LEVELS[LEV.name]
    end

    if LEV.prebuilt then
      LEV.name_class = LEV.prebuilt.name_class or "BOSS"
    end]]--

    -- procedural gotcha management code

    -- Prebuilts are to exist over procedural gotchas
    -- this means procedural gotchas will not override
    -- Icon of Sin for example if prebuilts are still on
    if not LEV.prebuilt then

      --handling for the Final Only option
      if PARAM.gotcha_frequency == "final" then
        if OB_CONFIG.length == "single" then
          if map == 1 then LEV.is_procedural_gotcha = true end
        elseif OB_CONFIG.length == "few" then
          if map == 4 then LEV.is_procedural_gotcha = true end
        elseif OB_CONFIG.length == "episode" then
          if map == 6 then LEV.is_procedural_gotcha = true end
        elseif OB_CONFIG.length == "game" then
          if map == 30 then LEV.is_procedural_gotcha = true end
        end
      end

      --every 10 maps
      if PARAM.gotcha_frequency == "epi" then
        if map == 11 or map == 20 or map == 30 then
          LEV.is_procedural_gotcha = true
        end
      end
      if PARAM.gotcha_frequency == "2epi" then
        if map == 5 or map == 11 or map == 16 or map == 20 or map == 25 or map == 30 then
          LEV.is_procedural_gotcha = true
        end
      end
      if PARAM.gotcha_frequency == "3epi" then
        if map == 3 or map == 7 or map == 11 or map == 14 or map == 17 or map == 20 or map == 23 or map == 27 or map == 30 then
          LEV.is_procedural_gotcha = true
        end
      end
      if PARAM.gotcha_frequency == "4epi" then
        if map == 3 or map == 6 or map == 9 or map == 11 or map == 14 or map == 16 or map == 18 or map == 20 or map == 23 or map == 26 or map == 28 or map == 30 then
          LEV.is_procedural_gotcha = true
        end
      end

      --5% of maps after map 4,
      if PARAM.gotcha_frequency == "5p" then
        if map > 4 then
          if rand.odds(5) then LEV.is_procedural_gotcha = true end
        end
      end

      -- 10% of maps after map 4,
      if PARAM.gotcha_frequency == "10p" then
        if map > 4 then
          if rand.odds(10) then LEV.is_procedural_gotcha = true end
        end
      end

      -- for masochists... or debug testing
      if PARAM.gotcha_frequency == "all" then
        LEV.is_procedural_gotcha = true
      end
    end

    -- handling for street mode
    -- actual handling for urban percentages are done
    if PARAM.float_streets_mode then
      if not LEV.is_procedural_gotcha and not LEV.prebuilt then
        if OB_CONFIG.batch == "yes" then
          if rand.odds(tonumber(OB_CONFIG.float_streets_mode)) then
            LEV.has_streets = true
          end
        else
          if rand.odds(PARAM.float_streets_mode) then
            LEV.has_streets = true
          end
        end
      end
    end

    if not LEV.prebuilt then
      if PARAM.float_linear_mode then
        if rand.odds(PARAM.float_linear_mode) then
          LEV.is_linear = true
        end
      end

      -- nature mode
      if PARAM.float_nature_mode and not LEV.has_streets then
        if rand.odds(PARAM.float_nature_mode) then
          LEV.is_nature = true
        end
      end

    end
  end

  -- handle "dist_to_end" for FEW and EPISODE lengths
  if OB_CONFIG.length ~= "single" and OB_CONFIG.length ~= "game" then
    GAME.levels[#GAME.levels].dist_to_end = 1

    if OB_CONFIG.length == "episode" then
      GAME.levels[#GAME.levels - 1].dist_to_end = 2
      GAME.levels[#GAME.levels - 2].dist_to_end = 3
    end
  end

end
