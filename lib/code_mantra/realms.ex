defmodule CodeMantra.Realms do
  @moduledoc """
  The Ash Domain for managing CodeMantra git repositories, active realm branches,
  World Tree progression, and transient dungeon state.
  """
  use Ash.Domain

  resources do
    resource CodeMantra.Realms.Repository
    resource CodeMantra.Realms.Branch
    resource CodeMantra.Realms.WorldTree
  end
end