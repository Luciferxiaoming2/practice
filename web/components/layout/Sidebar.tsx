"use client"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { LayoutDashboard, Users, Shield, ClipboardList, Building2, LogOut, X } from "lucide-react"
import { cn } from "@/lib/utils"
import { useAuth } from "@/lib/auth-context"

const nav = [
  { href: "/dashboard", label: "控制台", icon: LayoutDashboard },
  { href: "/dashboard/accounts", label: "用户管理", icon: Users },
  { href: "/dashboard/departments", label: "部门管理", icon: Building2 },
  { href: "/dashboard/roles", label: "角色管理", icon: Shield },
  { href: "/dashboard/checkins", label: "打卡记录", icon: ClipboardList },
]

export function Sidebar({ open, onClose }: { open?: boolean; onClose?: () => void }) {
  const pathname = usePathname()
  const router = useRouter()
  const { signOut } = useAuth()

  function handleSignOut() {
    signOut()
    router.push("/login")
  }

  return (
    <>
      {/* Mobile backdrop */}
      {open && (
        <div
          className="fixed inset-0 bg-black/50 z-40 md:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={cn(
          "w-60 min-h-screen flex flex-col py-6 px-3 border-r border-border",
          "fixed md:static z-50 transition-transform duration-300 md:transition-none md:translate-x-0",
          open ? "translate-x-0" : "-translate-x-full"
        )}
        style={{
          background: "linear-gradient(180deg, hsl(var(--card)) 0%, hsl(var(--background)) 100%)",
          boxShadow: "inset -1px 0 0 hsl(var(--border))",
        }}
      >
        <div className="px-3 mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-lg font-bold tracking-tight" style={{ color: "hsl(var(--primary))" }}>
              熵析云枢
            </h1>
            <p className="text-xs text-muted-foreground mt-0.5">打卡管理系统</p>
          </div>
          {/* Mobile close button */}
          <button
            className="md:hidden p-1.5 rounded-lg hover:bg-muted"
            onClick={onClose}
          >
            <X size={18} />
          </button>
        </div>
        <nav className="flex flex-col gap-1">
          {nav.map(({ href, label, icon: Icon }) => {
            const active = pathname === href
            return (
              <Link
                key={href}
                href={href}
                onClick={onClose}
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
    </>
  )
}
