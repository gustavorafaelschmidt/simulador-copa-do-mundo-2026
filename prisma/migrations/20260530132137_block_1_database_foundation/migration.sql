-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('CREDENTIALS', 'GOOGLE');

-- CreateEnum
CREATE TYPE "GlobalRole" AS ENUM ('USER', 'ADMIN_GLOBAL');

-- CreateEnum
CREATE TYPE "TeamMemberRole" AS ENUM ('CAPTAIN', 'ADMIN', 'MEMBER');

-- CreateEnum
CREATE TYPE "TeamMemberApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'REMOVED');

-- CreateEnum
CREATE TYPE "VotingSessionType" AS ENUM ('GROUP_STAGE', 'KNOCKOUT');

-- CreateEnum
CREATE TYPE "VotingSessionStatus" AS ENUM ('DRAFT', 'OPEN', 'TIEBREAKER_REQUIRED', 'CLOSED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "KnockoutPhase" AS ENUM ('ROUND_OF_32', 'ROUND_OF_16', 'QUARTER_FINAL', 'SEMI_FINAL', 'THIRD_PLACE', 'FINAL');

-- CreateEnum
CREATE TYPE "ConsensusDecisionType" AS ENUM ('MAJORITY', 'CAPTAIN_TIEBREAK', 'ADMIN_OVERRIDE');

-- CreateEnum
CREATE TYPE "RankingType" AS ENUM ('INDIVIDUAL', 'TEAM');

-- CreateEnum
CREATE TYPE "RealResultType" AS ENUM ('GROUP_STANDING', 'GROUP_MATCH', 'KNOCKOUT_MATCH', 'CHAMPION', 'RUNNER_UP', 'THIRD_PLACE');

-- CreateEnum
CREATE TYPE "GroupLetter" AS ENUM ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L');

-- CreateEnum
CREATE TYPE "RankingJobStatus" AS ENUM ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "OfficialDataStatus" AS ENUM ('PLACEHOLDER', 'PARTIAL', 'OFFICIAL', 'DEPRECATED');

-- CreateEnum
CREATE TYPE "BadgeTargetType" AS ENUM ('USER', 'TEAM');

-- CreateEnum
CREATE TYPE "BadgeRarity" AS ENUM ('COMMON', 'RARE', 'EPIC', 'LEGENDARY');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "name" TEXT,
    "email" TEXT,
    "email_verified" TIMESTAMP(3),
    "image" TEXT,
    "first_name" TEXT,
    "last_name" TEXT,
    "nickname" TEXT,
    "birth_date" TIMESTAMP(3),
    "password_hash" TEXT,
    "global_role" "GlobalRole" NOT NULL DEFAULT 'USER',
    "primary_auth_provider" "AuthProvider" NOT NULL DEFAULT 'CREDENTIALS',
    "profile_completed_at" TIMESTAMP(3),
    "onboarding_completed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "accounts" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "provider_account_id" TEXT NOT NULL,
    "refresh_token" TEXT,
    "access_token" TEXT,
    "expires_at" INTEGER,
    "token_type" TEXT,
    "scope" TEXT,
    "id_token" TEXT,
    "session_state" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" TEXT NOT NULL,
    "session_token" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,
    "revoked_at" TIMESTAMP(3),
    "ip_address" TEXT,
    "user_agent" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_tokens" (
    "identifier" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_tokens_pkey" PRIMARY KEY ("identifier","token")
);

-- CreateTable
CREATE TABLE "teams" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "invite_code" TEXT NOT NULL,
    "owner_id" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "max_members" INTEGER NOT NULL DEFAULT 20,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "teams_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_members" (
    "id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "role" "TeamMemberRole" NOT NULL DEFAULT 'MEMBER',
    "approval_status" "TeamMemberApprovalStatus" NOT NULL DEFAULT 'PENDING',
    "approved_by_user_id" TEXT,
    "approved_at" TIMESTAMP(3),
    "joined_at" TIMESTAMP(3),
    "removed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "team_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_invites" (
    "id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "created_by_user_id" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3),
    "max_uses" INTEGER,
    "used_count" INTEGER NOT NULL DEFAULT 0,
    "revoked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "team_invites_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "official_data_versions" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" "OfficialDataStatus" NOT NULL DEFAULT 'PLACEHOLDER',
    "source_document_ref" TEXT,
    "imported_at" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "official_data_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tournament_groups" (
    "id" TEXT NOT NULL,
    "letter" "GroupLetter" NOT NULL,
    "name" TEXT NOT NULL,
    "official_data_status" "OfficialDataStatus" NOT NULL DEFAULT 'PLACEHOLDER',
    "official_data_version_id" TEXT,
    "source_document_ref" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tournament_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "national_teams" (
    "id" TEXT NOT NULL,
    "fifa_code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "short_name" TEXT NOT NULL,
    "flag_url" TEXT,
    "group_id" TEXT,
    "group_position" INTEGER,
    "official_data_status" "OfficialDataStatus" NOT NULL DEFAULT 'PLACEHOLDER',
    "official_data_version_id" TEXT,
    "source_document_ref" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "national_teams_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "official_matches" (
    "id" TEXT NOT NULL,
    "match_number" INTEGER,
    "match_code" TEXT NOT NULL,
    "group_id" TEXT,
    "knockout_phase" "KnockoutPhase",
    "bracket_slot_id" TEXT,
    "home_team_id" TEXT,
    "away_team_id" TEXT,
    "home_slot_code" TEXT,
    "away_slot_code" TEXT,
    "starts_at" TIMESTAMP(3),
    "stadium" TEXT,
    "city" TEXT,
    "official_data_status" "OfficialDataStatus" NOT NULL DEFAULT 'PLACEHOLDER',
    "official_data_version_id" TEXT,
    "source_document_ref" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "official_matches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "official_bracket_slots" (
    "id" TEXT NOT NULL,
    "slot_code" TEXT NOT NULL,
    "phase" "KnockoutPhase" NOT NULL,
    "sort_order" INTEGER NOT NULL,
    "source_slot_code_a" TEXT,
    "source_slot_code_b" TEXT,
    "winner_goes_to_slot_code" TEXT,
    "official_data_status" "OfficialDataStatus" NOT NULL DEFAULT 'PLACEHOLDER',
    "official_data_version_id" TEXT,
    "source_document_ref" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "official_bracket_slots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "official_third_place_matrix_rules" (
    "id" TEXT NOT NULL,
    "combination_key" TEXT NOT NULL,
    "qualified_third_groups" "GroupLetter"[],
    "slot_assignments" JSONB NOT NULL,
    "official_data_status" "OfficialDataStatus" NOT NULL DEFAULT 'PLACEHOLDER',
    "official_data_version_id" TEXT,
    "source_document_ref" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "official_third_place_matrix_rules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "individual_group_predictions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "group" "GroupLetter" NOT NULL,
    "first_place_team_id" TEXT NOT NULL,
    "second_place_team_id" TEXT NOT NULL,
    "third_place_team_id" TEXT NOT NULL,
    "fourth_place_team_id" TEXT NOT NULL,
    "locked_at" TIMESTAMP(3),
    "submitted_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "individual_group_predictions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "individual_knockout_predictions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "bracket_slot_id" TEXT NOT NULL,
    "winner_team_id" TEXT NOT NULL,
    "locked_at" TIMESTAMP(3),
    "submitted_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "individual_knockout_predictions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "voting_sessions" (
    "id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "type" "VotingSessionType" NOT NULL,
    "status" "VotingSessionStatus" NOT NULL DEFAULT 'DRAFT',
    "group" "GroupLetter",
    "bracket_slot_id" TEXT,
    "opened_by_user_id" TEXT,
    "closed_by_user_id" TEXT,
    "opened_at" TIMESTAMP(3),
    "closed_at" TIMESTAMP(3),
    "tiebreaker_payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "voting_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_group_votes" (
    "id" TEXT NOT NULL,
    "voting_session_id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "group" "GroupLetter" NOT NULL,
    "first_place_team_id" TEXT NOT NULL,
    "second_place_team_id" TEXT NOT NULL,
    "third_place_team_id" TEXT NOT NULL,
    "fourth_place_team_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "team_group_votes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_knockout_votes" (
    "id" TEXT NOT NULL,
    "voting_session_id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "bracket_slot_id" TEXT NOT NULL,
    "winner_team_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "team_knockout_votes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_group_consensuses" (
    "id" TEXT NOT NULL,
    "voting_session_id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "group" "GroupLetter" NOT NULL,
    "first_place_team_id" TEXT NOT NULL,
    "second_place_team_id" TEXT NOT NULL,
    "third_place_team_id" TEXT NOT NULL,
    "fourth_place_team_id" TEXT NOT NULL,
    "decision_type" "ConsensusDecisionType" NOT NULL,
    "decided_by_user_id" TEXT,
    "decided_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "vote_summary" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "team_group_consensuses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_knockout_consensuses" (
    "id" TEXT NOT NULL,
    "voting_session_id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "bracket_slot_id" TEXT NOT NULL,
    "winner_team_id" TEXT NOT NULL,
    "decision_type" "ConsensusDecisionType" NOT NULL,
    "decided_by_user_id" TEXT,
    "decided_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "vote_summary" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "team_knockout_consensuses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "real_tournament_results" (
    "id" TEXT NOT NULL,
    "result_key" TEXT NOT NULL,
    "type" "RealResultType" NOT NULL,
    "group" "GroupLetter",
    "knockout_phase" "KnockoutPhase",
    "official_match_id" TEXT,
    "bracket_slot_id" TEXT,
    "payload" JSONB NOT NULL,
    "source_document_ref" TEXT,
    "official_data_status" "OfficialDataStatus" NOT NULL DEFAULT 'OFFICIAL',
    "official_data_version_id" TEXT,
    "created_by_user_id" TEXT,
    "updated_by_user_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "real_tournament_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ranking_snapshots" (
    "id" TEXT NOT NULL,
    "type" "RankingType" NOT NULL,
    "calculated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "source_job_id" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ranking_snapshots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ranking_entries" (
    "id" TEXT NOT NULL,
    "snapshot_id" TEXT NOT NULL,
    "ranking_type" "RankingType" NOT NULL,
    "user_id" TEXT,
    "team_id" TEXT,
    "participant_key" TEXT NOT NULL,
    "rank" INTEGER NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0,
    "correct_predictions" INTEGER NOT NULL DEFAULT 0,
    "total_predictions" INTEGER NOT NULL DEFAULT 0,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ranking_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ranking_recalculation_jobs" (
    "id" TEXT NOT NULL,
    "type" "RankingType" NOT NULL,
    "status" "RankingJobStatus" NOT NULL DEFAULT 'PENDING',
    "idempotency_key" TEXT NOT NULL,
    "requested_by_user_id" TEXT,
    "started_at" TIMESTAMP(3),
    "finished_at" TIMESTAMP(3),
    "error_message" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ranking_recalculation_jobs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "badges" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "target_type" "BadgeTargetType" NOT NULL,
    "rarity" "BadgeRarity" NOT NULL DEFAULT 'COMMON',
    "icon_key" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "badges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_badges" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "badge_id" TEXT NOT NULL,
    "awarded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "team_badges" (
    "id" TEXT NOT NULL,
    "team_id" TEXT NOT NULL,
    "badge_id" TEXT NOT NULL,
    "awarded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "team_badges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "global_stat_snapshots" (
    "id" TEXT NOT NULL,
    "stat_key" TEXT NOT NULL,
    "ranking_type" "RankingType",
    "team_id" TEXT,
    "payload" JSONB NOT NULL,
    "calculated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "global_stat_snapshots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "actor_user_id" TEXT,
    "action" TEXT NOT NULL,
    "entity_type" TEXT NOT NULL,
    "entity_id" TEXT,
    "metadata" JSONB,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_nickname_key" ON "users"("nickname");

-- CreateIndex
CREATE INDEX "users_global_role_idx" ON "users"("global_role");

-- CreateIndex
CREATE INDEX "users_profile_completed_at_idx" ON "users"("profile_completed_at");

-- CreateIndex
CREATE INDEX "users_onboarding_completed_at_idx" ON "users"("onboarding_completed_at");

-- CreateIndex
CREATE INDEX "users_created_at_idx" ON "users"("created_at");

-- CreateIndex
CREATE INDEX "accounts_user_id_idx" ON "accounts"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "accounts_provider_provider_account_id_key" ON "accounts"("provider", "provider_account_id");

-- CreateIndex
CREATE UNIQUE INDEX "sessions_session_token_key" ON "sessions"("session_token");

-- CreateIndex
CREATE INDEX "sessions_user_id_idx" ON "sessions"("user_id");

-- CreateIndex
CREATE INDEX "sessions_expires_idx" ON "sessions"("expires");

-- CreateIndex
CREATE INDEX "sessions_session_token_expires_idx" ON "sessions"("session_token", "expires");

-- CreateIndex
CREATE INDEX "verification_tokens_expires_idx" ON "verification_tokens"("expires");

-- CreateIndex
CREATE UNIQUE INDEX "teams_slug_key" ON "teams"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "teams_invite_code_key" ON "teams"("invite_code");

-- CreateIndex
CREATE INDEX "teams_owner_id_idx" ON "teams"("owner_id");

-- CreateIndex
CREATE INDEX "teams_invite_code_idx" ON "teams"("invite_code");

-- CreateIndex
CREATE INDEX "teams_slug_idx" ON "teams"("slug");

-- CreateIndex
CREATE INDEX "teams_created_at_idx" ON "teams"("created_at");

-- CreateIndex
CREATE INDEX "team_members_user_id_idx" ON "team_members"("user_id");

-- CreateIndex
CREATE INDEX "team_members_team_id_approval_status_idx" ON "team_members"("team_id", "approval_status");

-- CreateIndex
CREATE INDEX "team_members_team_id_role_idx" ON "team_members"("team_id", "role");

-- CreateIndex
CREATE UNIQUE INDEX "team_members_team_id_user_id_key" ON "team_members"("team_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "team_invites_code_key" ON "team_invites"("code");

-- CreateIndex
CREATE INDEX "team_invites_team_id_idx" ON "team_invites"("team_id");

-- CreateIndex
CREATE INDEX "team_invites_code_idx" ON "team_invites"("code");

-- CreateIndex
CREATE INDEX "team_invites_expires_at_idx" ON "team_invites"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "official_data_versions_code_key" ON "official_data_versions"("code");

-- CreateIndex
CREATE INDEX "official_data_versions_status_idx" ON "official_data_versions"("status");

-- CreateIndex
CREATE INDEX "official_data_versions_is_active_idx" ON "official_data_versions"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "tournament_groups_letter_key" ON "tournament_groups"("letter");

-- CreateIndex
CREATE INDEX "tournament_groups_official_data_status_idx" ON "tournament_groups"("official_data_status");

-- CreateIndex
CREATE INDEX "tournament_groups_official_data_version_id_idx" ON "tournament_groups"("official_data_version_id");

-- CreateIndex
CREATE UNIQUE INDEX "national_teams_fifa_code_key" ON "national_teams"("fifa_code");

-- CreateIndex
CREATE INDEX "national_teams_group_id_idx" ON "national_teams"("group_id");

-- CreateIndex
CREATE INDEX "national_teams_official_data_status_idx" ON "national_teams"("official_data_status");

-- CreateIndex
CREATE INDEX "national_teams_official_data_version_id_idx" ON "national_teams"("official_data_version_id");

-- CreateIndex
CREATE INDEX "national_teams_name_idx" ON "national_teams"("name");

-- CreateIndex
CREATE UNIQUE INDEX "national_teams_group_id_group_position_key" ON "national_teams"("group_id", "group_position");

-- CreateIndex
CREATE UNIQUE INDEX "official_matches_match_number_key" ON "official_matches"("match_number");

-- CreateIndex
CREATE UNIQUE INDEX "official_matches_match_code_key" ON "official_matches"("match_code");

-- CreateIndex
CREATE INDEX "official_matches_group_id_idx" ON "official_matches"("group_id");

-- CreateIndex
CREATE INDEX "official_matches_knockout_phase_idx" ON "official_matches"("knockout_phase");

-- CreateIndex
CREATE INDEX "official_matches_bracket_slot_id_idx" ON "official_matches"("bracket_slot_id");

-- CreateIndex
CREATE INDEX "official_matches_starts_at_idx" ON "official_matches"("starts_at");

-- CreateIndex
CREATE INDEX "official_matches_official_data_status_idx" ON "official_matches"("official_data_status");

-- CreateIndex
CREATE INDEX "official_matches_official_data_version_id_idx" ON "official_matches"("official_data_version_id");

-- CreateIndex
CREATE UNIQUE INDEX "official_bracket_slots_slot_code_key" ON "official_bracket_slots"("slot_code");

-- CreateIndex
CREATE INDEX "official_bracket_slots_phase_sort_order_idx" ON "official_bracket_slots"("phase", "sort_order");

-- CreateIndex
CREATE INDEX "official_bracket_slots_official_data_status_idx" ON "official_bracket_slots"("official_data_status");

-- CreateIndex
CREATE INDEX "official_bracket_slots_official_data_version_id_idx" ON "official_bracket_slots"("official_data_version_id");

-- CreateIndex
CREATE UNIQUE INDEX "official_third_place_matrix_rules_combination_key_key" ON "official_third_place_matrix_rules"("combination_key");

-- CreateIndex
CREATE INDEX "official_third_place_matrix_rules_official_data_status_idx" ON "official_third_place_matrix_rules"("official_data_status");

-- CreateIndex
CREATE INDEX "official_third_place_matrix_rules_official_data_version_id_idx" ON "official_third_place_matrix_rules"("official_data_version_id");

-- CreateIndex
CREATE INDEX "individual_group_predictions_user_id_idx" ON "individual_group_predictions"("user_id");

-- CreateIndex
CREATE INDEX "individual_group_predictions_group_idx" ON "individual_group_predictions"("group");

-- CreateIndex
CREATE UNIQUE INDEX "individual_group_predictions_user_id_group_key" ON "individual_group_predictions"("user_id", "group");

-- CreateIndex
CREATE INDEX "individual_knockout_predictions_user_id_idx" ON "individual_knockout_predictions"("user_id");

-- CreateIndex
CREATE INDEX "individual_knockout_predictions_bracket_slot_id_idx" ON "individual_knockout_predictions"("bracket_slot_id");

-- CreateIndex
CREATE INDEX "individual_knockout_predictions_winner_team_id_idx" ON "individual_knockout_predictions"("winner_team_id");

-- CreateIndex
CREATE UNIQUE INDEX "individual_knockout_predictions_user_id_bracket_slot_id_key" ON "individual_knockout_predictions"("user_id", "bracket_slot_id");

-- CreateIndex
CREATE INDEX "voting_sessions_team_id_status_idx" ON "voting_sessions"("team_id", "status");

-- CreateIndex
CREATE INDEX "voting_sessions_team_id_type_idx" ON "voting_sessions"("team_id", "type");

-- CreateIndex
CREATE INDEX "voting_sessions_group_idx" ON "voting_sessions"("group");

-- CreateIndex
CREATE INDEX "voting_sessions_bracket_slot_id_idx" ON "voting_sessions"("bracket_slot_id");

-- CreateIndex
CREATE INDEX "voting_sessions_created_at_idx" ON "voting_sessions"("created_at");

-- CreateIndex
CREATE INDEX "team_group_votes_voting_session_id_idx" ON "team_group_votes"("voting_session_id");

-- CreateIndex
CREATE INDEX "team_group_votes_team_id_group_idx" ON "team_group_votes"("team_id", "group");

-- CreateIndex
CREATE INDEX "team_group_votes_user_id_idx" ON "team_group_votes"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "team_group_votes_user_id_voting_session_id_team_id_group_key" ON "team_group_votes"("user_id", "voting_session_id", "team_id", "group");

-- CreateIndex
CREATE INDEX "team_knockout_votes_voting_session_id_idx" ON "team_knockout_votes"("voting_session_id");

-- CreateIndex
CREATE INDEX "team_knockout_votes_team_id_bracket_slot_id_idx" ON "team_knockout_votes"("team_id", "bracket_slot_id");

-- CreateIndex
CREATE INDEX "team_knockout_votes_user_id_idx" ON "team_knockout_votes"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "team_knockout_votes_user_id_voting_session_id_team_id_brack_key" ON "team_knockout_votes"("user_id", "voting_session_id", "team_id", "bracket_slot_id");

-- CreateIndex
CREATE INDEX "team_group_consensuses_team_id_group_idx" ON "team_group_consensuses"("team_id", "group");

-- CreateIndex
CREATE INDEX "team_group_consensuses_decision_type_idx" ON "team_group_consensuses"("decision_type");

-- CreateIndex
CREATE UNIQUE INDEX "team_group_consensuses_team_id_voting_session_id_group_key" ON "team_group_consensuses"("team_id", "voting_session_id", "group");

-- CreateIndex
CREATE INDEX "team_knockout_consensuses_team_id_bracket_slot_id_idx" ON "team_knockout_consensuses"("team_id", "bracket_slot_id");

-- CreateIndex
CREATE INDEX "team_knockout_consensuses_decision_type_idx" ON "team_knockout_consensuses"("decision_type");

-- CreateIndex
CREATE UNIQUE INDEX "team_knockout_consensuses_team_id_voting_session_id_bracket_key" ON "team_knockout_consensuses"("team_id", "voting_session_id", "bracket_slot_id");

-- CreateIndex
CREATE UNIQUE INDEX "real_tournament_results_result_key_key" ON "real_tournament_results"("result_key");

-- CreateIndex
CREATE INDEX "real_tournament_results_type_idx" ON "real_tournament_results"("type");

-- CreateIndex
CREATE INDEX "real_tournament_results_group_idx" ON "real_tournament_results"("group");

-- CreateIndex
CREATE INDEX "real_tournament_results_knockout_phase_idx" ON "real_tournament_results"("knockout_phase");

-- CreateIndex
CREATE INDEX "real_tournament_results_official_match_id_idx" ON "real_tournament_results"("official_match_id");

-- CreateIndex
CREATE INDEX "real_tournament_results_bracket_slot_id_idx" ON "real_tournament_results"("bracket_slot_id");

-- CreateIndex
CREATE INDEX "real_tournament_results_official_data_status_idx" ON "real_tournament_results"("official_data_status");

-- CreateIndex
CREATE INDEX "real_tournament_results_official_data_version_id_idx" ON "real_tournament_results"("official_data_version_id");

-- CreateIndex
CREATE INDEX "ranking_snapshots_type_calculated_at_idx" ON "ranking_snapshots"("type", "calculated_at");

-- CreateIndex
CREATE INDEX "ranking_entries_ranking_type_rank_idx" ON "ranking_entries"("ranking_type", "rank");

-- CreateIndex
CREATE INDEX "ranking_entries_user_id_idx" ON "ranking_entries"("user_id");

-- CreateIndex
CREATE INDEX "ranking_entries_team_id_idx" ON "ranking_entries"("team_id");

-- CreateIndex
CREATE INDEX "ranking_entries_score_idx" ON "ranking_entries"("score");

-- CreateIndex
CREATE UNIQUE INDEX "ranking_entries_snapshot_id_participant_key_key" ON "ranking_entries"("snapshot_id", "participant_key");

-- CreateIndex
CREATE UNIQUE INDEX "ranking_recalculation_jobs_idempotency_key_key" ON "ranking_recalculation_jobs"("idempotency_key");

-- CreateIndex
CREATE INDEX "ranking_recalculation_jobs_type_status_idx" ON "ranking_recalculation_jobs"("type", "status");

-- CreateIndex
CREATE INDEX "ranking_recalculation_jobs_created_at_idx" ON "ranking_recalculation_jobs"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "badges_code_key" ON "badges"("code");

-- CreateIndex
CREATE INDEX "badges_target_type_idx" ON "badges"("target_type");

-- CreateIndex
CREATE INDEX "badges_rarity_idx" ON "badges"("rarity");

-- CreateIndex
CREATE INDEX "badges_is_active_idx" ON "badges"("is_active");

-- CreateIndex
CREATE INDEX "user_badges_user_id_idx" ON "user_badges"("user_id");

-- CreateIndex
CREATE INDEX "user_badges_badge_id_idx" ON "user_badges"("badge_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_badges_user_id_badge_id_key" ON "user_badges"("user_id", "badge_id");

-- CreateIndex
CREATE INDEX "team_badges_team_id_idx" ON "team_badges"("team_id");

-- CreateIndex
CREATE INDEX "team_badges_badge_id_idx" ON "team_badges"("badge_id");

-- CreateIndex
CREATE UNIQUE INDEX "team_badges_team_id_badge_id_key" ON "team_badges"("team_id", "badge_id");

-- CreateIndex
CREATE INDEX "global_stat_snapshots_stat_key_idx" ON "global_stat_snapshots"("stat_key");

-- CreateIndex
CREATE INDEX "global_stat_snapshots_ranking_type_idx" ON "global_stat_snapshots"("ranking_type");

-- CreateIndex
CREATE INDEX "global_stat_snapshots_team_id_idx" ON "global_stat_snapshots"("team_id");

-- CreateIndex
CREATE INDEX "global_stat_snapshots_calculated_at_idx" ON "global_stat_snapshots"("calculated_at");

-- CreateIndex
CREATE INDEX "audit_logs_actor_user_id_idx" ON "audit_logs"("actor_user_id");

-- CreateIndex
CREATE INDEX "audit_logs_action_idx" ON "audit_logs"("action");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_idx" ON "audit_logs"("entity_type", "entity_id");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- AddForeignKey
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "teams" ADD CONSTRAINT "teams_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_members" ADD CONSTRAINT "team_members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_members" ADD CONSTRAINT "team_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_members" ADD CONSTRAINT "team_members_approved_by_user_id_fkey" FOREIGN KEY ("approved_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_invites" ADD CONSTRAINT "team_invites_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_invites" ADD CONSTRAINT "team_invites_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tournament_groups" ADD CONSTRAINT "tournament_groups_official_data_version_id_fkey" FOREIGN KEY ("official_data_version_id") REFERENCES "official_data_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "national_teams" ADD CONSTRAINT "national_teams_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "tournament_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "national_teams" ADD CONSTRAINT "national_teams_official_data_version_id_fkey" FOREIGN KEY ("official_data_version_id") REFERENCES "official_data_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "official_matches" ADD CONSTRAINT "official_matches_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "tournament_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "official_matches" ADD CONSTRAINT "official_matches_bracket_slot_id_fkey" FOREIGN KEY ("bracket_slot_id") REFERENCES "official_bracket_slots"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "official_matches" ADD CONSTRAINT "official_matches_home_team_id_fkey" FOREIGN KEY ("home_team_id") REFERENCES "national_teams"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "official_matches" ADD CONSTRAINT "official_matches_away_team_id_fkey" FOREIGN KEY ("away_team_id") REFERENCES "national_teams"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "official_matches" ADD CONSTRAINT "official_matches_official_data_version_id_fkey" FOREIGN KEY ("official_data_version_id") REFERENCES "official_data_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "official_bracket_slots" ADD CONSTRAINT "official_bracket_slots_official_data_version_id_fkey" FOREIGN KEY ("official_data_version_id") REFERENCES "official_data_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "official_third_place_matrix_rules" ADD CONSTRAINT "official_third_place_matrix_rules_official_data_version_id_fkey" FOREIGN KEY ("official_data_version_id") REFERENCES "official_data_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_group_predictions" ADD CONSTRAINT "individual_group_predictions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_group_predictions" ADD CONSTRAINT "individual_group_predictions_first_place_team_id_fkey" FOREIGN KEY ("first_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_group_predictions" ADD CONSTRAINT "individual_group_predictions_second_place_team_id_fkey" FOREIGN KEY ("second_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_group_predictions" ADD CONSTRAINT "individual_group_predictions_third_place_team_id_fkey" FOREIGN KEY ("third_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_group_predictions" ADD CONSTRAINT "individual_group_predictions_fourth_place_team_id_fkey" FOREIGN KEY ("fourth_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_knockout_predictions" ADD CONSTRAINT "individual_knockout_predictions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_knockout_predictions" ADD CONSTRAINT "individual_knockout_predictions_bracket_slot_id_fkey" FOREIGN KEY ("bracket_slot_id") REFERENCES "official_bracket_slots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "individual_knockout_predictions" ADD CONSTRAINT "individual_knockout_predictions_winner_team_id_fkey" FOREIGN KEY ("winner_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voting_sessions" ADD CONSTRAINT "voting_sessions_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voting_sessions" ADD CONSTRAINT "voting_sessions_opened_by_user_id_fkey" FOREIGN KEY ("opened_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voting_sessions" ADD CONSTRAINT "voting_sessions_closed_by_user_id_fkey" FOREIGN KEY ("closed_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_votes" ADD CONSTRAINT "team_group_votes_voting_session_id_fkey" FOREIGN KEY ("voting_session_id") REFERENCES "voting_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_votes" ADD CONSTRAINT "team_group_votes_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_votes" ADD CONSTRAINT "team_group_votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_votes" ADD CONSTRAINT "team_group_votes_first_place_team_id_fkey" FOREIGN KEY ("first_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_votes" ADD CONSTRAINT "team_group_votes_second_place_team_id_fkey" FOREIGN KEY ("second_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_votes" ADD CONSTRAINT "team_group_votes_third_place_team_id_fkey" FOREIGN KEY ("third_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_votes" ADD CONSTRAINT "team_group_votes_fourth_place_team_id_fkey" FOREIGN KEY ("fourth_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_votes" ADD CONSTRAINT "team_knockout_votes_voting_session_id_fkey" FOREIGN KEY ("voting_session_id") REFERENCES "voting_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_votes" ADD CONSTRAINT "team_knockout_votes_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_votes" ADD CONSTRAINT "team_knockout_votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_votes" ADD CONSTRAINT "team_knockout_votes_bracket_slot_id_fkey" FOREIGN KEY ("bracket_slot_id") REFERENCES "official_bracket_slots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_votes" ADD CONSTRAINT "team_knockout_votes_winner_team_id_fkey" FOREIGN KEY ("winner_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_consensuses" ADD CONSTRAINT "team_group_consensuses_voting_session_id_fkey" FOREIGN KEY ("voting_session_id") REFERENCES "voting_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_consensuses" ADD CONSTRAINT "team_group_consensuses_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_consensuses" ADD CONSTRAINT "team_group_consensuses_decided_by_user_id_fkey" FOREIGN KEY ("decided_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_consensuses" ADD CONSTRAINT "team_group_consensuses_first_place_team_id_fkey" FOREIGN KEY ("first_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_consensuses" ADD CONSTRAINT "team_group_consensuses_second_place_team_id_fkey" FOREIGN KEY ("second_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_consensuses" ADD CONSTRAINT "team_group_consensuses_third_place_team_id_fkey" FOREIGN KEY ("third_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_group_consensuses" ADD CONSTRAINT "team_group_consensuses_fourth_place_team_id_fkey" FOREIGN KEY ("fourth_place_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_consensuses" ADD CONSTRAINT "team_knockout_consensuses_voting_session_id_fkey" FOREIGN KEY ("voting_session_id") REFERENCES "voting_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_consensuses" ADD CONSTRAINT "team_knockout_consensuses_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_consensuses" ADD CONSTRAINT "team_knockout_consensuses_bracket_slot_id_fkey" FOREIGN KEY ("bracket_slot_id") REFERENCES "official_bracket_slots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_consensuses" ADD CONSTRAINT "team_knockout_consensuses_winner_team_id_fkey" FOREIGN KEY ("winner_team_id") REFERENCES "national_teams"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_knockout_consensuses" ADD CONSTRAINT "team_knockout_consensuses_decided_by_user_id_fkey" FOREIGN KEY ("decided_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "real_tournament_results" ADD CONSTRAINT "real_tournament_results_official_match_id_fkey" FOREIGN KEY ("official_match_id") REFERENCES "official_matches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "real_tournament_results" ADD CONSTRAINT "real_tournament_results_bracket_slot_id_fkey" FOREIGN KEY ("bracket_slot_id") REFERENCES "official_bracket_slots"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "real_tournament_results" ADD CONSTRAINT "real_tournament_results_official_data_version_id_fkey" FOREIGN KEY ("official_data_version_id") REFERENCES "official_data_versions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "real_tournament_results" ADD CONSTRAINT "real_tournament_results_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "real_tournament_results" ADD CONSTRAINT "real_tournament_results_updated_by_user_id_fkey" FOREIGN KEY ("updated_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ranking_snapshots" ADD CONSTRAINT "ranking_snapshots_source_job_id_fkey" FOREIGN KEY ("source_job_id") REFERENCES "ranking_recalculation_jobs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ranking_entries" ADD CONSTRAINT "ranking_entries_snapshot_id_fkey" FOREIGN KEY ("snapshot_id") REFERENCES "ranking_snapshots"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ranking_entries" ADD CONSTRAINT "ranking_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ranking_entries" ADD CONSTRAINT "ranking_entries_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ranking_recalculation_jobs" ADD CONSTRAINT "ranking_recalculation_jobs_requested_by_user_id_fkey" FOREIGN KEY ("requested_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_badges" ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_badges" ADD CONSTRAINT "user_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "badges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_badges" ADD CONSTRAINT "team_badges_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "team_badges" ADD CONSTRAINT "team_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "badges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "global_stat_snapshots" ADD CONSTRAINT "global_stat_snapshots_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "teams"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
