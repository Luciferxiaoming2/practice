"use client"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { LayoutDashboard, Users, ClipboardList, Settings, LogOut } from "lucide-react"
import { cn } from "@/lib/utils"
import { useAuth } from "@/lib/auth-context"

const nav = [
  { href: "/dashboard", label: "控制台", icon: LayoutDashboard },
  { href: "/dashboard/accounts", label: "账户管理", icon: Users },
  { href: "/dashboard/checkins", label: "打卡记录", icon: ClipboardList },
  { href: "/dashboard/settings", label: "系统设置", icon: Settings },
]

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const { signOut } = useAuth()

  function handleSignOut() {
    signOut()
    router.push("/login")
  }
  return (
    <aside
      className="w-60 min-h-screen flex flex-col py-6 px-3 border-r border-border"
      style={{
        background: "linear-gradient(180deg, hsl(var(--card)) 0%, hsl(var(--background)) 100%)",
        boxShadow: "inset -1px 0 0 hsl(var(--border))",
      }}
    >
      <div className="px-3 mb-8">
        <h1 className="text-lg font-bold tracking-tight" style={{ color: "hsl(var(--primary))" }}>
          熵析云枢
        </h1>
        <p className="text-xs text-muted-foreground mt-0.5">打卡管理系统</p>
      </div>
      <nav className="flex flex-col gap-1">
        {nav.map(({ href, label, icon: Icon }) => {
          const active = pathname === href
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                active
                  ? "text-primary-foreground scale-[1.01]"
                  : "text-muted-foreground hover:text-foreground hover:bg-muted"
              )}
              style={
                active
                  ? {
                      background:
                        "linear-gradient(135deg, hsl(var(--primary)) 0%, color-mix(in srgb, hsl(var(--primary)) 80%, black) 100%)",
                      boxShadow:
                        "0 4px 12px color-mix(in srgb, hsl(var(--primary)) 35%, transparent), inset 0 1px 0 rgba(255,255,255,0.2)",
                    }
                  : {}
              }
            >
              <Icon size={16} />
              {label}
            </Link>
          )
        })}
      </nav>
      <div className="mt-auto pt-4 border-t border-border">
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-muted w-full transition-all duration-200"
        >
          <LogOut size={16} />
          退出登录
        </button>
      </div>
    </aside>
  )
}
