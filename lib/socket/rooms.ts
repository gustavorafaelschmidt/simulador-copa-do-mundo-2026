export function getTeamRoomName(teamId: string): string {
  return `team:${teamId}`;
}

export function getVotingSessionRoomName(votingSessionId: string): string {
  return `voting_session:${votingSessionId}`;
}
