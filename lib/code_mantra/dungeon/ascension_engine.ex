defmodule CodeMantra.Dungeon.AscensionEngine do
  @moduledoc """
  Core engine managing Realm elevation up the World Tree canopy
  upon successful branch merges and boss defeats.
  """

  @spec ascend_realm(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def ascend_realm(realm_id, ascension_payload) do
    %{
      source_branch: source,
      target_branch: target,
      chambers_cleared: cleared_count,
      flow_bonus_multiplier: flow_multiplier
    } = ascension_payload

    # 1. Calculate vertical height delta based on complexity and focus
    base_height_gain = 50
    elevation_gain = round((base_height_gain + cleared_count * 25) * flow_multiplier)

    # 2. Update global World Tree state in the BEAM cluster
    new_canopy_level = persist_canopy_elevation(realm_id, elevation_gain)

    # 3. Broadcast universal ascension wave across the realm
    broadcast_canopy_ascent(realm_id, %{
      source: source,
      target: target,
      height_gain: elevation_gain,
      new_canopy_level: new_canopy_level
    })

    {:ok, %{canopy_level: new_canopy_level, height_gain: elevation_gain}}
  end

  defp persist_canopy_elevation(realm_id, height_gain) do
    # Interacts with Ash domain / ETS realm state store
    current_level = get_current_canopy_level(realm_id)
    new_level = current_level + height_gain

    # Store updated tree height
    # CodeMantra.Realms.update_realm_height!(realm_id, new_level)

    new_level
  end

  # Example baseline height
  defp get_current_canopy_level(_realm_id), do: 1250

  defp broadcast_canopy_ascent(realm_id, details) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "world_tree:#{realm_id}",
      {:realm_ascended, details}
    )
  end
end