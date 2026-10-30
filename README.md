# 🛡️ Code::Mantra

> **Turn IDE development into a real-time, dark-fantasy multiplayer RPG.**

**Code::Mantra** is a high-concurrency, distributed platform built on the BEAM ecosystem (Elixir/Phoenix). It transforms everyday coding, git commits, and code reviews into a multiplayer dungeon-crawling experience. By monitoring live telemetry streams from local code editors, Code::Mantra evaluates developer input in real-time—synthesizing royal titles, spawning world boss encounters for merge conflicts, and synchronizing global team repositories.

---

## 🌟 Key Features

* **Real-time Telemetry Processing:** Ingests 250ms sliding-window editor payloads (keystrokes, WPM, buffer changes) over Phoenix Channels (`developer_workspace:*`).
* **Procedural Title & Rank Synthesis:** Dynamically synthesizes royal titles (e.g., *The Asynchronous Strict-Type of the Sunken Technical Debt*) and unbounded rank tiers (`D` through `OMEGA`) based on cyclomatic complexity, coding cadence, and debt keywords.
* **Anti-Cheat Heuristics:** Employs Shannon Entropy algorithms to detect macro repetition, key-holding bots, and LLM code pastes—adjusting XP rewards accordingly.
* **Turn-Based Boss Encounters:**
    * **The Merge Conflict (World Boss):** Interactive combat loop triggered on Git collisions, featuring evasion passives, line collisions, and compiler checks.
    * **The Infinite Loop (Elite Monster):** Memory allocation threat requiring a `SIGKILL Decapitation` command within a 15-second window.
* **Runtime Apothecary & Vendor:** In-game shop for purchasing runtime stimulants (e.g., *Caffeine Overclock Tincture*, *Elixir of Garbage Collection*) and hardware upgrades using earned Gold Shards.
* **Monorepo Raid Engine:** Tracks multi-developer branch states across team repositories (`repo_dungeon:*`), turning teammate build failures into "Git Fracture" environmental hazards.
* **Multi-Region BEAM Clustering:** Built with `libcluster` and `Registry` process partitioning for cross-regional cloud scaling and global state synchronization.

---

## 🏗️ Core Architecture (BEAM Actors)

Code::Mantra operates via an isolated, fault-tolerant 6-actor supervision tree:

```
                  ┌──────────────────────────────┐
                  │   CodeMantra.Supervisor      │
                  └──────────────┬───────────────┘
                                 │
     ┌───────────────────────────┼───────────────────────────┐
     │                           │                           │
┌────┴──────────────┐   ┌────────┴─────────────┐   ┌────────┴────────────┐
│ ClientSocket      │   │ EvaluationDaemon     │   │ ProgressionBalancer │
│ (Actor 1)         │──>│ (Actor 2)            │──>│ (Actor 3)           │
└───────────────────┘   └──────────────────────┘   └────────┬────────────┘
                                                            │
┌───────────────────┐   ┌──────────────────────┐   ┌────────┴────────────┐
│ MonolithDrop      │   │ DungeonOrchestrator  │   │ PersistenceDaemon   │
│ (Actor 6)         │   │ (Actor 5)            │<──│ (Actor 4)           │
└───────────────────┘   └──────────────────────┘   └─────────────────────┘
```

1. **`ClientSocket` (Actor 1):** IDE WebSocket connection gateway.
2. **`EvaluationDaemon` (Actor 2):** AST cyclomatic complexity parser & procedural title synthesizer.
3. **`ProgressionBalancer` (Actor 3):** Anti-cheat entropy validator, WPM cadence calculator, and XP/Gold distributor.
4. **`PersistenceDaemon` (Actor 4):** In-memory delta buffer that flushes state checkpoints to PostgreSQL every 30s.
5. **`DungeonOrchestrator` (Actor 5):** Monorepo raid coordinator managing Git fractures and team shields.
6. **`MonolithDrop` (Actor 6):** Technical debt monitor that awakens *The Monolith King* world boss when global debt peaks.

---

## 🛠️ Stack & Dependencies

* **Language/Platform:** Elixir ~> 1.16, Erlang/OTP 26
* **Web Framework:** Phoenix ~> 1.7, Phoenix LiveView ~> 1.0
* **Data Layer:** PostgreSQL with Ash Framework
* **Clustering:** `libcluster`, Phoenix.PubSub
* **Frontend Overlay:** Tailwind CSS, LiveView Components

---

## 🚀 Quickstart Guide

### Prerequisites

* Elixir 1.16+ & Erlang/OTP 26+
* PostgreSQL 14+
* Docker (optional for containerized setup)

### 1. Local Setup

Clone the repository and install dependencies:

```bash
git clone https://github.com/your-org/code_mantra.git
cd code_mantra
mix deps.get
```

Set up database migrations:

```bash
mix setup
```

Start the Phoenix server with interactive Elixir shell:

```bash
iex -S mix phx.server
```

Open your browser to `http://localhost:4000/onboarding` to create your developer character and enter the dashboard.

---

### 2. VS Code Extension Integration

To stream telemetry from VS Code to your running backend:

1. Copy the `extension.ts` script into a local VS Code extension project directory.
2. Configure your `settings.json`:
   ```json
   {
     "codeMantra.userId": "user_123"
   }
   ```
3. Launch the extension (`F5`). Open any code file and start typing—telemetry streams automatically to the `developer_workspace:user_123` Phoenix channel.

---

### 3. Docker Deployment

Code::Mantra uses a multi-stage Docker setup targeting a lightweight Alpine runtime (~35MB base).

Build and run the container locally:

```bash
docker build -t code_mantra:latest .
docker run -p 4000:4000 -p 45892:45892/udp code_mantra:latest
```

#### Exposed Ports:
* `4000`: Phoenix Web Server & WebSockets
* `45892`: `libcluster` UDP Gossip Discovery
* `4369` / `9001`: EPMD & Distributed Erlang Inter-Node Ports

---

## 🎮 LiveView Interfaces

* **`/dashboard/:user_id`**: Real-time HUD displaying your active level, royal title, XP progress bar, Gold wallet, live combat feed, and global world boss HP.

---

## 🧪 Testing

Run the full Elixir test suite:

```bash
mix test
```

To test specific actor routines via IEx:

```elixir
# Trigger an Infinite Loop combat event
CodeMantra.Actors.BossEncounterEngine.trigger_infinite_loop("user_123", "repo_main")

# Execute SIGKILL Decapitation
CodeMantra.Actors.BossEncounterEngine.execute_sigkill("user_123", "loop_ENCOUNTER_ID")

# Summon The Monolith King World Boss
CodeMantra.Actors.MonolithDrop.summon_king("REALM-4aef81")
```

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.