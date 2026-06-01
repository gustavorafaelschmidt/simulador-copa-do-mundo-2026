import { describe, expect, it } from "vitest";
import {
  buildVisualBracketRounds,
  buildVisualRoundOf32,
  getVisualChampion
} from "../lib/fifa/visualBracketHelpers.ts";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";
import type { VisualGroupPicks } from "../lib/fifa/visualDemoHelpers.ts";

function fullGroupPicks(): VisualGroupPicks {
  return Object.fromEntries(
    visualDemoGroups.map((group) => [
      group.letter,
      {
        first: `${group.letter}1`,
        second: `${group.letter}2`,
        third: `${group.letter}3`
      }
    ])
  );
}

describe("visual bracket helpers", () => {
  it("deve montar 16 confrontos iniciais", () => {
    expect(buildVisualRoundOf32(visualDemoGroups, fullGroupPicks())).toHaveLength(16);
  });

  it("deve propagar vencedores até a final", () => {
    const groupPicks = fullGroupPicks();
    let rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, {});
    const bracketPicks: Record<string, string> = {};

    for (const match of rounds.round32) {
      if (match.homeTeam) {
        bracketPicks[match.id] = match.homeTeam.id;
      }
    }

    rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

    expect(rounds.round16[0]?.homeTeam).not.toBeNull();
  });

  it("deve retornar campeão quando final estiver escolhida", () => {
    const groupPicks = fullGroupPicks();
    let rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, {});
    const bracketPicks: Record<string, string> = {};

    for (const roundKey of ["round32", "round16", "quarterFinals", "semiFinals", "final"] as const) {
      rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

      for (const match of rounds[roundKey]) {
        const winner = match.homeTeam ?? match.awayTeam;

        if (winner) {
          bracketPicks[match.id] = winner.id;
        }
      }
    }

    rounds = buildVisualBracketRounds(visualDemoGroups, groupPicks, bracketPicks);

    expect(getVisualChampion(rounds, bracketPicks)).not.toBeNull();
  });
});
