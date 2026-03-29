"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Plus, Pencil, Trash2, X, Loader2, Settings, MapPin, Clock, ScanLine, ChevronDown, LogIn, LogOut } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import {
  getDepartments,
  getUsers,
  createDepartment,
  updateDepartment,
  deleteDepartment,
  batchDepartmentRules,
  type Department,
  type User,
} from "@/lib/api"
import dynamic from "next/dynamic"

const LocationPicker = dynamic(() => import("@/components/admin/LocationPicker"), { ssr: false })

export default function DepartmentsPage() {
  const [departments, setDepartments] = useState<Department[]>([])
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [editDept, setEditDept] = useState<Department | null>(null)
  const [showDelete, setShowDelete] = useState<Department | null>(null)
  const [showRules, setShowRules] = useState<Department | null>(null)

  // 按部门统计人数
  const deptCount = new Map<number, number>()
  users.forEach((u) => {
    if (u.department_id != null) {
      deptCount.set(u.department_id, (deptCount.get(u.department_id) ?? 0) + 1)
    }
  })

  async function load() {
    try {
      const [d, u] = await Promise.all([getDepartments(), getUsers()])
      setDepartments(d)
      setUsers(u)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  return (
    <div>
      <motion.div className="flex items-center justify-between mb-6" variants={fadeInUp} initial="hidden" animate="visible">
        <div>
          <h1 className="text-2xl font-bold">部门管理</h1>
          <p className="text-muted-foreground text-sm mt-0.5">新建、编辑部门及批量打卡规则设置</p>
        </div>
        <Button leftIcon={<Plus size={16} />} onClick={() => setShowCreate(true)}>
          新建部门
        </Button>
      </motion.div>

      {loading ? (
        <div className="flex justify-center py-20 text-muted-foreground">
          <Loader2 className="animate-spin" />
        </div>
      ) : (
        <motion.div variants={staggerContainer} initial="hidden" animate="visible">
          {departments.length === 0 ? (
            <motion.div variants={staggerItem}>
              <Card className="flex flex-col items-center justify-center py-20 text-muted-foreground">
                <p className="text-sm">暂无部门，点击右上角新建</p>
              </Card>
            </motion.div>
          ) : (
            <Card>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-muted-foreground text-xs">
                    <th className="px-5 py-3 text-left font-medium">ID</th>
                    <th className="px-5 py-3 text-left font-medium">部门名称</th>
                    <th className="px-5 py-3 text-left font-medium">人数</th>
                    <th className="px-5 py-3 text-left font-medium">描述</th>
                    <th className="px-5 py-3 text-left font-medium">操作</th>
                  </tr>
                </thead>
                <tbody>
                  {departments.map((dept) => (
                    <motion.tr key={dept.id} variants={staggerItem} className="border-b border-border last:border-0 hover:bg-muted/40 transition-colors">
                      <td className="px-5 py-3 font-mono text-xs">{dept.id}</td>
                      <td className="px-5 py-3 font-medium">{dept.name}</td>
                      <td className="px-5 py-3">
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-primary/10 text-primary">
                          {deptCount.get(dept.id) ?? 0} 人
                        </span>
                      </td>
                      <td className="px-5 py-3 text-muted-foreground">{dept.description || "—"}</td>
                      <td className="px-5 py-3">
                        <div className="flex gap-2">
                          <Button size="sm" variant="outline" leftIcon={<Pencil size={12} />}
                            onClick={() => setEditDept(dept)}>
                            编辑
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<Settings size={12} />}
                            onClick={() => setShowRules(dept)}>
                            批量设置打卡规则
                          </Button>
                          <Button size="sm" variant="outline" leftIcon={<Trash2 size={12} />}
                            onClick={() => setShowDelete(dept)}
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

      {showCreate && (
        <CreateModal onClose={() => setShowCreate(false)} onCreated={load} />
      )}

      {editDept && (
        <EditModal dept={editDept} onClose={() => setEditDept(null)} onSaved={load} />
      )}

      {showDelete && (
        <DeleteModal dept={showDelete} onClose={() => setShowDelete(null)} onDeleted={load} />
      )}

      {showRules && (
        <BatchRulesModal dept={showRules} onClose={() => setShowRules(null)} onSaved={load} />
      )}
    </div>
  )
}

/* -- Create Modal -- */
function CreateModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const [form, setForm] = useState({ name: "", description: "" })
  const [submitting, setSubmitting] = useState(false)
  const [msg, setMsg] = useState("")

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setMsg("")
    setSubmitting(true)
    try {
      await createDepartment({
        name: form.name,
        description: form.description || undefined,
      })
      onCreated()
      onClose()
    } catch (err: any) {
      setMsg(err.response?.data?.detail ?? "创建失败")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Modal title="新建部门" onClose={onClose}>
      <form className="space-y-3" onSubmit={handleSubmit}>
        <Field label="部门名称">
          <Input placeholder="输入部门名称" value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })} required />
        </Field>
        <Field label="描述">
          <Input placeholder="可选描述" value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })} />
        </Field>
        {msg && <p className="text-destructive text-xs">{msg}</p>}
        <div className="flex justify-end gap-2 pt-3 border-t border-border">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={submitting}>创建</Button>
        </div>
      </form>
    </Modal>
  )
}

/* -- Edit Modal -- */
function EditModal({ dept, onClose, onSaved }: { dept: Department; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({ name: dept.name, description: dept.description ?? "" })
  const [saving, setSaving] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    setErrMsg("")
    try {
      await updateDepartment(dept.id, {
        name: form.name,
        description: form.description || null,
      })
      onSaved()
      onClose()
    } catch (err: any) {
      setErrMsg(err.response?.data?.detail ?? "保存失败")
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={`编辑部门 — ${dept.name}`} onClose={onClose}>
      <form className="space-y-3" onSubmit={handleSave}>
        <Field label="部门名称">
          <Input value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })} required />
        </Field>
        <Field label="描述">
          <Input value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })} />
        </Field>
        {errMsg && <p className="text-destructive text-xs">{errMsg}</p>}
        <div className="flex justify-end gap-2 pt-3 border-t border-border">
          <Button type="button" variant="outline" onClick={onClose}>取消</Button>
          <Button type="submit" isLoading={saving}>保存</Button>
        </div>
      </form>
    </Modal>
  )
}

/* -- Delete Confirmation Modal -- */
function DeleteModal({ dept, onClose, onDeleted }: { dept: Department; onClose: () => void; onDeleted: () => void }) {
  const [submitting, setSubmitting] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function handleDelete() {
    setSubmitting(true)
    setErrMsg("")
    try {
      await deleteDepartment(dept.id)
      onDeleted()
      onClose()
    } catch {
      setErrMsg("删除失败，请重试")
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Modal title="确认删除" onClose={onClose}>
      <p className="text-sm text-muted-foreground mb-4">
        确定要删除部门 <span className="font-semibold text-foreground">{dept.name}</span> 吗？此操作不可撤销。
      </p>
      {errMsg && <p className="text-destructive text-xs mb-3">{errMsg}</p>}
      <div className="flex justify-end gap-2">
        <Button variant="outline" onClick={onClose}>取消</Button>
        <Button variant="destructive" isLoading={submitting} onClick={handleDelete}>确认删除</Button>
      </div>
    </Modal>
  )
}

/* -- Batch Rules Modal -- */
function BatchRulesModal({ dept, onClose, onSaved }: { dept: Department; onClose: () => void; onSaved: () => void }) {
  const [rules, setRules] = useState({
    require_sign_in: dept.require_sign_in ?? true,
    require_sign_out: dept.require_sign_out ?? false,
    require_location: dept.require_location ?? false,
    location_lat: dept.location_lat?.toString() ?? "",
    location_lng: dept.location_lng?.toString() ?? "",
    location_radius: dept.location_radius?.toString() ?? "",
    require_time: dept.require_time ?? false,
    checkin_time_start: dept.checkin_time_start ?? "",
    checkin_time_end: dept.checkin_time_end ?? "",
    sign_out_time_start: dept.sign_out_time_start ?? "",
    sign_out_time_end: dept.sign_out_time_end ?? "",
    require_face: dept.require_face ?? false,
  })
  const [saving, setSaving] = useState(false)

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      await batchDepartmentRules(dept.id, {
        require_sign_in: rules.require_sign_in,
        require_sign_out: rules.require_sign_out,
        require_location: rules.require_location,
        location_lat: rules.location_lat === "" ? null : Number(rules.location_lat),
        location_lng: rules.location_lng === "" ? null : Number(rules.location_lng),
        location_radius: rules.location_radius === "" ? null : Number(rules.location_radius),
        require_time: rules.require_time,
        checkin_time_start: rules.checkin_time_start || null,
        checkin_time_end: rules.checkin_time_end || null,
        sign_out_time_start: rules.sign_out_time_start || null,
        sign_out_time_end: rules.sign_out_time_end || null,
        require_face: rules.require_face,
      })
      onSaved()
      onClose()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal title={`批量设置打卡规则 — ${dept.name}`} onClose={onClose} wide>
      <form className="space-y-3" onSubmit={handleSave}>
        <p className="text-xs text-muted-foreground mb-2">
          以下规则将批量应用到该部门下的所有用户。
        </p>

        {/* 签到 */}
        <Toggle checked={rules.require_sign_in} icon={<LogIn size={16} />} label="要求签到"
          onChange={(v) => setRules({ ...rules, require_sign_in: v })} />

        {/* 签退 */}
        <Toggle checked={rules.require_sign_out} icon={<LogOut size={16} />} label="要求签退"
          onChange={(v) => setRules({ ...rules, require_sign_out: v })} />

        {/* Location */}
        <div className="space-y-3">
          <Toggle checked={rules.require_location} icon={<MapPin size={16} />} label="要求地点打卡"
            onChange={(v) => setRules({ ...rules, require_location: v })} />
          {rules.require_location && (
            <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} className="space-y-3 pl-2 border-l-2 border-primary/20 ml-2">
              <div className="pl-3 space-y-3">
                <LocationPicker
                  lat={rules.location_lat} lng={rules.location_lng} radius={rules.location_radius}
                  onChange={(lat, lng) => setRules({ ...rules, location_lat: String(lat), location_lng: String(lng) })}
                />
                <div className="grid grid-cols-3 gap-2">
                  <Field label="纬度">
                    <Input type="number" step="any" placeholder="30.2741" value={rules.location_lat}
                      min="-90" max="90"
                      onChange={(e) => setRules({ ...rules, location_lat: e.target.value })} />
                  </Field>
                  <Field label="经度">
                    <Input type="number" step="any" placeholder="120.1551" value={rules.location_lng}
                      min="-180" max="180"
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

        {/* Time */}
        <div className="space-y-3">
          <Toggle checked={rules.require_time} icon={<Clock size={16} />} label="要求时间段打卡"
            onChange={(v) => setRules({ ...rules, require_time: v })} />
          {rules.require_time && (
            <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} className="pl-2 border-l-2 border-primary/20 ml-2 space-y-3">
              <div className="pl-3">
                <p className="text-xs font-medium text-muted-foreground mb-1.5">签到时间窗口</p>
                <div className="grid grid-cols-2 gap-2">
                  <Field label="签到开始">
                    <Input type="time" value={rules.checkin_time_start}
                      onChange={(e) => setRules({ ...rules, checkin_time_start: e.target.value })} />
                  </Field>
                  <Field label="签到结束">
                    <Input type="time" value={rules.checkin_time_end}
                      onChange={(e) => setRules({ ...rules, checkin_time_end: e.target.value })} />
                  </Field>
                </div>
              </div>
              <div className="pl-3">
                <p className="text-xs font-medium text-muted-foreground mb-1.5">签退时间窗口</p>
                <div className="grid grid-cols-2 gap-2">
                  <Field label="签退开始">
                    <Input type="time" value={rules.sign_out_time_start}
                      onChange={(e) => setRules({ ...rules, sign_out_time_start: e.target.value })} />
                  </Field>
                  <Field label="签退结束">
                    <Input type="time" value={rules.sign_out_time_end}
                      onChange={(e) => setRules({ ...rules, sign_out_time_end: e.target.value })} />
                  </Field>
                </div>
              </div>
            </motion.div>
          )}
        </div>

        {/* Face */}
        <Toggle checked={rules.require_face} icon={<ScanLine size={16} />} label="要求人脸识别"
          onChange={(v) => setRules({ ...rules, require_face: v })} />

        <div className="flex justify-between pt-3 border-t border-border mt-4">
          <Button type="button" variant="outline"
            onClick={() => setRules({
              require_sign_in: true, require_sign_out: false,
              require_location: false, location_lat: "", location_lng: "", location_radius: "",
              require_time: false, checkin_time_start: "", checkin_time_end: "",
              sign_out_time_start: "", sign_out_time_end: "",
              require_face: false,
            })}>
            清空规则
          </Button>
          <div className="flex gap-2">
            <Button type="button" variant="outline" onClick={onClose}>取消</Button>
            <Button type="submit" isLoading={saving}>保存规则</Button>
          </div>
        </div>
      </form>
    </Modal>
  )
}

/* -- Shared Components -- */
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
