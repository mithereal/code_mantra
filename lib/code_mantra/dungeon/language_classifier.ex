defmodule CodeMantra.Dungeon.LanguageClassifier do
  @moduledoc """
  Classifies repositories against dynamic GitHub mainstream ranks,
  10 esoteric Void Anomalies, and 3 Ancient Relic languages.
  """

  use GenServer

  @esoteric_manifest %{
    "Brainfuck" => {"The Arcane Byte-Manipulator", :tape_shift_overflow},
    "Pony" => {"Sovereign of the Capability Grid", :reference_immunity},
    "COBOL" => {"Guardian of the Mainframe", :legacy_bulkhead},
    "Prolog" => {"Oracle of Logic Chains", :backtracking_strike},
    "Forth" => {"Stack-Walker of the Deep", :rpn_stack_cannon},
    "Whitespace" => {"The Invisible Weaver", :tab_space_invisibility},
    "Malbolge" => {"Cryptic Cipher Demigod", :self_encrypting_chaos},
    "Chef" => {"Master of Recipe Ciphers", :culinary_alchemy},
    "Intercal" => {"Polite System Sovereign", :please_protocol},
    "Befunge" => {"Dimensional Grid Traverser", :toroidal_movement}
  }

  @ancient_manifest %{
    "Fortran" => {"Grandfather of Numerical Matrices", :matrix_fortitude},
    "Lisp" => {"High Priest of S-Expression Spires", :macro_metamorphosis},
    "Algol" => {"Progenitor of Block Structures", :lexical_scope_bastion}
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def classify_language(language_name) do
    GenServer.call(__MODULE__, {:classify, language_name})
  end

  @impl true
  def init(_opts) do
    initial_ranks = [
      "TypeScript",
      "Python",
      "JavaScript",
      "Java",
      "C#",
      "C++",
      "PHP",
      "C",
      "Shell",
      "Go",
      "Ruby",
      "Rust",
      "Kotlin",
      "Swift",
      "R",
      "Dart",
      "Scala",
      "Elixir",
      "Haskell",
      "Lua"
    ]

    {:ok, %{top_20: initial_ranks}}
  end

  @impl true
  def handle_call({:classify, name}, _from, %{top_20: ranks} = state) do
    res =
      cond do
        Map.has_key?(@ancient_manifest, name) ->
          {title, perk} = Map.get(@ancient_manifest, name)

          %{
            rank: :ancient,
            class: :ancient_relic,
            title: title,
            perk: perk
          }

        Map.has_key?(@esoteric_manifest, name) ->
          {title, perk} = Map.get(@esoteric_manifest, name)

          %{
            rank: :exotic,
            class: :void_anomaly,
            title: title,
            perk: perk
          }

        true ->
          case Enum.find_index(ranks, &(&1 == name)) do
            nil ->
              %{
                rank: 99,
                class: :generic_realm,
                title: "#{name} Traverser",
                perk: :standard_baseline
              }

            idx ->
              rank_num = idx + 1

              %{
                rank: rank_num,
                class: :mainstream_tier,
                title: "Rank ##{rank_num} #{name} Vanguard",
                perk: :ecosystem_mastery_bonus
              }
          end
      end

    {:reply, res, state}
  end

  # Add this function to CodeMantra.Dungeon.LanguageClassifier
  def update_top_ranks(new_rank_list) do
    GenServer.cast(__MODULE__, {:update_ranks, new_rank_list})
  end

  # Add this handle_cast callback inside the GenServer module
  @impl true
  def handle_cast({:update_ranks, new_rank_list}, state) do
    # Updates the cached top 20 mainstream language order
    {:noreply, %{state | top_20: new_rank_list}}
  end
end
