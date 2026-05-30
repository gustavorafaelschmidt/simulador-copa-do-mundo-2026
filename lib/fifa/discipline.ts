export type TeamDisciplinaryRecord = {
  yellowCards: number;
  indirectRedCards: number;
  directRedCards: number;
  yellowAndDirectRedCards: number;
};

/*
  FWC26 Regulations, Article 13:
  - yellow card: minus 1 point
  - indirect red card: minus 3 points
  - direct red card: minus 4 points
  - yellow card and direct red card: minus 5 points

  Quanto maior o score final, melhor o team conduct.
*/
export function calculateTeamConductScore(record: TeamDisciplinaryRecord): number {
  return (
    record.yellowCards * -1 +
    record.indirectRedCards * -3 +
    record.directRedCards * -4 +
    record.yellowAndDirectRedCards * -5
  );
}
