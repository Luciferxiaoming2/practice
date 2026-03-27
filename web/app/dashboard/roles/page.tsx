"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import {
  Shield, Plus, Pencil, Trash2, Loader2, Users, ChevronDown, ChevronUp, Check,
} from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import {
  getRoles, getPermissions, createRole, updateRole, deleteRole, getRoleUsers,
  type Role, type Permission,
} from "@/lib/api"

export default function RolesPage() {
  const [roles, setRoles] = useState<Role[]>([])
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [editRole, setEditRole] = useState<Role | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Role | null>(null)
  const [expandedRole, setExpandedRole] = useState<number | null>(null)
  const [roleUsers, setRoleUsers] = useState<{ id: number; username: string; full_name: string }[]>([])
  const [loadingUsers, setLoadingUsers] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function load() {
    try {
      const [r, p] = await Promise.all([getRoles(), getPermissions()])
      setRoles(r)
      setPermissions(p)
    } finally {
      setLoading(false)
    }
  }
  useEffect(() => { load() }, [])

  async function handleExpand(roleId: number) {
    if (expandedRole === roleId) {
      setExpandedRole(null)
      return
    }
    setExpandedRole(roleId)
    setLoadingUsers(true)
    try {
      setRoleUsers(await getRoleUsers(roleId))
    } finally {
      setLoadingUsers(false)
    }
  }

  async function handleDelete() {
    if (!deleteTarget) return
    setSubmitting(true)
    setErrMsg("")
    try {
      await deleteRole(deleteTarget.id)
      setDeleteTarget(null)
      load()
    } catch (e: any) {
      setErrMsg(e.response?.data?.detail ?? "删除失败")
    } finally {
      setSubmitting(false)
    }
  }

  // 按权限 codename 前缀分组
  const permissionGroups = groupPermissions(permissions)

  if (loading) {
    return <div className="flex justify-center py-20 text-muted-foreground"><Loader2 className="animate-spin" /></div>
  }

  return (
    <div>
      <motion.div className="flex items-center justify-between mb-6" variants={fadeInUp} initial="hidden" animate="visible">
        <div>
          <h1 className="text-2xl font-bold">角色管理</h1>
          <p className="text-muted-foreground text-sm mt-0.5">管理系统角色、权限分配</p>
        </div>
        <Button leftIcon={<Plus size={14} />} onClick={() => { setShowCreate(true); setErrMsg("") }}>
          新建角色
        </Button>
      </motion.div>

      {/* 角色卡片网格 */}
      <motion.div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-5" variants={staggerContainer} initial="hidden" animate="visible">
        {roles.map((role) => {
          const expanded = expandedRole === role.id
          return (
            <motion.div key={role.id} variants={staggerItem}>
              <Card className="overflow-hidden">
                <CardContent className="p-5">
                  {/* 头部 */}
                  <div className="flex items-start gap-3 mb-4">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{
                        background: "linear-gradient(135deg, hsl(var(--primary)) 0%, color-mix(in srgb, hsl(var(--primary)) 75%, black) 100%)",
                        boxShadow: "0 4px 12px color-mix(in srgb, hsl(var(--primary)) 30%, transparent)",
                      }}
                    >
                      <Shield size={18} color="white" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <h3 className="text-sm font-semibold truncate">{role.name}</h3>
                        {role.is_system && <Badge variant="outline" className="text-[10px] px-1.5 py-0">内置</Badge>}
                      </div>
                      <p className="text-xs text-muted-foreground mt-0.5">{role.description || "无描述"}</p>
                    </div>
                  </div>

                  {/* 权限标签 */}
                  <div className="flex flex-wrap gap-1.5 mb-4">
                    {role.permissions.length === 0 ? (
                      <span className="text-xs text-muted-foreground">无权限</span>
                    ) : (
                      role.permissions.map((p) => (
                        <Badge key={p.id} variant="outline" className="text-[11px] px-2 py-0.5">
                          {p.name}
                        </Badge>
                      ))
                    )}
                  </div>

                  {/* 操作按钮 */}
                  <div className="flex items-center gap-2">
                    <Button
                      size="sm" variant="outline" className="flex-1"
                      leftIcon={expanded ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
                      onClick={() => handleExpand(role.id)}
                    >
                      成员
                    </Button>
                    <Button size="sm" variant="outline" leftIcon={<Pencil size={12} />}
                      onClick={() => { setEditRole(role); setErrMsg("") }}>
                      编辑
                    </Button>
                    {!role.is_system && (
                      <Button size="sm" variant="outline" leftIcon={<Trash2 size={12} />}
                        className="text-destructive hover:text-destructive"
                        onClick={() => { setDeleteTarget(role); setErrMsg("") }}>
                        删除
                      </Button>
                    )}
                  </div>

                  {/* 展开成员列表 */}
                  {expanded && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      transition={{ type: "spring", stiffness: 300, damping: 30 }}
                      className="mt-4 border-t border-border pt-3"
                    >
                      {loadingUsers ? (
                        <div className="flex justify-center py-4"><Loader2 size={16} className="animate-spin text-muted-foreground" /></div>
                      ) : roleUsers.length === 0 ? (
                        <p className="text-xs text-muted-foreground text-center py-3">暂无成员</p>
                      ) : (
                        <div className="space-y-1.5 max-h-48 overflow-y-auto">
                          {roleUsers.map((u) => (
                            <div key={u.id} className="flex items-center gap-2 py-1.5 px-2 rounded-lg hover:bg-muted/40 transition-colors">
                              <Users size={12} className="text-muted-foreground flex-shrink-0" />
                              <span className="text-sm">{u.full_name}</span>
                              <span className="text-xs text-muted-foreground font-mono">({u.username})</span>
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

      {/* 新建角色弹窗 */}
      {showCreate && (
        <RoleFormModal
          title="新建角色"
          permissions={permissions}
          permissionGroups={permissionGroups}
          onClose={() => setShowCreate(false)}
          onSave={async (name, desc, permIds) => {
            await createRole({ name, description: desc, permission_ids: permIds })
            load()
          }}
        />
      )}

      {/* 编辑角色弹窗 */}
      {editRole && (
        <RoleFormModal
          title={`编辑角色 — ${editRole.name}`}
          permissions={permissions}
          permissionGroups={permissionGroups}
          initial={{ name: editRole.name, description: editRole.description, permissionIds: editRole.permissions.map((p) => p.id) }}
          onClose={() => setEditRole(null)}
          onSave={async (name, desc, permIds) => {
            await updateRole(editRole.id, { name, description: desc, permission_ids: permIds })
            load()
          }}
        />
      )}

      {/* 删除确认弹窗 */}
      {deleteTarget && (
        <Modal title="确认删除" onClose={() => { setDeleteTarget(null); setErrMsg("") }}>
          <p className="text-sm text-muted-foreground mb-4">
            确定要删除角色 <span className="font-semibold text-foreground">{deleteTarget.name}</span> 吗？该角色下的用户将不再关联此角色。
          </p>
          {errMsg && <p className="text-destructive text-xs mb-3">{errMsg}</p>}
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => { setDeleteTarget(null); setErrMsg("") }}>取消</Button>
            <Button variant="destructive" isLoading={submitting} onClick={handleDelete}>确认删除</Button>
          </div>
        </Modal>
      )}
    </div>
  )
}

/* ── 角色表单弹窗 ─────────────────────────────────────── */
function RoleFormModal({
  title,
  permissions,
  permissionGroups,
  initial,
  onClose,
  onSave,
}: {
  title: string
  permissions: Permission[]
  permissionGroups: Record<string, Permission[]>
  initial?: { name: string; description: string; permissionIds: number[] }
  onClose: () => void
  onSave: (name: string, description: string, permissionIds: number[]) => Promise<void>
}) {
  const [name, setName] = useState(initial?.name ?? "")
  const [description, setDescription] = useState(initial?.description ?? "")
  const [selected, setSelected] = useState<Set<number>>(new Set(initial?.permissionIds ?? []))
  const [saving, setSaving] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  function togglePerm(id: number) {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function toggleGroup(groupPerms: Permission[]) {
    const allSelected = groupPerms.every((p) => selected.has(p.id))
    setSelected((prev) => {
      const next = new Set(prev)
      groupPerms.forEach((p) => {
        if (allSelected) next.delete(p.id)
        else next.add(p.id)
      })
      return next
    })
  }

  function selectAll() {
    if (selected.size === permissions.length) {
      setSelected(new Set())
    } else {
      setSelected(new Set(permissions.map((p) => p.id)))
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    setErrMsg("")
    try {
      await onSave(name, description, Array.from(selected))
      onClose()
    } catch (err: any) {
      setErrMsg(err.response?.data?.detail ?? "操作失败")
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={title} onClose={onClose} wide>
      <form className="space-y-4" onSubmit={handleSubmit}>
        <div className="grid grid-cols-2 gap-4">
          <Field label="角色名称">
            <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="如：运营主管" required />
          </Field>
          <Field label="描述">
            <Input value={description} onChange={(e) => setDescription(e.target.value)} placeholder="角色描述（可选）" />
          </Field>
        </div>

        {/* 权限选择 */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <label className="text-sm font-medium">权限分配</label>
            <button type="button" className="text-xs text-primary hover:underline" onClick={selectAll}>
              {selected.size === permissions.length ? "取消全选" : "全选"}
            </button>
          </div>
          <div className="border border-border rounded-xl p-4 space-y-4 max-h-72 overflow-y-auto">
            {Object.entries(permissionGroups).map(([group, perms]) => {
              const allChecked = perms.every((p) => selected.has(p.id))
              const someChecked = perms.some((p) => selected.has(p.id))
              return (
                <div key={group}>
                  <button
                    type="button"
                    className="flex items-center gap-2 text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2 hover:text-foreground transition-colors"
                    onClick={() => toggleGroup(perms)}
                  >
                    <div className={`w-3.5 h-3.5 rounded border flex items-center justify-center transition-colors ${allChecked ? "bg-primary border-primary" : someChecked ? "bg-primary/30 border-primary" : "border-muted-foreground/40"}`}>
                      {allChecked && <Check size={10} className="text-primary-foreground" />}
                    </div>
                    {group}
                  </button>
                  <div className="grid grid-cols-2 gap-1.5 ml-5">
                    {perms.map((p) => (
                      <label key={p.id} className="flex items-center gap-2 py-1 px-2 rounded-lg hover:bg-muted/40 cursor-pointer transition-colors">
                        <div className={`w-3.5 h-3.5 rounded border flex items-center justify-center transition-colors ${selected.has(p.id) ? "bg-primary border-primary" : "border-muted-foreground/40"}`}>
                          {selected.has(p.id) && <Check size={10} className="text-primary-foreground" />}
                        </div>
                        <span className="text-sm">{p.name}</span>
                      </label>
                    ))}
                  </div>
                </div>
              )
            })}
          </div>
          <p className="text-xs text-muted-foreground mt-1.5">
            已选择 {selected.size} / {permissions.length} 项权限
          </p>
        </div>

        {errMsg && <p className="text-destructive text-xs">{errMsg}</p>}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={saving}>保存</Button>
        </div>
      </form>
    </Modal>
  )
}

/* ── 工具函数 ─────────────────────────────────────────── */
function groupPermissions(permissions: Permission[]): Record<string, Permission[]> {
  const groups: Record<string, Permission[]> = {}
  const labelMap: Record<string, string> = {
    user: "用户管理",
    role: "角色管理",
    checkin: "打卡管理",
    system: "系统设置",
  }
  for (const p of permissions) {
    const prefix = p.codename.split(".")[0]
    const label = labelMap[prefix] ?? prefix
    if (!groups[label]) groups[label] = []
    groups[label].push(p)
  }
  return groups
}

/* ── 通用组件 ─────────────────────────────────────────── */
function Modal({ title, onClose, wide, children }: { title: string; onClose: () => void; wide?: boolean; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={onClose}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 35 }}
        className={`bg-card rounded-2xl shadow-xl mx-4 p-6 ${wide ? "w-full max-w-lg" : "w-full max-w-sm"}`}
        onClick={(e) => e.stopPropagation()}
        style={{ boxShadow: "0 20px 60px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.6)" }}
      >
        <h2 className="text-base font-semibold mb-4">{title}</h2>
        {children}
      </motion.div>
    </div>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="space-y-1.5">
      <label className="text-sm font-medium">{label}</label>
      {children}
    </div>
  )
}
