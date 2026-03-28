"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Search, Loader2, Pencil, Trash2, RotateCcw, ScanFace, Plus, Settings, X, MapPin, Clock, ScanLine, ChevronDown } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import { getUsers, createUser, updateUser, resetPassword, resetFace, deleteUser, getRoles, type User, type Role } from "@/lib/api"
import LocationPicker from "@/components/admin/LocationPicker"

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [roles, setRoles] = useState<Role[]>([])
  const [loading, setLoading] = useState(true)
  const [keyword, setKeyword] = useState("")
  const [showCreate, setShowCreate] = useState(false)
  const [editUser, setEditUser] = useState<User | null>(null)
  const [showReset, setShowReset] = useState<{ id: number; name: string } | null>(null)
  const [showDelete, setShowDelete] = useState<{ id: number; name: string } | null>(null)
  const [showRules, setShowRules] = useState<User | null>(null)
  const [newPwd, setNewPwd] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function load() {
    try {
      const [u, r] = await Promise.all([getUsers(), getRoles()])
      setUsers(u)
      setRoles(r)
    } finally { setLoading(false) }
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
        <Button leftIcon={<Plus size={14} />} onClick={() => setShowCreate(true)}>
          新建用户
        </Button>
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
                    <th className="px-5 py-3 text-left font-medium">打卡规则</th>
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

      {/* 新建用户弹窗 */}
      {showCreate && <CreateModal roles={roles} onClose={() => setShowCreate(false)} onCreated={load} />}

      {/* 编辑用户弹窗 */}
      {editUser && <EditModal user={editUser} roles={roles} onClose={() => setEditUser(null)} onSaved={load} />}

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

      {/* 打卡规则弹窗 */}
      {showRules && (
        <RulesModal user={showRules} onClose={() => setShowRules(null)} onSaved={load} />
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

/* ── 新建用户弹窗 ────────────────────────────────────── */
function CreateModal({ roles, onClose, onCreated }: { roles: Role[]; onClose: () => void; onCreated: () => void }) {
  const [form, setForm] = useState({
    username: "",
    full_name: "",
    password: "",
    role_id: (roles[0]?.id ?? null) as number | null,
    is_active: true,
  })
  const [saving, setSaving] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    setErrMsg("")
    try {
      await createUser({
        username: form.username,
        full_name: form.full_name,
        password: form.password,
        role_id: form.role_id ?? undefined,
      })
      // 如果需要设置 is_active，创建后再 patch（因为 createUser 默认 is_active=false）
      onCreated()
      onClose()
    } catch (err: any) {
      setErrMsg(err.response?.data?.detail ?? "创建失败，请重试")
    } finally { setSaving(false) }
  }

  return (
    <Modal title="新建用户" onClose={onClose}>
      <form className="space-y-4" onSubmit={handleSubmit}>
        <div className="grid grid-cols-2 gap-3">
          <Field label="账号">
            <Input value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })} placeholder="英文/数字/下划线" required />
          </Field>
          <Field label="姓名">
            <Input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} placeholder="真实姓名" required />
          </Field>
        </div>
        <Field label="密码">
          <Input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} placeholder="初始密码" required />
        </Field>
        <Field label="角色">
          <SelectField
            value={form.role_id}
            onChange={(v) => setForm({ ...form, role_id: v ? Number(v) : null })}
            options={roles.map((r) => ({ value: r.id, label: r.name }))}
            placeholder="未分配角色"
          />
        </Field>
        {errMsg && <p className="text-destructive text-xs">{errMsg}</p>}
        <div className="flex justify-end gap-2 pt-3 border-t border-border">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={saving}>创建</Button>
        </div>
      </form>
    </Modal>
  )
}

/* ── 编辑用户弹窗 ────────────────────────────────────── */
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
      setErrMsg(err.response?.data?.detail ?? "保存失败，请重试")
    } finally { setSaving(false) }
  }

  return (
    <Modal title={`编辑用户 — ${user.username}`} onClose={onClose}>
      <form className="space-y-4" onSubmit={handleSave}>
        <Field label="姓名">
          <Input value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} required />
        </Field>
        <Field label="角色">
          <SelectField
            value={form.role_id}
            onChange={(v) => setForm({ ...form, role_id: v ? Number(v) : null })}
            options={roles.map((r) => ({ value: r.id, label: r.name }))}
            placeholder="未分配角色"
          />
        </Field>
        <Toggle checked={form.is_active} label="账户已激活" onChange={(v) => setForm({ ...form, is_active: v })} />
        {errMsg && <p className="text-destructive text-xs">{errMsg}</p>}
        <div className="flex justify-end gap-2 pt-3 border-t border-border">
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
      <form className="space-y-3" onSubmit={handleSave}>
        {/* 地点打卡 */}
        <div className="space-y-3">
          <Toggle checked={rules.require_location} icon={<MapPin size={16} />} label="要求地点打卡"
            onChange={(v) => setRules({ ...rules, require_location: v })} />
          {rules.require_location && (
            <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} className="space-y-3 pl-2 border-l-2 border-primary/20 ml-2">
              <div className="pl-3">
                <LocationPicker
                  lat={rules.location_lat} lng={rules.location_lng} radius={rules.location_radius}
                  onChange={(lat, lng) => setRules({ ...rules, location_lat: String(lat), location_lng: String(lng) })}
                />
                <div className="grid grid-cols-3 gap-2 mt-2">
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
            </motion.div>
          )}
        </div>

        {/* 时间段打卡 */}
        <div className="space-y-3">
          <Toggle checked={rules.require_time} icon={<Clock size={16} />} label="要求时间段打卡"
            onChange={(v) => setRules({ ...rules, require_time: v })} />
          {rules.require_time && (
            <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} className="pl-2 border-l-2 border-primary/20 ml-2">
              <div className="grid grid-cols-2 gap-2 pl-3">
                <Field label="开始时间">
                  <Input type="time" value={rules.checkin_time_start}
                    onChange={(e) => setRules({ ...rules, checkin_time_start: e.target.value })} />
                </Field>
                <Field label="结束时间">
                  <Input type="time" value={rules.checkin_time_end}
                    onChange={(e) => setRules({ ...rules, checkin_time_end: e.target.value })} />
                </Field>
              </div>
            </motion.div>
          )}
        </div>

        {/* 人脸识别 */}
        <Toggle checked={rules.require_face} icon={<ScanLine size={16} />} label="要求人脸识别"
          onChange={(v) => setRules({ ...rules, require_face: v })} />

        <div className="flex justify-end gap-2 pt-3 border-t border-border mt-4">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={saving}>保存规则</Button>
        </div>
      </form>
    </Modal>
  )
}

/* ── 通用组件 ─────────────────────────────────────────── */
function Modal({ title, onClose, children, wide }: { title: string; onClose: () => void; children: React.ReactNode; wide?: boolean }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-[2px]" onClick={onClose}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 35 }}
        className={`bg-card rounded-2xl shadow-xl w-full ${wide ? "max-w-lg" : "max-w-sm"} mx-4 max-h-[90vh] overflow-y-auto`}
        onClick={(e) => e.stopPropagation()}
        style={{ boxShadow: "0 20px 60px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.6)" }}
      >
        <div className="flex items-center justify-between px-6 pt-5 pb-4 border-b border-border">
          <h2 className="text-base font-semibold">{title}</h2>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-muted/60 text-muted-foreground hover:text-foreground transition-colors">
            <X size={16} />
          </button>
        </div>
        <div className="px-6 py-5">
          {children}
        </div>
      </motion.div>
    </div>
  )
}

function Field({ label, error, children }: { label: string; error?: string; children: React.ReactNode }) {
  return (
    <div className="space-y-1.5">
      <label className="text-xs font-medium text-muted-foreground uppercase tracking-wide">{label}</label>
      {children}
      {error && <p className="text-destructive text-xs mt-1">{error}</p>}
    </div>
  )
}

function Toggle({ checked, onChange, label, icon }: { checked: boolean; onChange: (v: boolean) => void; label: string; icon?: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className={`flex items-center gap-3 w-full px-3 py-2.5 rounded-xl border transition-all ${
        checked ? "border-primary/30 bg-primary/5" : "border-border bg-background hover:bg-muted/40"
      }`}
    >
      {icon && <span className={`${checked ? "text-primary" : "text-muted-foreground"} transition-colors`}>{icon}</span>}
      <span className="text-sm font-medium flex-1 text-left">{label}</span>
      <div className={`w-9 h-5 rounded-full transition-colors relative ${checked ? "bg-primary" : "bg-muted-foreground/30"}`}>
        <div className={`absolute top-0.5 w-4 h-4 rounded-full bg-white shadow-sm transition-transform ${checked ? "translate-x-4" : "translate-x-0.5"}`} />
      </div>
    </button>
  )
}

function SelectField({ value, onChange, options, placeholder }: {
  value: string | number | null; onChange: (v: string) => void;
  options: { value: string | number; label: string }[]; placeholder?: string
}) {
  return (
    <div className="relative">
      <select
        className="w-full h-9 rounded-xl border border-border bg-background px-3 pr-8 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 appearance-none"
        value={value ?? ""}
        onChange={(e) => onChange(e.target.value)}
      >
        {placeholder && <option value="">{placeholder}</option>}
        {options.map((o) => (
          <option key={o.value} value={o.value}>{o.label}</option>
        ))}
      </select>
      <ChevronDown size={14} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground pointer-events-none" />
    </div>
  )
}
