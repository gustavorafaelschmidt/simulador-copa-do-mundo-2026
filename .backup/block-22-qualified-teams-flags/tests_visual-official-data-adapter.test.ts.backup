import { describe, expect, it } from "vitest";
import { normalizeVisualGroupsFromDatabaseRows } from "../lib/fifa/visualOfficialDataAdapter.ts";

describe("visual official data adapter", () => {
  it("deve normalizar linhas do banco para grupos visuais", () => {
    const groups = normalizeVisualGroupsFromDatabaseRows({
      groupRows: [
        {
          id: "group-a",
          letter: "A",
          name: "Grupo A"
        }
      ],
      teamRows: [
        {
          id: "team-a1",
          name: "Brasil",
          short_name: "BRA",
          fifa_code: "BRA",
          flag_emoji: "🇧🇷",
          group_letter: "A",
          seed: 1
        }
      ]
    });

    expect(groups).toHaveLength(12);
    expect(groups[0]?.letter).toBe("A");
    expect(groups[0]?.teams[0]).toMatchObject({
      id: "team-a1",
      name: "Brasil",
      shortName: "BRA",
      flag: "🇧🇷"
    });
  });

  it("deve ignorar seleções sem grupo válido", () => {
    const groups = normalizeVisualGroupsFromDatabaseRows({
      groupRows: [],
      teamRows: [
        {
          id: "invalid",
          name: "Inválida",
          short_name: "INV",
          fifa_code: "INV",
          flag_emoji: null,
          group_letter: "Z",
          seed: 1
        }
      ]
    });

    expect(groups.every((group) => group.teams.length === 0)).toBe(true);
  });
});
