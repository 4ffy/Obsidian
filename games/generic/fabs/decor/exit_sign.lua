--
-- A tiny exit sign (on the floor)
--

PREFABS.Decor_exit_sign =
{
  file   = "decor/exit_sign.wad",
  map    = "MAP01",
  game = { doom1=1, doom2=1, harmony=1 },

  group  = "exit_sign",
  prob   = 80,

  where  = "point",
}

PREFABS.Decor_exit_sign_strife =
{
  file   = "decor/exit_sign.wad",
  map    = "MAP01",
  game = "strife",

  group  = "exit_sign",
  prob   = 80,

  where  = "point",

  forced_offsets = 
  {
    [6] = { x=0, y=11 }
  }

}

