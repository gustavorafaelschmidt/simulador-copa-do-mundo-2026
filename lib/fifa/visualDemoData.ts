export type VisualDemoTeam = {
  id: string;
  fifaCode?: string;
  name: string;
  shortName: string;
  flag: string;
  countryCode?: string;
  flagImageUrl?: string;
  seed: number;
};

export type VisualDemoGroup = {
  letter: string;
  name: string;
  teams: VisualDemoTeam[];
};

export { worldCup2026QualifiedGroups as visualDemoGroups } from "./worldCup2026QualifiedTeams.ts";
