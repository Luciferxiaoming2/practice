import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

function parseJwtPayload(token: string): { sub: string; is_admin: boolean } | null {
  try {
    const payload = token.split(".")[1]
    if (!payload) return null
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/")
    const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4)
    return JSON.parse(atob(padded))
  } catch {
    return null
  }
}

export function middleware(request: NextRequest) {
  const token = request.cookies.get("token")?.value
  const { pathname } = request.nextUrl

  const isAuthPage = pathname.startsWith("/login") || pathname.startsWith("/register")
  const isDashboard = pathname.startsWith("/dashboard") || pathname.startsWith("/home")
  const isUserArea = pathname.startsWith("/user")
  const isProtected = isDashboard || isUserArea

  // 未登录访问受保护页面 → 跳登录
  if (isProtected && !token) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  if (isProtected && token) {
    const payload = parseJwtPayload(token)
    if (!payload) {
      // token 无法解析 → 清除并跳登录
      const res = NextResponse.redirect(new URL("/login", request.url))
      res.cookies.delete("token")
      return res
    }
    // 角色路由保护：普通用户不可访问管理后台，管理员不可访问用户端
    if (isDashboard && !payload.is_admin) {
      return NextResponse.redirect(new URL("/user", request.url))
    }
    if (isUserArea && payload.is_admin) {
      return NextResponse.redirect(new URL("/dashboard", request.url))
    }
  }

  // 已登录访问登录/注册页 → 按角色跳转
  if (isAuthPage && token) {
    const payload = parseJwtPayload(token)
    if (!payload) {
      const res = NextResponse.redirect(new URL("/login", request.url))
      res.cookies.delete("token")
      return res
    }
    return NextResponse.redirect(new URL(payload.is_admin ? "/dashboard" : "/user", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/dashboard/:path*", "/home/:path*", "/user/:path*", "/login", "/register"],
}
