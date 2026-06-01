import type { VisualDemoGroup, VisualDemoTeam } from "./visualDemoData.ts";

export type VisualPickPosition = "first" | "second" | "third";

export type VisualGroupPick = {
  first?: string;
  second?: string;
  third?: string;
};

export type VisualGroupPicks = Record<string, VisualGroupPick>;

export type VisualQualifiedTeam = {
  groupLetter: string;
  position: 1 | 2 | 3;
  team: VisualDemoTeam;
};

export function chooseVisualTeam(
  currentPick: VisualGroupPick,
  position: VisualPickPosition,
  teamId: string
): VisualGroupPick {
  const nextPick: VisualGroupPick = {};

  for (const key of ["first", "second", "third"] as const) {
    const value = currentPick[key];

    if (value && value !== teamId) {
      nextPick[key] = value;
    }
  }

  if (currentPick[position] === teamId) {
    delete nextPick[position];
    return nextPick;
  }

  nextPick[position] = teamId;

  return nextPick;
}

export function buildVisualQualifiedTeams(
  groups: VisualDemoGroup[],
  picks: VisualGroupPicks
): VisualQualifiedTeam[] {
  const qualified: VisualQualifiedTeam[] = [];

  for (const group of groups) {
    const pick = picks[group.letter] ?? {};
    const entries = [
      ["first", 1],
      ["second", 2],
      ["third", 3]
    ] as const;

    for (const [key, position] of entries) {
      const teamId = pick[key];
      const team = group.teams.find((candidate) => candidate.id === teamId);

      if (team) {
        qualified.push({
          groupLetter: group.letter,
          position,
          team
        });
      }
    }
  }

  return qualified;
}

export function countCompletedGroups(groups: VisualDemoGroup[], picks: VisualGroupPicks): number {
  return groups.filter((group) => {
    const pick = picks[group.letter];

    return Boolean(pick?.first && pick.second && pick.third);
  }).length;
}

export function getDemoBestThirdPlacedTeams(
  groups: VisualDemoGroup[],
  picks: VisualGroupPicks
): VisualQualifiedTeam[] {
  return buildVisualQualifiedTeams(groups, picks)
    .filter((qualified) => qualified.position === 3)
    .slice(0, 8);
}
