# Raft Consensus Implementation Patterns
#
# Raft is a consensus algorithm for managing a replicated log.
# It provides fault tolerance and consistency in distributed systems.
#
# For production use, consider:
#   {:raft, "~> 0.5"} - Pure Elixir implementation
#   :ra - Erlang implementation from RabbitMQ team
#
# Key concepts:
# - Leader election
# - Log replication
# - Safety guarantees
# - Membership changes

defmodule MyApp.RaftConfig do
  @moduledoc """
  Configuration for Raft consensus groups.
  """

  def election_timeout_range do
    # 1.5 to 3 seconds
    {1_500, 3_000}
  end

  def heartbeat_interval do
    # 500ms
    500
  end

  def snapshot_interval do
    # Every 1000 entries
    1_000
  end

  def max_log_entries_per_request do
    100
  end
end

defmodule MyApp.RaftState do
  @moduledoc """
  Represents the state of a Raft node.
  """

  defstruct [
    :current_term,
    :voted_for,
    :log,
    :commit_index,
    :last_applied,
    :leader_id,
    :next_index,
    :match_index,
    :state,
    :peers,
    :votes_received
  ]

  def new(node_id, peers) do
    %__MODULE__{
      current_term: 0,
      voted_for: nil,
      log: [],
      commit_index: 0,
      last_applied: 0,
      leader_id: nil,
      next_index: %{},
      match_index: %{},
      state: :follower,
      peers: peers,
      votes_received: MapSet.new()
    }
  end
end

defmodule MyApp.RaftNode do
  @moduledoc """
  Implementation of a Raft consensus node.

  This is a simplified implementation for educational purposes.
  For production, use :ra or the raft library.
  """

  use GenStateMachine
  require Logger

  @heartbeat_interval 500
  @election_timeout_min 1_500
  @election_timeout_max 3_000

  def start_link(opts) do
    node_id = Keyword.fetch!(opts, :node_id)
    peers = Keyword.fetch!(opts, :peers)

    GenStateMachine.start_link(__MODULE__, {node_id, peers}, name: via_tuple(node_id))
  end

  def propose(node_id, command) do
    GenStateMachine.call(via_tuple(node_id), {:propose, command})
  end

  def get_state(node_id) do
    GenStateMachine.call(via_tuple(node_id), :get_state)
  end

  defp via_tuple(node_id) do
    {:via, Registry, {MyApp.RaftRegistry, node_id}}
  end

  # Callbacks

  @impl true
  def init({node_id, peers}) do
    state = %{
      node_id: node_id,
      peers: peers,
      current_term: 0,
      voted_for: nil,
      log: [],
      commit_index: 0,
      last_applied: 0,
      leader_id: nil,
      next_index: %{},
      match_index: %{},
      state_machine: %{}
    }

    # Start as follower with election timeout
    {:ok, :follower, state, [{:state_timeout, random_election_timeout()}]}
  end

  # Follower state

  @impl true
  def handle_event(:state_timeout, _content, :follower, state) do
    Logger.info("Follower #{state.node_id} election timeout, becoming candidate")
    become_candidate(state)
  end

  @impl true
  def handle_event(
        {:call, from},
        {:request_vote, term, candidate_id, last_log_index, last_log_term},
        :follower,
        state
      ) do
    handle_vote_request(from, term, candidate_id, last_log_index, last_log_term, state)
  end

  @impl true
  def handle_event(
        {:call, from},
        {:append_entries, term, leader_id, prev_log_index, prev_log_term, entries, leader_commit},
        :follower,
        state
      ) do
    handle_append_entries(
      from,
      term,
      leader_id,
      prev_log_index,
      prev_log_term,
      entries,
      leader_commit,
      state
    )
  end

  # Candidate state

  @impl true
  def handle_event(:state_timeout, _content, :candidate, state) do
    Logger.info("Candidate #{state.node_id} election timeout, starting new election")
    become_candidate(state)
  end

  @impl true
  def handle_event(:info, {:vote_granted, voter_id}, :candidate, state) do
    new_votes = MapSet.put(state.votes_received, voter_id)
    new_state = %{state | votes_received: new_votes}

    # Check if we have majority
    majority = div(length(state.peers) + 1, 2) + 1

    if MapSet.size(new_votes) >= majority do
      become_leader(new_state)
    else
      {:next_state, :candidate, new_state}
    end
  end

  # Leader state

  @impl true
  def handle_event(:state_timeout, _content, :leader, state) do
    # Send heartbeats
    send_heartbeats(state)
    {:next_state, :leader, state, [{:state_timeout, @heartbeat_interval}]}
  end

  @impl true
  def handle_event({:call, from}, {:propose, command}, :leader, state) do
    handle_proposal(from, command, state)
  end

  # Common handlers

  @impl true
  def handle_event({:call, from}, :get_state, _state_name, state) do
    {:keep_state, state, [{:reply, from, state}]}
  end

  # Private functions

  defp become_candidate(state) do
    new_term = state.current_term + 1

    new_state = %{
      state
      | current_term: new_term,
        voted_for: state.node_id,
        state: :candidate,
        leader_id: nil,
        votes_received: MapSet.new([state.node_id])
    }

    # Request votes from all peers
    request_votes(new_state)

    {:next_state, :candidate, new_state, [{:state_timeout, random_election_timeout()}]}
  end

  defp become_leader(state) do
    Logger.info("Node #{state.node_id} becoming leader for term #{state.current_term}")

    new_state = %{
      state
      | state: :leader,
        leader_id: state.node_id,
        next_index: Map.new(state.peers, fn peer -> {peer, length(state.log) + 1} end),
        match_index: Map.new(state.peers, fn peer -> {peer, 0} end)
    }

    # Send initial heartbeats
    send_heartbeats(new_state)

    {:next_state, :leader, new_state, [{:state_timeout, @heartbeat_interval}]}
  end

  defp request_votes(state) do
    last_log_index = length(state.log)
    last_log_term = get_log_term(state.log, last_log_index)

    Enum.each(state.peers, fn peer ->
      send_vote_request(peer, state.current_term, state.node_id, last_log_index, last_log_term)
    end)
  end

  defp send_heartbeats(state) do
    Enum.each(state.peers, fn peer ->
      next_idx = Map.get(state.next_index, peer, 1)
      prev_log_index = next_idx - 1
      prev_log_term = get_log_term(state.log, prev_log_index)

      entries = Enum.drop(state.log, next_idx - 1)

      send_append_entries(
        peer,
        state.current_term,
        state.node_id,
        prev_log_index,
        prev_log_term,
        entries,
        state.commit_index
      )
    end)
  end

  defp handle_vote_request(from, term, candidate_id, last_log_index, last_log_term, state) do
    {response, new_state} =
      cond do
        term < state.current_term ->
          {{:vote_denied, state.current_term}, state}

        term > state.current_term ->
          # Update term and become follower
          new_state = %{state | current_term: term, voted_for: nil, state: :follower}
          grant_vote_if_valid(new_state, candidate_id, last_log_index, last_log_term)

        state.voted_for == nil or state.voted_for == candidate_id ->
          grant_vote_if_valid(state, candidate_id, last_log_index, last_log_term)

        true ->
          {{:vote_denied, state.current_term}, state}
      end

    {:keep_state, new_state, [{:reply, from, response}]}
  end

  defp grant_vote_if_valid(state, candidate_id, last_log_index, last_log_term) do
    my_last_index = length(state.log)
    my_last_term = get_log_term(state.log, my_last_index)

    if last_log_term > my_last_term or
         (last_log_term == my_last_term and last_log_index >= my_last_index) do
      new_state = %{state | voted_for: candidate_id}
      {{:vote_granted, state.current_term}, new_state}
    else
      {{:vote_denied, state.current_term}, state}
    end
  end

  defp handle_append_entries(
         from,
         term,
         leader_id,
         prev_log_index,
         prev_log_term,
         entries,
         leader_commit,
         state
       ) do
    if term < state.current_term do
      {:keep_state, state, [{:reply, from, {:rejected, state.current_term}}]}
    else
      new_state =
        if term > state.current_term do
          %{state | current_term: term, voted_for: nil, leader_id: leader_id}
        else
          %{state | leader_id: leader_id}
        end

      # Reset election timeout
      actions = [
        {:reply, from, {:accepted, state.current_term}},
        {:state_timeout, random_election_timeout()}
      ]

      # Apply entries to log (simplified)
      new_state = apply_entries(new_state, prev_log_index, prev_log_term, entries)

      # Update commit index
      new_state = update_commit_index(new_state, leader_commit)

      {:keep_state, new_state, actions}
    end
  end

  defp handle_proposal(from, command, state) do
    # Append to log
    entry = {state.current_term, command}
    new_log = state.log ++ [entry]
    new_state = %{state | log: new_log}

    Logger.info("Leader #{state.node_id} appended command: #{inspect(command)}")

    {:keep_state, new_state, [{:reply, from, :ok}]}
  end

  defp apply_entries(state, _prev_log_index, _prev_log_term, entries) do
    # Simplified: just append entries
    # In production, would verify prev_log_index/term match
    %{state | log: state.log ++ entries}
  end

  defp update_commit_index(state, leader_commit) do
    if leader_commit > state.commit_index do
      new_commit_index = min(leader_commit, length(state.log))

      # Apply committed entries to state machine
      new_state_machine = apply_committed(state)

      %{state | commit_index: new_commit_index, state_machine: new_state_machine}
    else
      state
    end
  end

  defp apply_committed(state) do
    # Apply entries from last_applied to commit_index
    Enum.reduce(
      Enum.slice(state.log, state.last_applied..(state.commit_index - 1)),
      state.state_machine,
      fn {_term, command}, sm -> apply_command(sm, command) end
    )
  end

  defp apply_command(state_machine, command) do
    # Apply command to state machine
    Logger.info("Applying command: #{inspect(command)}")
    state_machine
  end

  defp get_log_term(_log, 0), do: 0

  defp get_log_term(log, index) when index > 0 and index <= length(log) do
    {term, _command} = Enum.at(log, index - 1)
    term
  end

  defp get_log_term(_log, _index), do: 0

  defp random_election_timeout do
    :rand.uniform(@election_timeout_max - @election_timeout_min) + @election_timeout_min
  end

  # Network functions (would use actual RPC in production)
  defp send_vote_request(peer, term, candidate_id, last_log_index, last_log_term) do
    # In production, use :rpc.call or similar
    Logger.debug("Sending vote request to #{peer}")
    :ok
  end

  defp send_append_entries(
         peer,
         term,
         leader_id,
         prev_log_index,
         prev_log_term,
         entries,
         leader_commit
       ) do
    # In production, use :rpc.call or similar
    Logger.debug("Sending append entries to #{peer}")
    :ok
  end
end

# Production usage with :ra library
#
# defmodule MyApp.RaftCluster do
#   @cluster_name :my_raft_cluster
#
#   def start_cluster(nodes) do
#     :ra.start_cluster(
#       @cluster_name,
#       {:module, MyApp.RaftStateMachine, []},
#       nodes,
#       %{}
#     )
#   end
#
#   def command(command) do
#     :ra.process_command(@cluster_name, command, 5_000)
#   end
#
#   def query(query) do
#     :ra.local_query(@cluster_name, query, 5_000)
#   end
# end
#
# defmodule MyApp.RaftStateMachine do
#   @behaviour :ra_machine
#
#   @impl true
#   def init(_config), do: %{}
#
#   @impl true
#   def apply(_meta, command, state) do
#     case command do
#       {:put, key, value} -> 
#         {{:ok, key}, Map.put(state, key, value)}
#       {:get, key} ->
#         {{:ok, Map.get(state, key)}, state}
#     end
#   end
#
#   @impl true
#   def state_enter(_term, _state), do: :ok
# end
