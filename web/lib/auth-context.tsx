"use client"
import { createContext, useContext, useState, useEffect, ReactNode } from "react"
import Cookies from "js-cookie"
import { login as apiLogin } from "./api"

interface TokenPayload {
  sub: string
  is_admin: boolean
  role: string | null
  role_id: number | null
  permissions: string[]
  exp: number
}

function decodeJWT(token: string): TokenPayload | null {
  try {
    const payload = token.split(".")[1]
    return JSON.parse(atob(payload))
  } catch {
    return null
  }
}

interface AuthCtx {
  token: string | null
  userId: number | null
  isAdmin: boolean
  role: string | null
  permissions: string[]
  hasPermission: (codename: string) => boolean
  signIn: (username: string, password: string) => Promise<boolean>
  signOut: () => void
}

const AuthContext = createContext<AuthCtx | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(null)
  const [userId, setUserId] = useState<number | null>(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [role, setRole] = useState<string | null>(null)
  const [permissions, setPermissions] = useState<string[]>([])

  function applyToken(t: string | null) {
    setToken(t)
    if (t) {
      const payload = decodeJWT(t)
      setUserId(payload ? Number(payload.sub) : null)
      setIsAdmin(payload?.is_admin ?? false)
      setRole(payload?.role ?? null)
      setPermissions(payload?.permissions ?? [])
    } else {
      setUserId(null)
      setIsAdmin(false)
      setRole(null)
      setPermissions([])
    }
  }

  function hasPermission(codename: string): boolean {
    if (isAdmin) return true
    return permissions.includes(codename)
  }

  useEffect(() => {
    applyToken(Cookies.get("token") ?? null)
  }, [])

  async function signIn(username: string, password: string): Promise<boolean> {
    const { access_token } = await apiLogin(username, password)
    Cookies.set("token", access_token, { expires: 1 })
    applyToken(access_token)
    const payload = decodeJWT(access_token)
    return payload?.is_admin ?? false
  }

  function signOut() {
    Cookies.remove("token")
    applyToken(null)
  }

  return (
    <AuthContext.Provider value={{ token, userId, isAdmin, role, permissions, hasPermission, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be used within AuthProvider")
  return ctx
}
