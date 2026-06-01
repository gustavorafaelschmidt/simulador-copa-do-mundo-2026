import type { VisualDemoGroup, VisualDemoTeam } from "./visualDemoData.ts";

export type QualifiedTeamSeed = {
  id: string;
  fifaCode: string;
  name: string;
  shortName: string;
  flag: string;
  countryCode: string;
  seed: number;
};

export type QualifiedGroupSeed = {
  letter: string;
  name: string;
  teams: QualifiedTeamSeed[];
};

export function getFlagImageUrl(countryCode: string): string {
  return `https://flagcdn.com/${countryCode.toLowerCase()}.svg`;
}

function team(teamSeed: QualifiedTeamSeed): VisualDemoTeam {
  return {
    ...teamSeed,
    flagImageUrl: getFlagImageUrl(teamSeed.countryCode)
  };
}

/*
  Dados visuais baseados na tabela pública de grupos da Copa do Mundo 2026.
  Não usamos escudos/logos de federações, pois esses assets podem ser protegidos.
  Usamos bandeiras nacionais via country code + fallback em emoji.
*/
export const worldCup2026QualifiedGroups: VisualDemoGroup[] = [
  {
    letter: "A",
    name: "Grupo A",
    teams: [
      team({ id: "MEX", fifaCode: "MEX", name: "México", shortName: "MEX", flag: "🇲🇽", countryCode: "mx", seed: 1 }),
      team({ id: "RSA", fifaCode: "RSA", name: "África do Sul", shortName: "AFS", flag: "🇿🇦", countryCode: "za", seed: 2 }),
      team({ id: "KOR", fifaCode: "KOR", name: "Coreia do Sul", shortName: "COR", flag: "🇰🇷", countryCode: "kr", seed: 3 }),
      team({ id: "CZE", fifaCode: "CZE", name: "República Tcheca", shortName: "TCH", flag: "🇨🇿", countryCode: "cz", seed: 4 })
    ]
  },
  {
    letter: "B",
    name: "Grupo B",
    teams: [
      team({ id: "CAN", fifaCode: "CAN", name: "Canadá", shortName: "CAN", flag: "🇨🇦", countryCode: "ca", seed: 1 }),
      team({ id: "BIH", fifaCode: "BIH", name: "Bósnia", shortName: "BOS", flag: "🇧🇦", countryCode: "ba", seed: 2 }),
      team({ id: "QAT", fifaCode: "QAT", name: "Catar", shortName: "CAT", flag: "🇶🇦", countryCode: "qa", seed: 3 }),
      team({ id: "SUI", fifaCode: "SUI", name: "Suíça", shortName: "SUI", flag: "🇨🇭", countryCode: "ch", seed: 4 })
    ]
  },
  {
    letter: "C",
    name: "Grupo C",
    teams: [
      team({ id: "BRA", fifaCode: "BRA", name: "Brasil", shortName: "BRA", flag: "🇧🇷", countryCode: "br", seed: 1 }),
      team({ id: "MAR", fifaCode: "MAR", name: "Marrocos", shortName: "MAR", flag: "🇲🇦", countryCode: "ma", seed: 2 }),
      team({ id: "HAI", fifaCode: "HAI", name: "Haiti", shortName: "HAI", flag: "🇭🇹", countryCode: "ht", seed: 3 }),
      team({ id: "SCO", fifaCode: "SCO", name: "Escócia", shortName: "ESC", flag: "🏴󠁧󠁢󠁳󠁣󠁴󠁿", countryCode: "gb-sct", seed: 4 })
    ]
  },
  {
    letter: "D",
    name: "Grupo D",
    teams: [
      team({ id: "USA", fifaCode: "USA", name: "Estados Unidos", shortName: "EUA", flag: "🇺🇸", countryCode: "us", seed: 1 }),
      team({ id: "PAR", fifaCode: "PAR", name: "Paraguai", shortName: "PAR", flag: "🇵🇾", countryCode: "py", seed: 2 }),
      team({ id: "AUS", fifaCode: "AUS", name: "Austrália", shortName: "AUS", flag: "🇦🇺", countryCode: "au", seed: 3 }),
      team({ id: "TUR", fifaCode: "TUR", name: "Turquia", shortName: "TUR", flag: "🇹🇷", countryCode: "tr", seed: 4 })
    ]
  },
  {
    letter: "E",
    name: "Grupo E",
    teams: [
      team({ id: "GER", fifaCode: "GER", name: "Alemanha", shortName: "ALE", flag: "🇩🇪", countryCode: "de", seed: 1 }),
      team({ id: "CUW", fifaCode: "CUW", name: "Curaçao", shortName: "CUR", flag: "🇨🇼", countryCode: "cw", seed: 2 }),
      team({ id: "CIV", fifaCode: "CIV", name: "Costa do Marfim", shortName: "CDM", flag: "🇨🇮", countryCode: "ci", seed: 3 }),
      team({ id: "ECU", fifaCode: "ECU", name: "Equador", shortName: "EQU", flag: "🇪🇨", countryCode: "ec", seed: 4 })
    ]
  },
  {
    letter: "F",
    name: "Grupo F",
    teams: [
      team({ id: "NED", fifaCode: "NED", name: "Holanda", shortName: "HOL", flag: "🇳🇱", countryCode: "nl", seed: 1 }),
      team({ id: "JPN", fifaCode: "JPN", name: "Japão", shortName: "JAP", flag: "🇯🇵", countryCode: "jp", seed: 2 }),
      team({ id: "SWE", fifaCode: "SWE", name: "Suécia", shortName: "SUE", flag: "🇸🇪", countryCode: "se", seed: 3 }),
      team({ id: "TUN", fifaCode: "TUN", name: "Tunísia", shortName: "TUN", flag: "🇹🇳", countryCode: "tn", seed: 4 })
    ]
  },
  {
    letter: "G",
    name: "Grupo G",
    teams: [
      team({ id: "BEL", fifaCode: "BEL", name: "Bélgica", shortName: "BEL", flag: "🇧🇪", countryCode: "be", seed: 1 }),
      team({ id: "EGY", fifaCode: "EGY", name: "Egito", shortName: "EGI", flag: "🇪🇬", countryCode: "eg", seed: 2 }),
      team({ id: "IRN", fifaCode: "IRN", name: "Irã", shortName: "IRA", flag: "🇮🇷", countryCode: "ir", seed: 3 }),
      team({ id: "NZL", fifaCode: "NZL", name: "Nova Zelândia", shortName: "NZL", flag: "🇳🇿", countryCode: "nz", seed: 4 })
    ]
  },
  {
    letter: "H",
    name: "Grupo H",
    teams: [
      team({ id: "ESP", fifaCode: "ESP", name: "Espanha", shortName: "ESP", flag: "🇪🇸", countryCode: "es", seed: 1 }),
      team({ id: "CPV", fifaCode: "CPV", name: "Cabo Verde", shortName: "CVE", flag: "🇨🇻", countryCode: "cv", seed: 2 }),
      team({ id: "KSA", fifaCode: "KSA", name: "Arábia Saudita", shortName: "SAU", flag: "🇸🇦", countryCode: "sa", seed: 3 }),
      team({ id: "URU", fifaCode: "URU", name: "Uruguai", shortName: "URU", flag: "🇺🇾", countryCode: "uy", seed: 4 })
    ]
  },
  {
    letter: "I",
    name: "Grupo I",
    teams: [
      team({ id: "FRA", fifaCode: "FRA", name: "França", shortName: "FRA", flag: "🇫🇷", countryCode: "fr", seed: 1 }),
      team({ id: "SEN", fifaCode: "SEN", name: "Senegal", shortName: "SEN", flag: "🇸🇳", countryCode: "sn", seed: 2 }),
      team({ id: "IRQ", fifaCode: "IRQ", name: "Iraque", shortName: "IRQ", flag: "🇮🇶", countryCode: "iq", seed: 3 }),
      team({ id: "NOR", fifaCode: "NOR", name: "Noruega", shortName: "NOR", flag: "🇳🇴", countryCode: "no", seed: 4 })
    ]
  },
  {
    letter: "J",
    name: "Grupo J",
    teams: [
      team({ id: "ARG", fifaCode: "ARG", name: "Argentina", shortName: "ARG", flag: "🇦🇷", countryCode: "ar", seed: 1 }),
      team({ id: "ALG", fifaCode: "ALG", name: "Argélia", shortName: "ARG", flag: "🇩🇿", countryCode: "dz", seed: 2 }),
      team({ id: "AUT", fifaCode: "AUT", name: "Áustria", shortName: "AUS", flag: "🇦🇹", countryCode: "at", seed: 3 }),
      team({ id: "JOR", fifaCode: "JOR", name: "Jordânia", shortName: "JOR", flag: "🇯🇴", countryCode: "jo", seed: 4 })
    ]
  },
  {
    letter: "K",
    name: "Grupo K",
    teams: [
      team({ id: "POR", fifaCode: "POR", name: "Portugal", shortName: "POR", flag: "🇵🇹", countryCode: "pt", seed: 1 }),
      team({ id: "COD", fifaCode: "COD", name: "RD Congo", shortName: "RDC", flag: "🇨🇩", countryCode: "cd", seed: 2 }),
      team({ id: "UZB", fifaCode: "UZB", name: "Uzbequistão", shortName: "UZB", flag: "🇺🇿", countryCode: "uz", seed: 3 }),
      team({ id: "COL", fifaCode: "COL", name: "Colômbia", shortName: "COL", flag: "🇨🇴", countryCode: "co", seed: 4 })
    ]
  },
  {
    letter: "L",
    name: "Grupo L",
    teams: [
      team({ id: "ENG", fifaCode: "ENG", name: "Inglaterra", shortName: "ING", flag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", countryCode: "gb-eng", seed: 1 }),
      team({ id: "CRO", fifaCode: "CRO", name: "Croácia", shortName: "CRO", flag: "🇭🇷", countryCode: "hr", seed: 2 }),
      team({ id: "GHA", fifaCode: "GHA", name: "Gana", shortName: "GAN", flag: "🇬🇭", countryCode: "gh", seed: 3 }),
      team({ id: "PAN", fifaCode: "PAN", name: "Panamá", shortName: "PAN", flag: "🇵🇦", countryCode: "pa", seed: 4 })
    ]
  }
];

export const worldCup2026QualifiedTeamNames = new Set(
  worldCup2026QualifiedGroups.flatMap((group) => group.teams.map((teamData) => teamData.name))
);

export const worldCup2026QualifiedFifaCodes = new Set(
  worldCup2026QualifiedGroups.flatMap((group) => group.teams.map((teamData) => teamData.fifaCode))
);

export const fifaCodeToCountryCode = new Map(
  worldCup2026QualifiedGroups.flatMap((group) =>
    group.teams.map((teamData) => [teamData.fifaCode, teamData.countryCode] as const)
  )
);

export const fifaCodeToFlagEmoji = new Map(
  worldCup2026QualifiedGroups.flatMap((group) =>
    group.teams.map((teamData) => [teamData.fifaCode, teamData.flag] as const)
  )
);
