import type { DefaultSession } from "next-auth";
import type { AuthProvider, GlobalRole } from "@/lib/contracts/enums";

declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      globalRole: GlobalRole;
      primaryAuthProvider: AuthProvider;
      profileCompleted: boolean;
      onboardingCompleted: boolean;
    } & DefaultSession["user"];
  }

  interface User {
    globalRole?: GlobalRole;
    primaryAuthProvider?: AuthProvider;
    profileCompleted?: boolean;
    onboardingCompleted?: boolean;
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    userId?: string;
    globalRole?: GlobalRole;
    primaryAuthProvider?: AuthProvider;
    profileCompleted?: boolean;
    onboardingCompleted?: boolean;
  }
}
