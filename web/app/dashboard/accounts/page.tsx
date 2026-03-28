"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Plus, RotateCcw, ScanFace, Loader2, Settings, Pencil } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import { getUsers, createUser, resetPassword, resetFace, updateUser, getRoles, type User, type Role } from "@/lib/api"
import LocationPicker from "@/components/admin/LocationPicker"

export default function AccountsPage() {
  const [users, setUsers] = useState<User[]>([])
  const [roles, setRoles] = useState<Role[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [editUser, setEditUser] = useState<User | null>(null)
  const [showReset, setShowReset] = useState<{ id: number; name: string } | null>(null)
  const [showRules, setShowRules] = useState<User | null>(null)
  const [newPwd, setNewPwd] = useState("")
  const [submitting, setSubmitting] = useState(false)

  async function load() {
    try {
      const [u, r] = await Promise.all([getUsers(), getRoles()])
      setUsers(u)
      setRoles(r)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  async function handleResetPwd(e: React.FormEvent) {
    e.preventDefault()
    if (!showReset) return
    setSubmitting(true)
    try {
      await resetPassword(showReset.id, newPwd)
      setShowReset(null)
      setNewPwd("")
    } finally {
      setSubmitting(false)
    }
  }

  async function handleResetFace(id: number) {
    await resetFace(id)
    load()
  }

  return (
    <div>
      <motion.div className="flex items-center justify-between mb-6" variants={fadeInUp} initial="hidden" animate="visible">
        <div>
          <h1 className="text-2xl font-bold">账户管理</h1>
          <p className="text-muted-foreground text-sm mt-0.5">新建、编辑账户及打卡规则配置</p>
        </div>
        <Button leftIcon={<Plus size={16} />} onClick={() => setShowCreate(true)}>
          新建账户
        </Button>
      </motion.div>

      {loading ? (
        <div className="flex justify-center py-20 text-muted-foreground">
          <Loader2 className="animate-spin" />
        </div>
      ) : (
        <motion.div variants={staggerContainer} initial="hidden" animate="visible">
          {users.length === 0 ? (
            <motion.div variants={staggerItem}>
              <Card className="flex flex-col items-center justify-center py-20 text-muted-foreground">
                <p className="text-sm">暂无账户，点击右上角新建</p>
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
                    <th className="px-5 py-3 text-left font-medium">打卡规则</th>
                    <th className="px-5 py-3 text-left font-medium">操作</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((u) => (
                    <motion.tr key={u.id} variants={staggerItem} className="border-b border-border last:border-0 hover:bg-muted/40 transition-colors">
                      <td className="px-5 py-3 font-mono text-xs">{u.username}</td>
                      <td className="px-5 py-3">{u.full_name}</td>
                      <td className="px-5 py-3">
                        <Badge variant={u.is_admin ? "default" : "outline"}>
                          {u.role?.name ?? (u.is_admin ? "管理员" : "普通用户")}
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
                        <div className="flex flex-wrap gap-1">
                          {u.require_location && (
                            <Badge variant="default">
                              地点 {u.location_radius ? `${u.location_radius}m` : ""}
                            </Badge>
                          )}
                          {u.require_time && (
                            <Badge variant="default">
                              时间 {u.checkin_time_start && u.checkin_time_end ? `${u.checkin_time_start}-${u.checkin_time_end}` : ""}
                            </Badge>
                          )}
                          {u.require_face && <Badge variant="default">人脸</Badge>}
                          {!u.require_location && !u.require_time && !u.require_face && (
                            <span className="text-xs text-muted-foreground">未配置</span>
                          )}
                        </div>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex gap-2">
                          <Button size="sm" variant="outline" leftIcon={<Pencil size={12} />}
                            onClick={() => setEditUser(u)}>
                            编辑
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<Settings size={12} />}
                            onClick={() => setShowRules(u)}>
                            规则
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<RotateCcw size={12} />}
                            onClick={() => { setShowReset({ id: u.id, name: u.full_name }); setNewPwd("") }}>
                            重置密码
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<ScanFace size={12} />}
                            onClick={() => handleResetFace(u.id)}>
                            重置人脸
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

      {/* 新建账户弹窗 */}
      {showCreate && (
        <CreateModal roles={roles} onClose={() => setShowCreate(false)} onCreated={load} />
      )}

      {/* 编辑账户弹窗（角色+状态） */}
      {editUser && (
        <EditModal user={editUser} roles={roles} onClose={() => setEditUser(null)} onSaved={load} />
      )}

      {/* 重置密码弹窗 */}
      {showReset && (
        <Modal title={`重置密码 — ${showReset.name}`} onClose={() => setShowReset(null)}>
          <form className="space-y-3" onSubmit={handleResetPwd}>
            <Field label="新密码">
              <Input type="password" placeholder="输入新密码" value={newPwd} onChange={(e) => setNewPwd(e.target.value)} required />
            </Field>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="outline" onClick={() => setShowReset(null)}>取消</Button>
              <Button type="submit" isLoading={submitting}>确认重置</Button>
            </div>
          </form>
        </Modal>
      )}

      {/* 打卡规则配置弹窗 */}
      {showRules && (
        <RulesModal user={showRules} onClose={() => setShowRules(null)} onSaved={load} />
      )}
    </div>
  )
}

/* ── 新建账户弹窗 ────────────────────────────────────── */
function CreateModal({ roles, onClose, onCreated }: { roles: Role[]; onClose: () => void; onCreated: () => void }) {
  const [form, setForm] = useState({
    username: "", full_name: "", password: "", confirm: "",
    role_id: (roles[0]?.id ?? null) as number | null,
  })
  const [submitting, setSubmitting] = useState(false)
  const [msg, setMsg] = useState("")
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})

  function validate() {
    const errors: Record<string, string> = {}
    if (form.username.length < 3) errors.username = "账号至少 3 个字符"
    if (!/^[a-zA-Z0-9_]+$/.test(form.username)) errors.username = "账号只能包含字母、数字和下划线"
    if (form.full_name.trim().length < 2) errors.full_name = "姓名至少 2 个字符"
    if (form.password.length < 8) errors.password = "密码至少 8 位"
    else if (!/[A-Za-z]/.test(form.password)) errors.password = "密码需包含至少 1 个字母"
    else if (!/[0-9]/.test(form.password)) errors.password = "密码需包含至少 1 个数字"
    if (form.confirm !== form.password) errors.confirm = "两次密码不一致"
    return errors
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setMsg("")
    const errors = validate()
    if (Object.keys(errors).length > 0) { setFieldErrors(errors); return }
    setFieldErrors({})
    setSubmitting(true)
    try {
      await createUser({
        username: form.username,
        full_name: form.full_name,
        password: form.password,
        role_id: form.role_id ?? undefined,
      })
      onCreated()
      onClose()
    } catch (err: any) {
      setMsg(err.response?.data?.detail ?? "创建失败，账号可能已存在")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Modal title="新建账户" onClose={onClose}>
      <form className="space-y-3" onSubmit={handleSubmit}>
        <Field label="账号" error={fieldErrors.username}>
          <Input placeholder="字母/数字/下划线，至少 3 位" value={form.username}
            onChange={(e) => setForm({ ...form, username: e.target.value })}
            className={fieldErrors.username ? "border-destructive focus-visible:ring-destructive" : ""}
            required />
        </Field>
        <Field label="姓名" error={fieldErrors.full_name}>
          <Input placeholder="真实姓名" value={form.full_name}
            onChange={(e) => setForm({ ...form, full_name: e.target.value })}
            className={fieldErrors.full_name ? "border-destructive focus-visible:ring-destructive" : ""}
            required />
        </Field>
        <Field label="角色">
          <select
            className="w-full h-9 rounded-xl border border-border bg-background px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
            value={form.role_id ?? ""}
            onChange={(e) => setForm({ ...form, role_id: e.target.value ? Number(e.target.value) : null })}
          >
            <option value="">未分配角色</option>
            {roles.map((r) => (
              <option key={r.id} value={r.id}>{r.name}</option>
            ))}
          </select>
        </Field>
        <Field label="初始密码" error={fieldErrors.password}>
          <Input type="password" placeholder="至少 8 位，含字母和数字" value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            className={fieldErrors.password ? "border-destructive focus-visible:ring-destructive" : ""}
            required />
        </Field>
        <Field label="确认密码" error={fieldErrors.confirm}>
          <Input type="password" placeholder="再次输入密码" value={form.confirm}
            onChange={(e) => setForm({ ...form, confirm: e.target.value })}
            className={fieldErrors.confirm ? "border-destructive focus-visible:ring-destructive" : ""}
            required />
        </Field>
        {msg && <p className="text-destructive text-xs">{msg}</p>}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={submitting}>创建</Button>
        </div>
      </form>
    </Modal>
  )
}

/* ── 编辑账户弹窗（角色+状态） ────────────────────────── */
function EditModal({ user, roles, onClose, onSaved }: { user: User; roles: Role[]; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    full_name: user.full_name,
    is_active: user.is_active,
    role_id: user.role_id as number | null,
  })
  const [saving, setSaving] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    setErrMsg("")
    try {
      await updateUser(user.id, {
        full_name: form.full_name,
        is_active: form.is_active,
        role_id: form.role_id,
      })
      onSaved()
      onClose()
    } catch (err: any) {
      setErrMsg(err.response?.data?.detail ?? "保存失败")
    } finally { setSaving(false) }
  }

  return (
    <Modal title={`编辑账户 — ${user.username}`} onClose={onClose}>
      <form className="space-y-4" onSubmit={handleSave}>
        <Field label="姓名">
          <Input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} required />
        </Field>
        <Field label="角色">
          <select
            className="w-full h-9 rounded-xl border border-border bg-background px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
            value={form.role_id ?? ""}
            onChange={(e) => setForm({ ...form, role_id: e.target.value ? Number(e.target.value) : null })}
          >
            <option value="">未分配角色</option>
            {roles.map((r) => (
              <option key={r.id} value={r.id}>{r.name}</option>
            ))}
          </select>
        </Field>
        <label className="flex items-center gap-2 text-sm font-medium">
          <input type="checkbox" checked={form.is_active} onChange={(e) => setForm({ ...form, is_active: e.target.checked })} className="rounded" />
          已激活
        </label>
        {errMsg && <p className="text-destructive text-xs">{errMsg}</p>}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={saving}>保存</Button>
        </div>
      </form>
    </Modal>
  )
}

/* ── 打卡规则弹窗 ────────────────────────────────────── */
function RulesModal({ user, onClose, onSaved }: { user: User; onClose: () => void; onSaved: () => void }) {
  const [rules, setRules] = useState({
    require_location: user.require_location,
    location_lat: user.location_lat ?? "",
    location_lng: user.location_lng ?? "",
    location_radius: user.location_radius ?? "",
    require_time: user.require_time,
    checkin_time_start: user.checkin_time_start ?? "",
    checkin_time_end: user.checkin_time_end ?? "",
    require_face: user.require_face,
  })
  const [saving, setSaving] = useState(false)

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      await updateUser(user.id, {
        require_location: rules.require_location,
        location_lat: rules.location_lat === "" ? null : Number(rules.location_lat),
        location_lng: rules.location_lng === "" ? null : Number(rules.location_lng),
        location_radius: rules.location_radius === "" ? null : Number(rules.location_radius),
        require_time: rules.require_time,
        checkin_time_start: rules.checkin_time_start || null,
        checkin_time_end: rules.checkin_time_end || null,
        require_face: rules.require_face,
      })
      onSaved()
      onClose()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={`打卡规则 — ${user.full_name}`} onClose={onClose} wide>
      <form className="space-y-4" onSubmit={handleSave}>
        <div className="space-y-2">
          <label className="flex items-center gap-2 text-sm font-medium">
            <input type="checkbox" checked={rules.require_location}
              onChange={(e) => setRules({ ...rules, require_location: e.target.checked })}
              className="rounded" />
            要求地点打卡
          </label>
          {rules.require_location && (
            <div className="space-y-2 pl-6">
              <LocationPicker
                lat={rules.location_lat}
                lng={rules.location_lng}
                radius={rules.location_radius}
                onChange={(lat, lng) => setRules({ ...rules, location_lat: String(lat), location_lng: String(lng) })}
              />
              <div className="grid grid-cols-3 gap-2">
                <Field label="纬度">
                  <Input type="number" step="any" placeholder="30.2741" value={rules.location_lat}
                    onChange={(e) => setRules({ ...rules, location_lat: e.target.value })} />
                </Field>
                <Field label="经度">
                  <Input type="number" step="any" placeholder="120.1551" value={rules.location_lng}
                    onChange={(e) => setRules({ ...rules, location_lng: e.target.value })} />
                </Field>
                <Field label="半径(米)">
                  <Input type="number" step="any" placeholder="200" value={rules.location_radius}
                    onChange={(e) => setRules({ ...rules, location_radius: e.target.value })} />
                </Field>
              </div>
            </div>
          )}
        </div>
        <div className="space-y-2">
          <label className="flex items-center gap-2 text-sm font-medium">
            <input type="checkbox" checked={rules.require_time}
              onChange={(e) => setRules({ ...rules, require_time: e.target.checked })}
              className="rounded" />
            要求时间段打卡
          </label>
          {rules.require_time && (
            <div className="grid grid-cols-2 gap-2 pl-6">
              <Field label="开始时间">
                <Input type="time" value={rules.checkin_time_start}
                  onChange={(e) => setRules({ ...rules, checkin_time_start: e.target.value })} />
              </Field>
              <Field label="结束时间">
                <Input type="time" value={rules.checkin_time_end}
                  onChange={(e) => setRules({ ...rules, checkin_time_end: e.target.value })} />
              </Field>
            </div>
          )}
        </div>
        <label className="flex items-center gap-2 text-sm font-medium">
          <input type="checkbox" checked={rules.require_face}
            onChange={(e) => setRules({ ...rules, require_face: e.target.checked })}
            className="rounded" />
          要求人脸识别
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
function Modal({ title, onClose, children, wide }: { title: string; onClose: () => void; children: React.ReactNode; wide?: boolean }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={onClose}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 35 }}
        className={`bg-card rounded-2xl shadow-xl w-full ${wide ? "max-w-lg" : "max-w-sm"} mx-4 p-6 max-h-[90vh] overflow-y-auto`}
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
