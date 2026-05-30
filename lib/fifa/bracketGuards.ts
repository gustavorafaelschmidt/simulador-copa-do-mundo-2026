import { OFFICIAL_DATA_STATUS } from "@/lib/contracts/enums";
import { AppError } from "@/lib/errors/AppError";
import type { BracketSlotDescriptor } from "@/lib/fifa/types";

type ThirdPlaceMatrixRuleLike = {
  combinationKey: string;
  officialDataStatus: string;
  officialDataVersionId: string | null;
};

export function assertBracketSlotsAreOfficial(slots: Array<BracketSlotDescriptor & {
  officialDataStatus?: string;
  officialDataVersionId?: string | null;
}>): void {
  const invalidSlots = slots.filter(
    (slot) =>
      slot.officialDataStatus !== undefined &&
      slot.officialDataStatus !== OFFICIAL_DATA_STATUS.OFFICIAL
  );

  if (invalidSlots.length > 0) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Slots de mata-mata oficiais ainda não estão disponíveis.",
      statusCode: 500,
      details: {
        invalidSlotCodes: invalidSlots.map((slot) => slot.slotCode)
      }
    });
  }
}

export function assertThirdPlaceMatrixIsOfficial(
  rules: ThirdPlaceMatrixRuleLike[]
): void {
  if (rules.length === 0) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Matriz oficial dos terceiros colocados não foi carregada.",
      statusCode: 500
    });
  }

  const invalidRules = rules.filter(
    (rule) =>
      rule.officialDataStatus !== OFFICIAL_DATA_STATUS.OFFICIAL ||
      !rule.officialDataVersionId
  );

  if (invalidRules.length > 0) {
    throw new AppError({
      code: "OFFICIAL_DATA_UNAVAILABLE",
      message: "Matriz dos terceiros colocados possui regras não oficiais ou sem versão.",
      statusCode: 500,
      details: {
        invalidCombinationKeys: invalidRules.map((rule) => rule.combinationKey)
      }
    });
  }
}
