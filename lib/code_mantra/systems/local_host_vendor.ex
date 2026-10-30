defmodule CodeMantra.Systems.LocalHostVendor do
  @moduledoc """
  Safety Zone Merchant System for protected local host nodes.
  Sells specialized physical hardware and gear upgrades for accumulated Gold.
  """
  require Logger

  @vendor_catalog %{
    "dagger_npm_i" => %{
      name: "Dagger of npm i",
      category: :weapon,
      cost: 350,
      min_level: 1,
      max_level: 5,
      class_restriction: :web_rogue,
      stats: %{alpha_numeric_xp_bonus: 0.2, timeout_reduction: true},
      description: "Boosts alpha-numeric typing base value by +0.2 XP per stroke. Decreases network timeout windows."
    },
    "blue_light_shield" => %{
      name: "Blue-Light Mitigation Shield",
      category: :armor,
      cost: 800,
      min_level: 6,
      max_level: 15,
      class_restriction: :all,
      stats: %{compiler_flash_burn_res: 0.15},
      description: "Grants +15% resistance against ambient compiler flash burn damage."
    },
    "gateron_broadsword" => %{
      name: "Linear Gateron Broadsword",
      category: :weapon,
      cost: 2500,
      min_level: 16,
      max_level: 30,
      class_restriction: [:low_level, :oop],
      stats: %{wpm_flow_multiplier: 1.20},
      description: "Grants a permanent +20 WPM flow state pacing multiplier bonus."
    },
    "tailwind_robe" => %{
      name: "The Robe of Tailwind Utility",
      category: :armor,
      cost: 5000,
      min_level: 31,
      max_level: 45,
      class_restriction: :web_illusionist,
      stats: %{dodge_multiplier: 1.50},
      description: "Allows your character to alter visual aspect ratios, multiplying dodge percentages by an additional 1.5x."
    },
    "splunk_monocle" => %{
      name: "Splunk True-Sight Monocle",
      category: :accessory,
      cost: 12000,
      min_level: 46,
      max_level: 60,
      class_restriction: :all,
      stats: %{reveal_memory_leaks: true},
      description: "Permanently highlights hidden architecture memory leak caches within multi-tiered repository dungeons."
    }
  }

  def catalog, do: @vendor_catalog

  @doc """
  Barters an item from the Local Host Provider within a safety zone node.
  """
  def purchase(user_id, item_id, user_level, user_class, current_gold) do
    case Map.get(@vendor_catalog, item_id) do
      nil ->
        {:error, :item_not_found}

      item when user_level < item.min_level or user_level > item.max_level ->
        {:error, {:level_out_of_range, min: item.min_level, max: item.max_level}}

      item when current_gold < item.cost ->
        {:error, :insufficient_gold}

      item ->
        if valid_class?(item.class_restriction, user_class) do
          remaining_gold = current_gold - item.cost
          CodeMantra.Actors.PersistenceDaemon.queue_delta(user_id, %{gold: -item.cost})

          Logger.info("🏪 [LOCAL HOST PROVIDER] User #{user_id} equipped #{item.name}!")
          {:ok, item, remaining_gold}
        else
          {:error, {:class_mismatch, required: item.class_restriction}}
        end
    end
  end

  defp valid_class?(:all, _user_class), do: true
  defp valid_class?(allowed_class, user_class) when is_atom(allowed_class), do: allowed_class == user_class
  defp valid_class?(allowed_list, user_class) when is_list(allowed_list), do: user_class in allowed_list
end