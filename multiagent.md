# Parameters

| Symbol | Value | Description |
|--------|-------|-------------|
| `WORK_ROUND_SOFT_CAP` | 10 minutes | Default duration for a work round active phase |
| `WORK_ROUND_HARD_CAP` | 30 minutes | Maximum duration for a work round active phase |
| `AGGREGATION_TIME_FACTOR` | 2 | Aggregation phase lasts up to this multiple of the active phase duration |
| `INTRO_ROUND_HARD_CAP` | 2 minutes | Hard time limit for an introduction round |
| `ITERATION_SOFT_CAP` | 10 | Default max iterations per agent |
| `ITERATION_HARD_CAP` | 20 | Max total iterations before forced stop (user confirmation to exceed) |
| `POLLING_INTERVAL` | 15 seconds | Default interval for polling files |
| `AGENT_ID_LENGTH` | 16 bytes | Length of random agent ID |
| `DUPLICATE_RANDOM_LENGTH_MIN` | 8 characters | Min length of random strings in duplicate report filename |
| `DUPLICATE_RANDOM_LENGTH_MAX` | 16 characters | Max length of random strings in duplicate report filename |
| `STOPFILE_ZEROS` | 40 | Number of zero characters in the stopfile name |
| `SEMANTIC_THRESHOLD` | 5% | Max semantic difference to declare convergence |
| `LEXICOGRAPHIC_THRESHOLD` | 15% | Max lexicographic difference to declare convergence |
| `STALE_SUGGESTION_ROUNDS` | 3 | Consecutive rounds with identical suggestions before agent halts |
| `COORDINATION_ROUND_CAP` | 10 minutes | Hard time limit for a coordination round |
| `MAX_AGENTS` | 10 | Maximum number of agents in a coordinated group |
| `COORDINATION_TRIGGER_RATIO` | 50% | Ratio of agents lost since last coordination to trigger re-coordination |
| `COORDINATION_MIN_AGENTS` | 4 | Minimum active agents required for re-coordination to occur |
| `MIN_PROPOSAL_LENGTH` | 1 | Minimum number of methods each agent must list in its coordination proposal |
| `SUPER_MINORITY_RATIO` | 20% | If this ratio or fewer of agents lack access to the winning method, those agents halt |
| `COORDINATION_DIR` | `_coordination` | Directory for coordination files (user-configurable) |
| `GIT_RETRY_DELAY` | 5 seconds | Delay before retrying a failed git commit |
| `TIMESTAMP_TOLERANCE` | 10 seconds | Max allowed discrepancy between reported and filesystem timestamps |

# Purpose

* This file governs the coordination of multiple AI agents to achieve the same task ONLY when the agents are
  instructed to coordinate without having a centralized orchestrator
* Multiple agents that are started and managed by an orchestrator are to coordinate based on that context,
  using the mechanisms provided by the orchestrator

## Terms and definitions

* `filehash` refers to the SHA1 hash of the relative path from the base directory to the file
* Time in "wall clock" minutes measures the passage of time from a starting event and cannot be paused
* If using a timezone is important, that timezone will be UTC
* "Current time" refers to the system time as shown by the system clock
* When comparing files for changes, "original" refers to the contents of the file at the start of the current
  round and "updated" refers to the file after the changes made during the round
* A work round's active phase has a default duration of `WORK_ROUND_SOFT_CAP` and a maximum duration of
  `WORK_ROUND_HARD_CAP`. The active phase starts at the moment the round-start file is created. The
  duration for the round is known at round start (announced by the leader in the round-start file)
* Any agent may request a time extension by creating a time-extension request file during the previous
  round or before the round starts. The leader sets the active phase duration to the maximum requested
  time (capped at `WORK_ROUND_HARD_CAP`). If no extensions are requested, `WORK_ROUND_SOFT_CAP` is used
* The aggregation phase begins at the end of the active phase and can last up to `AGGREGATION_TIME_FACTOR`
  times the active phase duration
* The wait for the `starting-gun-pop` file to appear has a maximum duration equal to `WORK_ROUND_HARD_CAP`
* An agent is considered "dead" if it has not produced any valid suggestion files by the end of the active
  phase (i.e., before aggregation starts)
* An agent is considered "at risk" if its token usage has approached a limit that may prevent it from
  completing further rounds of work

## Special files naming conventions

* All special files are placed in the `COORDINATION_DIR` directory
* All special files are named using *only* ASCII printable characters
* Round types are indicated in filenames using the following prefixes:
    * `intro` — introduction rounds
    * `coord` — coordination rounds
    * `work` — work rounds

| File type | Name pattern | Notes |
|-----------|--------------|-------|
| Stopfile | `0000000000000000000000000000000000000000-stop` | `STOPFILE_ZEROS` zeros + `-stop` |
| Wrap-up file | `<filehash>-<ID>-postmortem-suggestions` | |
| Work application file | `agent-coordination-<ID>-<agent_name>` | |
| Starting-gun file | `starting-gun-pop` | Verbatim, created by user |
| Round-start file | `round-start-<type>-<round_number>-<leader_ID>` | Contains round duration |
| Time-extension request | `time-ext-<type>-<round_number>-<ID>` | Contains requested duration |
| Duplicate report file | `duplicate-agent-report-<ID>-<random1>-<random2>` | Random strings: `DUPLICATE_RANDOM_LENGTH_MIN` to `DUPLICATE_RANDOM_LENGTH_MAX` |
| Error report file | `error-agent-report-<ID>` | Single file per agent, append-only |
| Dead-agent report file | `dead-agent-report-<type>-<round_number>-<leader_ID>` | Lists dead agent IDs |
| Opt-out file | `opt-out-leader-<ID>` | |
| Agent-done file | `agent-done-<type>-<round_number>-<ID>` | Voluntary exit signal |
| Next-leader announcement | `next-leader-<type>-<round_number>-<leader_ID>` | Contains next leader's ID |
| Suggestion file | `suggestion-<filehash>-<round_number>-<ID>` | Per-file, per-round, per-agent |
| Coordination proposal | `coordination-proposal-<round_number>-<ID>` | Ranked method list |
| Coordination consideration | `coordination-consider-<round_number>-<leader_ID>` | Lists proposal files to consider |

## Base rules

* The agent should assume that all other agents in the coordinated group follow these rules
* Agents are assumed to act in good faith. The threat model is buggy implementations, not malicious agents
* The agents all work in the same **base** directory. Every change happens in that directory
* All coordination/special files are placed in `COORDINATION_DIR`. The user may configure this name to
  avoid conflicts with existing project directories
* The agents are allowed to agree to another coordination method as an outcome of their coordination
* An agent's special files can **only** be modified by that agent, including updating access and
  modification times
* An agent tracks the state of the special files that belong to it. If any of its files are modified by
  an entity other than the agent itself, the agent reports this as an issue in its error report file
  and halts
* All other rules, including those concerning code development and PII protection are in effect
* Due to the agents being expected to work iteratively to achieve an outcome, minimal human intervention
  should be required
* ALL risks that may lead to agents stalling waiting for human input should be addressed as soon as possible
* If an agent is at risk of blocking, i.e. due to token exhaustion it **must**:
    * Report the risk as soon as possible
    * Ensure it records actions in status files prior to acting, to avoid loss of information and effort
    * Opt out from becoming a round leader / coordinator
* File paths are considered as the file ID. Files are not considered to be moved but instead removed and
  new files added

### Versioning and git commit protocol

* Versioning is the default choice. The preferred tool is `git`. A repository is initialized if not
  available and the files in the context are added into it
* Coordination files are tracked in git but committed separately from work files. Coordination file commits
  happen at the end of each coordination set or at natural checkpoints, not in the same transaction as
  work file commits during aggregation
* Work file commits during aggregation contain only the modified work files
* When files are committed, the commit message details what work was done and which agent did the commit
* During aggregation, the round leader stages only modified work files (`git add <work files>`)
* The leader commits with a structured message including round number, round type, and agent ID
* If the commit fails (e.g., index lock, hook failure), the leader retries once after `GIT_RETRY_DELAY`
* If the retry fails, the leader reports the error in its error report file and handover triggers
* On handover, the acting leader performs `git reset --hard HEAD` to discard any partial changes from
  the failed leader, then performs aggregation from scratch

## Convergence, stop and timeout rules

* These rules apply explicitly and implicitly unless an **explicit** instruction for a different convergence
  method is given
* The default maximum number of iterations is `ITERATION_SOFT_CAP`. Agents may autonomously decide to
  extend beyond this up to `ITERATION_HARD_CAP` based on observed progress, number of files, or file
  sizes — no user confirmation is required for this extension
* Extending past `ITERATION_HARD_CAP` requires explicit user confirmation. If user confirmation is not
  available, the process halts. The user may then start a new coordination session with an expanded
  `ITERATION_HARD_CAP`, potentially with different agents or agent IDs. The user is allowed to delete
  coordination files between sessions to achieve a clean state
* The iterations stop as soon as a stopfile is created even if no other stop criteria has been satisfied,
  such as number of rounds or timeout
* An agent considers that work on a document has converged if the delta between the document at the start of
  the round and the changes it can propose for the document are below the convergence thresholds
* An agent considers that its work is done when all the documents have converged
* The delta calculation uses semantic difference and lexicographic difference as separate thresholds.
  Convergence is reached when **either** threshold is satisfied (see Convergence thresholds section)
* If an agent's remaining suggestions are substantively identical across `STALE_SUGGESTION_ROUNDS`
  consecutive rounds (as determined by comparing its suggestion files across rounds), the agent must
  report this condition and halt
* An agent that has been considered dead but is not inactive may create wrap-up files to summarize
  their suggestions for human perusal
* Wrap-up files are excluded from consideration by active agents during work rounds. They exist solely
  for human review after the process completes
* If no agent is eligible to be a round leader / coordinator, then the iterations stop and all agents
  report their status
* Polling for files is set to `POLLING_INTERVAL` by default
* If an agent identifies a file using its ID it did not create, that agent stops and reports the issue in
  a duplicate report file
* If only one agent is active, the process halts
* At the end of each work round, the round leader creates a dead-agent report file listing any agents that
  did not produce suggestion files during that round. Agents listed are excluded from future rounds
* An agent that has no further feedback and wishes to end its participation in the process creates an
  `agent-done` file. This is a voluntary exit and does not mark the agent as dead

### Convergence thresholds

* Convergence is reached when **either** of the following conditions is met:
    * The semantic difference between the original and updated file is less than or equal to
      `SEMANTIC_THRESHOLD`
    * The lexicographic difference between the original and updated file is less than or equal to
      `LEXICOGRAPHIC_THRESHOLD`

## Types of iteration rounds

* The types of rounds are as follows:
    * Introduction rounds
    * Coordination rounds
    * Work rounds
* Coordination rounds and work rounds have a round leader

### Introduction rounds

* They are rounds where new agents are allowed to be added to the working set of agents
* The first round(s) are always introduction rounds, so agents can identify themselves
* If this instruction set allows it, agents may be added or the list be refreshed during introduction
  rounds. Otherwise, agents may only be added to the working set during the initial introduction rounds
* For the time being, introduction rounds may only precede other round types
* Introduction rounds are not counted towards the total number of maximum iterations
* Introduction rounds have a maximum run limit of `INTRO_ROUND_HARD_CAP` each (hard cap)

#### Introduction steps

* Each agent generates a random string of `AGENT_ID_LENGTH` that becomes their ID when they start work.
  That ID is immutable throughout the entire work and identifies the agent uniquely
* The agent then creates its work application file as a way to state that it is available for work
* Once the agent has created the file, it polls the directory waiting for the creation of the
  `starting-gun-pop` file by the user
* If the `starting-gun-pop` file does not appear within `WORK_ROUND_HARD_CAP`, the execution terminates
  without any further action
* Once the `starting-gun-pop` file appears, each agent reads all work-application files to identify the
  full set of active agent IDs

### Coordination rounds

* Coordination rounds refer to rounds where work is assigned or ways to coordinate are defined by agents
* Coordination rounds **must** follow the last introduction round in an introduction round set
* A **set** of coordination rounds occurs between work rounds when `COORDINATION_TRIGGER_RATIO` of the
  agents that were active at the start of work after the previous coordination set are no longer active,
  **and** more than `COORDINATION_MIN_AGENTS` agents are still active
* For the first coordination set, the active agent count is defined as the number of agents that created
  work application files before the `starting-gun-pop` file appeared
* Coordination rounds are **not** counted towards iteration caps
* A coordination round has a leader, selected using the same rules as work round leaders
* A coordination round begins when its leader creates a round-start file and has a hard time cap of
  `COORDINATION_ROUND_CAP`
* The maximum number of agents in a coordinated group is `MAX_AGENTS`. This assumption keeps the
  file-based coordination protocol manageable

#### Coordination methods

* A coordination method is identified by a canonical string in the format `<protocol>` or
  `<protocol>:<details>`, where `protocol` is a known keyword and `details` are protocol-specific
* Matching across proposals is performed on **exact string equality**
* The following canonical method strings are defined:

| Method string | Interpretation |
|---------------|----------------|
| `file-based` | The default protocol defined in this document (shared directory, polling) |
| `mq:<endpoint>` | A message queue at the specified endpoint |
| `pubsub:<topic>@<broker>` | Publish-subscribe messaging on a given topic and broker |
| `api:<url>` | A REST/HTTP API endpoint for coordination messages |
| `db:<connection_string>` | A shared database for coordination state |
| `pipe:<path>` | A named pipe / FIFO at the specified filesystem path |
| `socket:<host>:<port>` | A TCP socket connection |

* The `file-based` method is always implicitly available to every agent
* An agent that has a coordination method available but cannot find a matching canonical string in the
  table above must report the situation in its error report file but does **not** halt. It lists only
  the methods it can express using known canonical strings

#### Coordination proposal protocol

* A coordination round follows the same time structure as a work round: it starts when the leader creates
  the round-start file and ends at round start + `COORDINATION_ROUND_CAP`
* During the active phase, each agent creates a coordination proposal file containing its ranked list of
  available coordination methods (using canonical method strings), ordered from most preferred to least
  preferred
* Each proposal must list at least `MIN_PROPOSAL_LENGTH` method (the `file-based` fallback is always
  implicitly available to every agent)
* At round end, the round leader creates a coordination consideration file listing the proposal files
  to be considered. Only proposals created during the active phase are eligible
* An agent whose proposal file is **not** listed in the consideration file must report an error and halt
* All agents read all listed proposal files and independently determine the winning method using the
  following resolution algorithm:
    1. Identify all methods that appear in at least one proposal. For each method, count how many
       agents list it
    2. Determine the candidate set: methods shared by **every** agent. If no fully-shared method
       exists, use methods shared by the largest number of agents as the candidate set
    3. For each candidate method, compute its worst rank (the highest rank number assigned by any
       agent that lists it)
    4. The winning method is the candidate with the lowest worst-rank (maximin criterion)
    5. If multiple candidates are tied on worst-rank, break the tie by lowest sum of ranks across
       all agents that list them (Borda count)
    6. If still tied, break by lexicographic ordering of the method name (earliest wins)
    7. If the winning method is not fully shared: identify agents that do not list it. If those
       agents constitute `SUPER_MINORITY_RATIO` or fewer of the active agents, those agents halt
       and the remaining agents adopt the method. Otherwise, all agents fall back to the `file-based`
       protocol defined in this document
* No agent writes to another agent's files. The resolution is achieved through each agent reading all
  proposals and arriving at the same conclusion independently
* Strategic misreporting of preferences is a violation of base rules (agents are assumed to act in good
  faith). This is accepted as a known risk for this iteration

#### Coordination leader failure

* If `COORDINATION_ROUND_CAP` expires and no coordination consideration file exists, agents wait one
  additional `POLLING_INTERVAL` (grace period)
* After the grace period, the next eligible agent checks whether a consideration file for this round
  exists
* If no consideration file exists: the acting leader creates it, listing all coordination proposal files
  with filesystem timestamps within the active phase
* If a consideration file exists: normal resolution flow resumes (the original leader was slow but
  completed)
* The acting leader for coordination failure is determined by the same lexicographic rule as work
  round handover

### Work rounds

* Work rounds are the rounds when the actual implementation and work take place
* A work round begins when the round leader creates a round-start file. All other agents poll for this file
* The work rounds are split into two phases:
    * Active phase (from round start until round end)
    * Aggregation phase (after round end, performed by the round leader only)

#### Active phase

* During the active phase, **all** agents (including the round leader) read the files that still need
  work and create suggestion files
* An agent is free to create its suggestion files at any point during the active phase
* Each suggestion file must include the agent's current system time at the end of the file in the
  format `file created at <ISO 8601 timestamp>`
* Only suggestion files with a filesystem creation time between round start and round end (end of active
  phase) are considered valid
* During aggregation, the round leader validates each suggestion file by comparing the reported
  timestamp against the file's filesystem creation/modification time. If the discrepancy exceeds
  `TIMESTAMP_TOLERANCE`, the leader reports the discrepancy in its error report file. The suggestion
  file is still considered valid if its filesystem time falls within the active phase
* An agent (including the round leader) that does not produce any valid suggestion file during the
  active phase is considered dead
* The round leader does not assign special weight to its own suggestions during aggregation

#### Aggregation phase

* Aggregation begins at the end of the active phase and can last up to `AGGREGATION_TIME_FACTOR` times
  the active phase duration
* The round leader reads all valid suggestion files from active agents (including its own)
* The round leader decides which suggestions to apply, considering the aggregate input. Differences in
  quality and priority across suggestions are considered a feature of this approach
* The round leader applies the selected changes to the target files
* The round leader commits all modifications with a message detailing the round number and changes applied
* After committing, the round leader:
    * Creates a dead-agent report file if any agents failed to produce valid suggestion files
    * Creates a next-leader announcement file designating the leader for the following round
    * The next leader is selected from agents that are alive and have not created an opt-out file,
      in lexicographic order after the current leader's ID (wrapping around if necessary)

#### Timing and clock reference

* All timing within a round is derived from the **filesystem modification timestamp (mtime)** of the
  round-start file. This serves as the single shared clock reference for all agents
* Active phase ends at: round-start file mtime + active phase duration (as announced in the file)
* Aggregation deadline: active phase end + (active phase duration × `AGGREGATION_TIME_FACTOR`)
* Agents compare "current time" against these derived deadlines to determine phase transitions

#### Leader failure and handover during aggregation

* If the round leader dies during the active phase (fails to produce suggestions), the aggregation
  responsibility transfers to the next eligible agent in lexicographic order. This agent becomes the
  acting leader for the aggregation phase only and performs the aggregation duties
* If the round leader fails to complete aggregation within the aggregation deadline, the next eligible
  agent initiates handover using the following protocol:
    1. Wait an additional `POLLING_INTERVAL` after the aggregation deadline (grace period)
    2. Check `git log` to determine if the original leader committed during the aggregation phase
    3. If a commit by the original leader exists, handover is cancelled — the round completed normally
    4. If no such commit exists, the acting leader performs `git reset --hard HEAD` to discard any
       partial changes, then performs aggregation from scratch using all valid suggestion files
* The acting leader that took over aggregation also designates the next round's leader (which may be
  itself or another eligible agent)

### Definition of round leader

* The first round leader is the active agent whose ID comes first lexicographically
* Subsequent round leaders are designated by the current round leader via the next-leader announcement file
* An agent that has been declared dead by a previous round leader must not act as round leader. If it is
  still active, it must create an opt-out file
* An agent that has reported a blocking risk must create an opt-out file
* If the current round leader fails to produce suggestions during the active phase, or fails to complete
  aggregation within the aggregation time limit, it is considered dead. Handover proceeds as described
  in the "Leader failure and handover during aggregation" section

### Next-leader announcement validation

* An agent only acts on a next-leader announcement file whose `<leader_ID>` field matches the agent it
  expects to be the current round leader (based on the previous announcement, or the lexicographic
  bootstrap for round 1)
* If an agent encounters a next-leader announcement file with an unexpected `<leader_ID>`, it ignores
  the file and reports the discrepancy in its error report file. It continues to wait for a valid
  announcement (up to the aggregation deadline + grace period)
* If multiple next-leader announcement files exist for the same round and type, all agents report the
  conflict in their error report files and halt

# Known risks and issues

* **Duplicate IDs**: Agents may enter a race condition where two share the same ID, with neither being
  aware that they are not unique. The 16-byte random ID makes collisions statistically improbable, but
  a malformed agent or implementation bug could produce duplicates. Detection and resolution of this case
  is deferred to a future iteration of this document
* **Convergence thresholds**: Current values (`SEMANTIC_THRESHOLD` = 5%, `LEXICOGRAPHIC_THRESHOLD` = 15%)
  are initial estimates. Empirical calibration may adjust these. The semantic threshold is intentionally
  tight (primary convergence signal); the lexicographic threshold is a fallback for when semantic diff is
  unreliable or expensive to compute
* **Premature agent termination during coordination**: If the round leader's coordination consideration
  file omits an agent's proposal (due to race condition or error), that agent halts permanently with no
  recovery mechanism. This is accepted for the first iteration of this document; a grace period or retry
  mechanism may be added in a future revision
* **Strategic misreporting in coordination proposals**: An agent could rank methods dishonestly to
  influence the outcome. Base rules assume good faith; no verification mechanism exists in this iteration
* **Super-minority override**: When no fully-shared method exists, agents constituting
  `SUPER_MINORITY_RATIO` or fewer of the group may be forced to halt. This is a deliberate trade-off
  to avoid defaulting to no-change too readily
* **Round leader discretion in aggregation**: The round leader decides which suggestions to apply and how
  to reconcile conflicting suggestions. This grants significant power to the leader and could lead to
  bias or suboptimal outcomes. This is accepted for the first iteration and should be evaluated based on
  generated results before deciding whether to retain, constrain, or replace this approach
* **Filehash collision**: If two distinct file paths produce the same SHA1 hash, the suggestion file
  naming scheme cannot distinguish them. The round leader must detect this condition (two files mapping
  to the same `filehash`), report it in its error report file, and halt the iteration. SHA1 collisions
  on short path strings are statistically improbable (probability ~2^-160) but not theoretically
  impossible
* **Git state recovery is the user's responsibility**: If a handover or halt leaves the git repository in
  an unrecoverable state (corrupted index, partial merges, etc.), the user is responsible for cleanup.
  The `.git` directory may be renamed or moved outside the working directory for posterity. Agents do not
  attempt complex git recovery beyond `git reset --hard HEAD`
* **Spurious next-leader announcements**: A buggy agent could accidentally create a next-leader
  announcement file with an incorrect `<leader_ID>`. This is handled by validation (agents ignore files
  from unexpected leaders) but could delay round transitions if the legitimate leader also fails to
  announce. In the worst case, the aggregation deadline + grace expires and handover triggers. The
  assumption is that agents are good-faith but potentially buggy, not malicious
* **Time-extension requests for the first work round**: There is no previous round during which to
  submit a time-extension request for work round 1. Agents would need to create the request during the
  coordination phase or in the gap before the leader creates the first round-start file. The exact
  window for this is unspecified
* **Number of rounds in a coordination set**: The document defines when a coordination set triggers but
  not how many rounds it contains or when it ends. Whether a set is always a single round or may repeat
  on failure is undefined
* **Interaction between `agent-done` and dead-agent detection**: If an agent creates an `agent-done` file
  mid-round without producing suggestion files, it is unclear whether it is declared dead or its
  voluntary exit protects it from that classification
* **Transition signal from introduction to coordination**: After the `starting-gun-pop` file appears and
  agents read work-application files, no explicit rule states who creates the first coordination
  round-start file or when. The implicit assumption is that the first leader does so immediately
* **Cascading handover**: If the designated handover agent also fails, no protocol defines further
  cascading. Only a single level of handover is specified
* **Iteration cap semantics (per-agent vs. total)**: `ITERATION_SOFT_CAP` is described as "per agent"
  in the parameters table but as a total count in the rules. `ITERATION_HARD_CAP` is described as
  "total." Whether these are the same counter or independent per-agent vs. global counters needs
  clarification
* **Suggestion file content format**: The content of suggestion files (beyond the trailing timestamp) is
  not defined. Different agent providers may produce varying formats (free text, diffs, structured data),
  making aggregation more complex. This is partially by design (leader discretion) but may warrant a
  minimal format specification in a future revision
* **Git staging discipline for `COORDINATION_DIR`**: Coordination files live inside the repo but are
  committed separately. No `.gitignore` rule or staging convention (e.g., never use `git add .`) is
  specified to prevent accidental inclusion of coordination files in work commits
* **Resolution algorithm with partial coverage ties**: When no fully-shared method exists, multiple
  methods may tie on agent coverage (e.g., two methods each shared by 7 of 10 agents). Both enter the
  candidate set and worst-rank is computed only over agents listing each method. A method listed by
  fewer agents could win due to having a lower worst-rank. This is deterministic but may produce
  unintuitive outcomes
* **Exceeding `MAX_AGENTS`**: If more than `MAX_AGENTS` agents create work-application files before
  the `starting-gun-pop` file, no rule defines whether excess agents are excluded, the process halts,
  or user intervention is required
