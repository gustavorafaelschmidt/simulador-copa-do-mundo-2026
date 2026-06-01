import { describe, expect, it } from "vitest";
import {
  buildVisualProgressSummary,
  clampVisualProgressPercentage,
  getVisualTotalBracketMatches
} from "../lib/fifa/visualProgress.ts";
import { visualDemoGroups } from "../lib/fifa/visualDemoData.ts";

describe("visual progress helpers", () => {
  it("deve calcular total de jogos do mata-mata visual", () => {
    expect(getVisualTotalBracketMatches()).toBe(31);
  });

  it("deve limitar percentual visual", () => {
    expect(clampVisualProgressPercentage(-10)).toBe(0);
    expect(clampVisualProgressPercentage(55.4)).toBe(55);
    expect(clampVisualProgressPercentage(110)).toBe(100);
  });

  it("deve montar resumo de progresso", () => {
    const summary = buildVisualProgressSummary({
      groups: visualDemoGroups,
      groupPicks: {
        A: {
          first: "A1",
          second: "A2",
          third: "A3"
        }
      },
      bracketPicks: {
        "round32-0": "A2"
      }
    });

    expect(summary.completedGroups).toBe(1);
    expect(summary.totalGroups).toBe(12);
    expect(summary.totalBracketMatches).toBe(31);
    expect(summary.completionPercentage).toBeGreaterThan(0);
  });
});
