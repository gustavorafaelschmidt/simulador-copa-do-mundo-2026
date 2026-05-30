import { describe, expect, it } from "vitest";
import { AppError } from "../lib/errors/AppError.ts";
import { GROUP_LETTER_VALUES } from "../lib/contracts/enums.ts";
import {
  assertOfficialImportManifestConsistency,
  parseOfficialDataManifest
} from "../lib/fifa/official-import/index.ts";

const validPartialManifest = {
  source: {
    code: "FWC26_TEST_PARTIAL",
    description: "Manifesto parcial de teste.",
    sourceDocumentRef: "FWC26_regulations_EN.pdf",
    status: "PARTIAL"
  },
  groups: GROUP_LETTER_VALUES.map((letter) => ({
    letter,
    name: `Grupo ${letter}`
  })),
  teams: GROUP_LETTER_VALUES.flatMap((letter) =>
    [1, 2, 3, 4].map((position) => ({
      fifaCode: `${letter}${position}`,
      name: `Team ${letter}${position}`,
      shortName: `T${letter}${position}`,
      group: letter,
      groupPosition: position
    }))
  ),
  matches: [],
  bracketSlots: [],
  thirdPlaceMatrix: []
};

describe("official data import", () => {
  it("deve validar manifesto parcial consistente em desenvolvimento", () => {
    expect(() => parseOfficialDataManifest(validPartialManifest)).not.toThrow();
  });

  it("deve rejeitar grupos incompletos", () => {
    expect(() =>
      parseOfficialDataManifest({
        ...validPartialManifest,
        groups: validPartialManifest.groups.slice(0, 11)
      })
    ).toThrow();
  });

  it("deve rejeitar seleção duplicada por código FIFA", () => {
    expect(() =>
      assertOfficialImportManifestConsistency({
        ...validPartialManifest,
        teams: [
          ...validPartialManifest.teams,
          {
            fifaCode: "A1",
            name: "Duplicado",
            shortName: "Dup",
            group: "A",
            groupPosition: 1
          }
        ]
      })
    ).toThrow(AppError);
  });

  it("deve rejeitar regra de matriz com chave incoerente", () => {
    expect(() =>
      parseOfficialDataManifest({
        ...validPartialManifest,
        thirdPlaceMatrix: [
          {
            combinationKey: "ABCDEFGH",
            qualifiedThirdGroups: ["A", "B", "C", "D", "E", "F", "G", "I"],
            slotAssignments: {}
          }
        ]
      })
    ).toThrow(AppError);
  });
});
