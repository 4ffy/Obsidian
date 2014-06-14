--
-- Drop-off border prefabs
--

DOOM.SKINS.Border_dropoff_c =
{
  file   = "border/dropoff_c2.wad"
  group  = "border_dropoff"
  shape  = "C"

  seed_w = 3
  seed_h = 3

  -- need this due to diagonal outlier part
  bound_x1 = 0
  bound_y1 = 0

  add_sky = 1
}


DOOM.SKINS.Border_dropoff_t =
{
  file   = "border/dropoff_t.wad"
  group  = "border_dropoff"
  shape  = "T"

  seed_w = 3
  seed_h = 3

  add_sky = 1
}


DOOM.SKINS.Border_dropoff_exit =
{
  file   = "border/dropoff_exit.wad"
  group  = "border_dropoff"
  shape  = "T"

  purpose = "EXIT"

  seed_w = 3
  seed_h = 3

  x_fit = "frame"

  add_sky = 1
}


--
-- Group information
--

DOOM.GROUPS.border_dropoff =
{
  kind = "border"

  fence_boost = 12
}

