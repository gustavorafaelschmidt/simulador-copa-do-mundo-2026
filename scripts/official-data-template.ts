import { writeFileSync } from "node:fs";
import { GROUP_LETTER_VALUES } from "../lib/contracts/enums.ts";

const manifest = {
  source: {
    code: "FWC26_OFFICIAL_TEMPLATE",
    description:
      "Template para importação de dados oficiais. Substitua por dados oficiais FIFA antes de produção.",
    sourceDocumentRef: "FWC26_regulations_EN.pdf",
    status: "PARTIAL"
  },
  groups: GROUP_LETTER_VALUES.map((letter) => ({
    letter,
    name: `Grupo ${letter}`
  })),
  teams: [],
  matches: [],
  bracketSlots: [],
  thirdPlaceMatrix: []
};

writeFileSync("docs/official-data-template.json", `${JSON.stringify(manifest, null, 2)}\n`);

console.log("Template criado em docs/official-data-template.json");
