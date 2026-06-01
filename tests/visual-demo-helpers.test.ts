import { describe, expect, it } from "vitest";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";
import {
  buildVisualQualifiedTeams,
  chooseVisualTeam,
  countCompletedGroups,
  getDemoBestThirdPlacedTeams
} from "../lib/fifa/visualDemoHelpers.ts";

describe("visual demo helpers", () => {
  it("deve selecionar uma equipe por posição e remover duplicidade", () => {
    const firstPick = chooseVisualTeam({}, "first", "A1");
    const secondPick = chooseVisualTeam(firstPick, "second", "A1");

    expect(secondPick).toEqual({
      second: "A1"
    });
  });

  it("deve contar grupos completos", () => {
    expect(
      countCompletedGroups(visualDemoGroups, {
        A: {
          first: "A1",
          second: "A2",
          third: "A3"
        }
      })
    ).toBe(1);
  });

  it("deve montar classificados visuais", () => {
    const qualified = buildVisualQualifiedTeams(visualDemoGroups, {
      A: {
        first: "A1",
        second: "A2",
        third: "A3"
      }
    });

    expect(qualified).toHaveLength(3);
    expect(qualified[0]?.team.name).toBe("Brasil");
  });

  it("deve limitar terceiros demo a oito seleções", () => {
    const picks = Object.fromEntries(
      visualDemoGroups.map((group) => [
        group.letter,
        {
          first: `${group.letter}1`,
          second: `${group.letter}2`,
          third: `${group.letter}3`
        }
      ])
    );

    expect(getDemoBestThirdPlacedTeams(visualDemoGroups, picks)).toHaveLength(8);
  });
});
