import type { NationalTeamDTO } from "../../lib/contracts/officialData.ts";

type NationalTeamOptionLabelProps = {
  team: NationalTeamDTO;
};

export function buildNationalTeamOptionLabel(team: NationalTeamDTO): string {
  const groupPrefix = team.groupLetter ? `Grupo ${team.groupLetter} · ` : "";
  const positionPrefix = team.groupPosition ? `${team.groupPosition}. ` : "";

  return `${groupPrefix}${positionPrefix}${team.shortName}`;
}

export function NationalTeamOptionLabel({ team }: NationalTeamOptionLabelProps) {
  return (
    <span>
      {team.groupPosition ? `${team.groupPosition}. ` : ""}
      {team.shortName}
    </span>
  );
}
