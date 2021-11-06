PREFABS.Decor_air_vent_large_module =
{
  file   = "decor/gtd_decor_industrial_air_vents_set_EPIC.wad",
  map    = "MAP01",

  prob   = 5000,
  texture_pack = "armaetus",

  group = "gtd_wall_air_vents",

  where  = "point",
  size   = 104,
  height = 96,

  bound_z1 = 0,
  bound_z2 = 96,

  z_fit  = "top",
}

PREFABS.Decor_air_vent_pillar =
{
  template = "Decor_air_vent_large_module",
  map = "MAP02",

  size = 64,
}

PREFABS.Decor_air_vent_large_module =
{
  template = "Decor_air_vent_large_module",
  map = "MAP03",

  size = 128,
  height = 80
}
