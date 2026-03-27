"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Shield, User as UserIcon, Loader2, ArrowRightLeft } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import { getUsers, updateUser, type User } from "@/lib/api"
import { useAuth } from "@/lib/auth-context"

const ROLES = [
  {
    key: "admin",
    label: "管理员",
    icon: Shield,
    color: "hsl(var(--primary))",
    description: "拥有系统全部权限",
    permissions: [
      "查看控制台统计数据",
      "创建、编辑、删除用户",
      "管理用户角色分配",
      "配置打卡规则",
      "查看所有用户打卡记录",
      "重置用户密码与人脸",
      "系统设置管理",
    ],
  },
  {
    key: "user",
    label: "普通用户",
    icon: UserIcon,
    color: "hsl(142 60% 45%)",
    description: "基础打卡功能权限",
    permissions: [
      "查看个人首页与统计",
      "查看自己的打卡记录",
      "查看个人信息与规则",
      "修改自己的密码",
      "移动端打卡操作",
    ],
  },
]

export default function RolesPage() {
  const { userId } = useAuth()
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [expandedRole, setExpandedRole] = useState<string | null>(null)
  const [toggling, setToggling] = useState<number | null>(null)

  async function load() {
    try { setUsers(await getUsers()) } finally { setLoading(false) }
  }
  useEffect(() => { load() }, [])

  const admins = users.filter((u) => u.is_admin)
  const normals = users.filter((u) => !u.is_admin)

  async function handleToggleRole(u: User) {
    setToggling(u.id)
    try {
      await updateUser(u.id, { is_admin: !u.is_admin })
      await load()
    } finally { setToggling(null) }
  }

  function membersOf(roleKey: string) {
    return roleKey === "admin" ? admins : normals
  }

  if (loading) {
    return (
      <div className="flex justify-center py-20 text-muted-foreground"><Loader2 className="animate-spin" /></div>
    )
  }

  return (
    <div>
      <motion.div variants={fadeInUp} initial="hidden" animate="visible" className="mb-6">
        <h1 className="text-2xl font-bold">角色管理</h1>
        <p className="text-muted-foreground text-sm mt-0.5">管理系统角色与权限分配</p>
      </motion.div>

      {/* 角色卡片 */}
      <motion.div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8" variants={staggerContainer} initial="hidden" animate="visible">
        {ROLES.map((role) => {
          const members = membersOf(role.key)
          const expanded = expandedRole === role.key
          const Icon = role.icon
          return (
            <motion.div key={role.key} variants={staggerItem}>
              <Card className="overflow-hidden">
                <CardContent className="p-6">
                  <div className="flex items-center gap-4 mb-4">
                    <div
                      className="w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0"
                      style={{
                        background: `linear-gradient(135deg, ${role.color} 0%, color-mix(in srgb, ${role.color} 75%, black) 100%)`,
                        boxShadow: `0 4px 12px color-mix(in srgb, ${role.color} 35%, transparent)`,
                      }}
                    >
                      <Icon size={20} color="white" />
                    </div>
                    <div className="flex-1">
                      <h2 className="text-base font-semibold">{role.label}</h2>
                      <p className="text-xs text-muted-foreground">{role.description}</p>
                    </div>
                    <Badge variant="outline">{members.length} 人</Badge>
                  </div>

                  {/* 权限列表 */}
                  <div className="space-y-1.5 mb-4">
                    <p className="text-xs font-medium text-muted-foreground mb-2">权限列表</p>
                    {role.permissions.map((p) => (
                      <div key={p} className="flex items-center gap-2 text-sm">
                        <div className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ background: role.color }} />
                        {p}
                      </div>
                    ))}
                  </div>

                  {/* 展开成员列表 */}
                  <Button
                    variant="outline"
                    size="sm"
                    className="w-full"
                    onClick={() => setExpandedRole(expanded ? null : role.key)}
                  >
                    {expanded ? "收起成员列表" : `查看成员 (${members.length})`}
                  </Button>

                  {expanded && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      transition={{ type: "spring", stiffness: 300, damping: 30 }}
                      className="mt-4 border-t border-border pt-4"
                    >
                      {members.length === 0 ? (
                        <p className="text-sm text-muted-foreground text-center py-4">暂无成员</p>
                      ) : (
                        <div className="space-y-2 max-h-64 overflow-y-auto">
                          {members.map((u) => (
                            <div key={u.id} className="flex items-center justify-between py-2 px-3 rounded-xl hover:bg-muted/40 transition-colors">
                              <div>
                                <p className="text-sm font-medium">{u.full_name}</p>
                                <p className="text-xs text-muted-foreground font-mono">{u.username}</p>
                              </div>
                              {u.id === userId ? (
                                <span className="text-xs text-muted-foreground">当前账户</span>
                              ) : (
                                <Button
                                  size="sm"
                                  variant="outline"
                                  leftIcon={toggling === u.id ? <Loader2 size={12} className="animate-spin" /> : <ArrowRightLeft size={12} />}
                                  disabled={toggling === u.id}
                                  onClick={() => handleToggleRole(u)}
                                >
                                  {u.is_admin ? "设为普通用户" : "设为管理员"}
                                </Button>
                              )}
                            </div>
                          ))}
                        </div>
                      )}
                    </motion.div>
                  )}
                </CardContent>
              </Card>
            </motion.div>
          )
        })}
      </motion.div>

      {/* 全部用户角色速览表 */}
      <motion.div variants={fadeInUp} initial="hidden" animate="visible">
        <h2 className="text-lg font-semibold mb-4">角色分配总览</h2>
        <Card>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-muted-foreground text-xs">
                <th className="px-5 py-3 text-left font-medium">账号</th>
                <th className="px-5 py-3 text-left font-medium">姓名</th>
                <th className="px-5 py-3 text-left font-medium">当前角色</th>
                <th className="px-5 py-3 text-left font-medium">操作</th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id} className="border-b border-border last:border-0 hover:bg-muted/40 transition-colors">
                  <td className="px-5 py-3 font-mono text-xs">{u.username}</td>
                  <td className="px-5 py-3">{u.full_name}</td>
                  <td className="px-5 py-3">
                    <Badge variant={u.is_admin ? "default" : "outline"}>
                      {u.is_admin ? "管理员" : "普通用户"}
                    </Badge>
                  </td>
                  <td className="px-5 py-3">
                    <Button
                      size="sm"
                      variant="outline"
                      leftIcon={toggling === u.id ? <Loader2 size={12} className="animate-spin" /> : <ArrowRightLeft size={12} />}
                      disabled={toggling === u.id}
                      onClick={() => handleToggleRole(u)}
                    >
                      {u.is_admin ? "设为普通用户" : "设为管理员"}
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      </motion.div>
    </div>
  )
}
