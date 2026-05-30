import { AppError } from "../errors/AppError.ts";
import type { GroupLetter } from "../contracts/enums.ts";

export type RoundOf32FixedSlot = {
  matchCode: string;
  order: number;
  teamA: string;
  teamB: string;
  allowedThirdGroups?: GroupLetter[];
};

/*
  FWC26 Regulations, Article 12.6.
  Os confrontos que dependem dos terceiros devem ser resolvidos com Annexe C.
*/
export const ROUND_OF_32_FIXED_SLOTS: RoundOf32FixedSlot[] = [
  { matchCode: "M73", order: 1, teamA: "2A", teamB: "2B" },
  { matchCode: "M74", order: 2, teamA: "1E", teamB: "BEST_3RD_ABCDF", allowedThirdGroups: ["A", "B", "C", "D", "F"] },
  { matchCode: "M75", order: 3, teamA: "1F", teamB: "2C" },
  { matchCode: "M76", order: 4, teamA: "1C", teamB: "2F" },
  { matchCode: "M77", order: 5, teamA: "1I", teamB: "BEST_3RD_CDFGH", allowedThirdGroups: ["C", "D", "F", "G", "H"] },
  { matchCode: "M78", order: 6, teamA: "2E", teamB: "2I" },
  { matchCode: "M79", order: 7, teamA: "1A", teamB: "BEST_3RD_CEFHI", allowedThirdGroups: ["C", "E", "F", "H", "I"] },
  { matchCode: "M80", order: 8, teamA: "1L", teamB: "BEST_3RD_EHIJK", allowedThirdGroups: ["E", "H", "I", "J", "K"] },
  { matchCode: "M81", order: 9, teamA: "1D", teamB: "BEST_3RD_BEFIJ", allowedThirdGroups: ["B", "E", "F", "I", "J"] },
  { matchCode: "M82", order: 10, teamA: "1G", teamB: "BEST_3RD_AEHIJ", allowedThirdGroups: ["A", "E", "H", "I", "J"] },
  { matchCode: "M83", order: 11, teamA: "2K", teamB: "2L" },
  { matchCode: "M84", order: 12, teamA: "1H", teamB: "2J" },
  { matchCode: "M85", order: 13, teamA: "1B", teamB: "BEST_3RD_EFGIJ", allowedThirdGroups: ["E", "F", "G", "I", "J"] },
  { matchCode: "M86", order: 14, teamA: "1J", teamB: "2H" },
  { matchCode: "M87", order: 15, teamA: "1K", teamB: "BEST_3RD_DEIJL", allowedThirdGroups: ["D", "E", "I", "J", "L"] },
  { matchCode: "M88", order: 16, teamA: "2D", teamB: "2G" }
];

export type ThirdPlaceMatrixAssignment = {
  slotCode: string;
  thirdGroup: GroupLetter;
};

export type ThirdPlaceMatrixRule = {
  combinationKey: string;
  assignments: ThirdPlaceMatrixAssignment[];
};

export function buildThirdPlaceCombinationKey(groups: GroupLetter[]): string {
  return [...groups].sort().join("");
}

export function validateThirdPlaceMatrixRule(rule: ThirdPlaceMatrixRule): void {
  const combinationGroups = buildThirdPlaceCombinationKey(
    rule.combinationKey.split("") as GroupLetter[]
  );

  if (combinationGroups !== rule.combinationKey) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Chave de combinação de terceiros precisa estar ordenada.",
      statusCode: 422
    });
  }

  if (rule.assignments.length !== 8) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Regra da matriz de terceiros precisa possuir oito atribuições.",
      statusCode: 422
    });
  }

  const assignedGroups = new Set(rule.assignments.map((assignment) => assignment.thirdGroup));

  if (assignedGroups.size !== 8) {
    throw new AppError({
      code: "VALIDATION_ERROR",
      message: "Regra da matriz de terceiros não pode repetir grupos.",
      statusCode: 422
    });
  }

  const allowedSlotCodes = new Set(
    ROUND_OF_32_FIXED_SLOTS
      .filter((slot) => slot.allowedThirdGroups)
      .map((slot) => slot.teamB)
  );

  for (const assignment of rule.assignments) {
    if (!allowedSlotCodes.has(assignment.slotCode)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Regra da matriz aponta para slot inexistente de terceiro colocado.",
        statusCode: 422,
        details: assignment
      });
    }

    const fixedSlot = ROUND_OF_32_FIXED_SLOTS.find((slot) => slot.teamB === assignment.slotCode);

    if (!fixedSlot?.allowedThirdGroups?.includes(assignment.thirdGroup)) {
      throw new AppError({
        code: "VALIDATION_ERROR",
        message: "Grupo terceiro atribuído a slot onde ele não é permitido pelo Artigo 12.6.",
        statusCode: 422,
        details: assignment
      });
    }
  }
}

export function resolveThirdPlaceAssignments(
  bestThirdGroups: GroupLetter[],
  rules: ThirdPlaceMatrixRule[]
): ThirdPlaceMatrixAssignment[] {
  const combinationKey = buildThirdPlaceCombinationKey(bestThirdGroups);
  const rule = rules.find((candidate) => candidate.combinationKey === combinationKey);

  if (!rule) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message:
        "Combinação oficial da matriz de terceiros não encontrada. Carregue Annexe C completo antes de resolver os 16-avos.",
      statusCode: 500,
      details: {
        combinationKey
      }
    });
  }

  validateThirdPlaceMatrixRule(rule);

  return rule.assignments;
}
