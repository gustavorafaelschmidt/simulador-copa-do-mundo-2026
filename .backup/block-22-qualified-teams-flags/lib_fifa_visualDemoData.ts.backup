export type VisualDemoTeam = {
  id: string;
  name: string;
  shortName: string;
  flag: string;
  seed: number;
};

export type VisualDemoGroup = {
  letter: string;
  name: string;
  teams: VisualDemoTeam[];
};

const flags = ["🇧🇷", "🇦🇷", "🇫🇷", "🇪🇸", "🇩🇪", "🇮🇹", "🇵🇹", "🇳🇱", "🇺🇸", "🇲🇽", "🇯🇵", "🇰🇷"];

const teamNames = [
  ["Brasil", "Canadá", "Marrocos", "Escócia"],
  ["Argentina", "Egito", "Austrália", "Noruega"],
  ["França", "Uruguai", "Gana", "Panamá"],
  ["Espanha", "Colômbia", "Tunísia", "Nova Zelândia"],
  ["Alemanha", "Chile", "Japão", "Catar"],
  ["Itália", "México", "Senegal", "Costa Rica"],
  ["Portugal", "Estados Unidos", "África do Sul", "Arábia Saudita"],
  ["Holanda", "Croácia", "Coreia do Sul", "Jamaica"],
  ["Inglaterra", "Paraguai", "Irã", "Honduras"],
  ["Bélgica", "Suíça", "Equador", "Iraque"],
  ["Dinamarca", "Sérvia", "Peru", "China"],
  ["Suécia", "Polônia", "Nigéria", "Bolívia"]
];

export const visualDemoGroups: VisualDemoGroup[] = teamNames.map((teams, groupIndex) => {
  const letter = String.fromCharCode(65 + groupIndex);

  return {
    letter,
    name: `Grupo ${letter}`,
    teams: teams.map((name, teamIndex) => ({
      id: `${letter}${teamIndex + 1}`,
      name,
      shortName: name.slice(0, 3).toUpperCase(),
      flag: flags[(groupIndex + teamIndex) % flags.length] ?? "🏳️",
      seed: teamIndex + 1
    }))
  };
});
