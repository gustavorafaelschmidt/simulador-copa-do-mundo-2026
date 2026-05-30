/*
  Rotas canônicas do projeto.

  Regra:
  - páginas públicas e privadas devem importar daqui quando fizer sentido;
  - evitar strings soltas em redirects, links e Server Actions.
*/

export const APP_ROUTES = {
  HOME: "/",
  LOGIN: "/entrar",
  REGISTER: "/cadastro",
  ONBOARDING: "/onboarding",
  DASHBOARD: "/dashboard",
  GAMIFICATION: "/dashboard/gamificacao",
  PREDICTIONS: "/dashboard/previsoes",
  PREDICTIONS_GROUPS: "/dashboard/previsoes/grupos",
  PREDICTIONS_KNOCKOUT: "/dashboard/previsoes/mata-mata",

  TEAMS: "/equipes",
  TEAM_DETAILS: (teamId: string) => `/equipes/${teamId}`,

  RANKING: "/ranking",
  RANKING_INDIVIDUAL: "/ranking/individual",
  RANKING_TEAMS: "/ranking/equipes",

  SETTINGS: "/configuracoes",
  PROFILE_SETTINGS: "/configuracoes/perfil",

  ADMIN: "/admin",
  ADMIN_RESULTS: "/admin/resultados",
  ADMIN_STATS: "/admin/estatisticas"
} as const;

export const API_ROUTES = {
  HEALTH: "/api/health",
  AUTH: "/api/auth",

  TEAMS: "/api/equipes",
  TEAM_BY_ID: (teamId: string) => `/api/equipes/${teamId}`,
  TEAM_INVITES: (teamId: string) => `/api/equipes/${teamId}/convites`,

  RANKING_INDIVIDUAL: "/api/ranking/individual",
  RANKING_TEAMS: "/api/ranking/equipes",

  ADMIN_RESULTS: "/api/admin/resultados"
} as const;
