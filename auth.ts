import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import Credentials from "next-auth/providers/credentials";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { prisma } from "@/lib/db/prisma";
import { APP_ROUTES } from "@/lib/contracts/routes";
import { loginWithCredentialsSchema } from "@/lib/validations/auth";
import { validateCredentials } from "@/services/auth/authService";

const providers = [
  Credentials({
    id: "credentials",
    name: "Email e senha",
    credentials: {
      email: {
        label: "Email",
        type: "email"
      },
      password: {
        label: "Senha",
        type: "password"
      }
    },
    async authorize(credentials) {
      const parsedCredentials = loginWithCredentialsSchema.safeParse(credentials);

      if (!parsedCredentials.success) {
        return null;
      }

      const user = await validateCredentials(parsedCredentials.data);

      if (!user) {
        return null;
      }

      return {
        id: user.id,
        email: user.email,
        name: user.name,
        image: user.image,
        globalRole: user.globalRole,
        primaryAuthProvider: user.primaryAuthProvider,
        profileCompleted: user.profileCompleted,
        onboardingCompleted: user.onboardingCompleted
      };
    }
  }),
  ...(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET
    ? [
        Google({
          clientId: process.env.GOOGLE_CLIENT_ID,
          clientSecret: process.env.GOOGLE_CLIENT_SECRET
        })
      ]
    : [])
];

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  secret: process.env.AUTH_SECRET ?? process.env.NEXTAUTH_SECRET,
  trustHost: true,
  session: {
    /*
      Credentials Provider funciona de forma mais previsível com JWT.
      A tabela sessions permanece modelada para compatibilidade com Auth.js
      e para evolução futura de validação direta pelo servidor Socket.io.
    */
    strategy: "jwt"
  },
  pages: {
    signIn: APP_ROUTES.LOGIN
  },
  providers,
  callbacks: {
    async signIn({ user, account }) {
      if (account?.provider === "google" && user.id) {
        await prisma.user.update({
          where: {
            id: user.id
          },
          data: {
            primaryAuthProvider: "GOOGLE",
            name: user.name ?? undefined,
            image: user.image ?? undefined
          }
        });
      }

      return true;
    },

    async jwt({ token, user }) {
      const userId = user?.id ?? token.userId;

      if (!userId) {
        return token;
      }

      const dbUser = await prisma.user.findUnique({
        where: {
          id: String(userId)
        },
        select: {
          id: true,
          globalRole: true,
          primaryAuthProvider: true,
          profileCompletedAt: true,
          onboardingCompletedAt: true
        }
      });

      if (!dbUser) {
        return token;
      }

      token.userId = dbUser.id;
      token.globalRole = dbUser.globalRole;
      token.primaryAuthProvider = dbUser.primaryAuthProvider;
      token.profileCompleted = Boolean(dbUser.profileCompletedAt);
      token.onboardingCompleted = Boolean(dbUser.onboardingCompletedAt);

      return token;
    },

    async session({ session, token }) {
      if (session.user) {
        session.user.id = String(token.userId);
        session.user.globalRole = token.globalRole ?? "USER";
        session.user.primaryAuthProvider = token.primaryAuthProvider ?? "CREDENTIALS";
        session.user.profileCompleted = Boolean(token.profileCompleted);
        session.user.onboardingCompleted = Boolean(token.onboardingCompleted);
      }

      return session;
    }
  }
});
