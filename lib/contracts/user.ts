import type { AuthProvider, GlobalRole } from "./enums.ts";

export type UserId = string;

export type PublicUserDTO = {
  id: UserId;
  name: string | null;
  nickname: string | null;
  image: string | null;
};

export type CurrentUserDTO = {
  id: UserId;
  name: string | null;
  email: string | null;
  firstName: string | null;
  lastName: string | null;
  nickname: string | null;
  birthDate: string | null;
  image: string | null;
  globalRole: GlobalRole;
  primaryAuthProvider: AuthProvider;
  profileCompleted: boolean;
  onboardingCompleted: boolean;
};

export type CompleteProfileInputDTO = {
  firstName: string;
  lastName: string;
  nickname: string;
  birthDate: string;
};

export type UpdateProfileImageInputDTO = {
  image: string;
};
