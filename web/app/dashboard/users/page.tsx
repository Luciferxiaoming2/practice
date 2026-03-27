"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Search, Loader2, Pencil, Trash2, RotateCcw, ScanFace } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import { getUsers, updateUser, resetPassword, resetFace, deleteUser, type User } from "@/lib/api"

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [keyword, setKeyword] = useState("")
  const [editUser, setEditUser] = useState<User | null>(null)
  const [showReset, setShowReset] = useState<{ id: number; name: string } | null>(null)
  const [showDelete, setShowDelete] = useState<{ id: number; name: string } | null>(null)
  const [newPwd, setNewPwd] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function load() {
    try { setUsers(await getUsers()) } finally { setLoading(false) }
  }
  useEffect(() => { load() }, [])

  const filtered = users.filter((u) => {
    if (!keyword) return true
    const k = keyword.toLowerCase()
    return u.username.toLowerCase().includes(k) || u.full_name.toLowerCase().includes(k)
  })

  async function handleResetFace(id: number) {
    await resetFace(id)
    load()
  }

  async function handleResetPwd(e: React.FormEvent) {
    e.preventDefault()
    if (!showReset) return
    setSubmitting(true)
    setErrMsg("")
    try {
      await resetPassword(showReset.id, newPwd)
      setShowReset(null)
      setNewPwd("")
    } catch {
      setErrMsg("重置密码失败，请重试")
    } finally { setSubmitting(false) }
  }

  async function handleDelete() {
    if (!showDelete) return
    setSubmitting(true)
    setErrMsg("")
    try {
      await deleteUser(showDelete.id)
      setShowDelete(null)
      load()
    } catch {
      setErrMsg("删除失败，请重试")
    } finally { setSubmitting(false) }
  }

  return (
    <div>
      <motion.div className="flex items-center justify-between mb-6" variants={fadeInUp} initial="hidden" animate="visible">
        <div>
          <h1 className="text-2xl font-bold">用户管理</h1>
          <p className="text-muted-foreground text-sm mt-0.5">查看、编辑和管理所有用户</p>
        </div>
      </motion.div>

      <motion.div className="flex flex-wrap gap-3 mb-4" variants={fadeInUp} initial="hidden" animate="visible">
        <div className="relative">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input className="pl-9 w-64" placeholder="搜索账号或姓名..." value={keyword} onChange={(e) => setKeyword(e.target.value)} />
        </div>
        <div className="flex items-center gap-2 ml-auto text-sm text-muted-foreground">
          共 {filtered.length} 个用户
        </div>
      </motion.div>

      {loading ? (
        <div className="flex justify-center py-20 text-muted-foreground"><Loader2 className="animate-spin" /></div>
      ) : (
        <motion.div variants={staggerContainer} initial="hidden" animate="visible">
          {filtered.length === 0 ? (
            <motion.div variants={staggerItem}>
              <Card className="flex flex-col items-center justify-center py-20 text-muted-foreground">
                <p className="text-sm">暂无匹配用户</p>
              </Card>
            </motion.div>
          ) : (
            <Card>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-muted-foreground text-xs">
                    <th className="px-5 py-3 text-left font-medium">账号</th>
                    <th className="px-5 py-3 text-left font-medium">姓名</th>
                    <th className="px-5 py-3 text-left font-medium">角色</th>
                    <th className="px-5 py-3 text-left font-medium">状态</th>
                    <th className="px-5 py-3 text-left font-medium">人脸</th>
                    <th className="px-5 py-3 text-left font-medium">操作</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((u) => (
                    <motion.tr key={u.id} variants={staggerItem} className="border-b border-border last:border-0 hover:bg-muted/40 transition-colors">
                      <td className="px-5 py-3 font-mono text-xs">{u.username}</td>
                      <td className="px-5 py-3">{u.full_name}</td>
                      <td className="px-5 py-3">
                        <Badge variant={u.is_admin ? "default" : "outline"}>
                          {u.is_admin ? "管理员" : "普通用户"}
                        </Badge>
                      </td>
                      <td className="px-5 py-3">
                        <Badge variant={u.is_active ? "success" : "warning"}>
                          {u.is_active ? "已激活" : "待激活"}
                        </Badge>
                      </td>
                      <td className="px-5 py-3">
                        <Badge variant={u.face_enrolled ? "success" : "outline"}>
                          {u.face_enrolled ? "已录入" : "未录入"}
                        </Badge>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex gap-2">
                          <Button size="sm" variant="outline" leftIcon={<Pencil size={12} />}
                            onClick={() => setEditUser(u)}>
                            编辑
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<RotateCcw size={12} />}
                            onClick={() => { setShowReset({ id: u.id, name: u.full_name }); setNewPwd("") }}>
                            重置密码
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<ScanFace size={12} />}
                            onClick={() => handleResetFace(u.id)}>
                            重置人脸
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<Trash2 size={12} />}
                            onClick={() => setShowDelete({ id: u.id, name: u.full_name })}
                            className="text-destructive hover:text-destructive">
                            删除
                          </Button>
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            </Card>
          )}
        </motion.div>
      )}

      {/* 编辑用户弹窗 */}
      {editUser && <EditModal user={editUser} onClose={() => setEditUser(null)} onSaved={load} />}

      {/* 重置密码弹窗 */}
      {showReset && (
        <Modal title={`重置密码 — ${showReset.name}`} onClose={() => { setShowReset(null); setErrMsg("") }}>
          <form className="space-y-3" onSubmit={handleResetPwd}>
            <Field label="新密码">
              <Input type="password" placeholder="输入新密码" value={newPwd} onChange={(e) => setNewPwd(e.target.value)} required />
            </Field>
            {errMsg && <p className="text-destructive text-xs">{errMsg}</p>}
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="outline" onClick={() => { setShowReset(null); setErrMsg("") }}>取消</Button>
              <Button type="submit" isLoading={submitting}>确认重置</Button>
            </div>
          </form>
        </Modal>
      )}

      {/* 删除确认弹窗 */}
      {showDelete && (
        <Modal title="确认删除" onClose={() => { setShowDelete(null); setErrMsg("") }}>
          <p className="text-sm text-muted-foreground mb-4">
            确定要删除用户 <span className="font-semibold text-foreground">{showDelete.name}</span> 吗？此操作不可撤销，该用户的所有打卡记录也将被删除。
          </p>
          {errMsg && <p className="text-destructive text-xs mb-3">{errMsg}</p>}
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => { setShowDelete(null); setErrMsg("") }}>取消</Button>
            <Button variant="destructive" isLoading={submitting} onClick={handleDelete}>确认删除</Button>
          </div>
        </Modal>
      )}
    </div>
  )
}

/* ── 编辑用户弹窗 ────────────────────────────────────── */
function EditModal({ user, onClose, onSaved }: { user: User; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    full_name: user.full_name,
    is_active: user.is_active,
    is_admin: user.is_admin,
  })
  const [saving, setSaving] = useState(false)

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      await updateUser(user.id, form)
      onSaved()
      onClose()
    } finally { setSaving(false) }
  }

  return (
    <Modal title={`编辑用户 — ${user.username}`} onClose={onClose}>
      <form className="space-y-4" onSubmit={handleSave}>
        <Field label="姓名">
          <Input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} required />
        </Field>
        <label className="flex items-center gap-2 text-sm font-medium">
          <input type="checkbox" checked={form.is_active} onChange={(e) => setForm({ ...form, is_active: e.target.checked })} className="rounded" />
          已激活
        </label>
        <label className="flex items-center gap-2 text-sm font-medium">
          <input type="checkbox" checked={form.is_admin} onChange={(e) => setForm({ ...form, is_admin: e.target.checked })} className="rounded" />
          管理员角色
        </label>
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={saving}>保存</Button>
        </div>
      </form>
    </Modal>
  )
}

/* ── 通用组件 ─────────────────────────────────────────── */
function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={onClose}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 35 }}
        className="bg-card rounded-2xl shadow-xl w-full max-w-sm mx-4 p-6"
        onClick={(e) => e.stopPropagation()}
        style={{ boxShadow: "0 20px 60px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.6)" }}
      >
        <h2 className="text-base font-semibold mb-4">{title}</h2>
        {children}
      </motion.div>
    </div>
  )
}

function Field({ label, error, children }: { label: string; error?: string; children: React.ReactNode }) {
  return (
    <div className="space-y-1.5">
      <label className="text-sm font-medium">{label}</label>
      {children}
      {error && <p className="text-destructive text-xs">{error}</p>}
    </div>
  )
}
