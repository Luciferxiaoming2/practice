"use client"
import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { PasswordInput } from "@/components/ui/password-input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { scaleIn } from "@/lib/motion"
import { register } from "@/lib/api"

function validate(form: { username: string; full_name: string; password: string; confirm: string }) {
  const errors: Record<string, string> = {}
  if (form.username.length < 3) errors.username = "账号至少 3 个字符"
  else if (!/^[a-zA-Z0-9_]+$/.test(form.username)) errors.username = "只能包含字母、数字和下划线"
  if (form.full_name.trim().length < 2) errors.full_name = "姓名至少 2 个字符"
  if (form.password.length < 8) errors.password = "密码至少 8 位"
  else if (!/[A-Za-z]/.test(form.password)) errors.password = "需包含至少 1 个字母"
  else if (!/[0-9]/.test(form.password)) errors.password = "需包含至少 1 个数字"
  if (form.confirm !== form.password) errors.confirm = "两次密码不一致"
  return errors
}

export default function RegisterPage() {
  const router = useRouter()
  const [form, setForm] = useState({ username: "", full_name: "", password: "", confirm: "" })
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})
  const [serverError, setServerError] = useState("")
  const [loading, setLoading] = useState(false)

  function set(key: string, value: string) {
    setForm((f) => ({ ...f, [key]: value }))
    setFieldErrors((e) => ({ ...e, [key]: "" }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setServerError("")
    const errors = validate(form)
    if (Object.keys(errors).length > 0) { setFieldErrors(errors); return }
    setLoading(true)
    try {
      await register(form.username, form.full_name, form.password)
      router.push("/login?registered=1")
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail
      setServerError(msg ?? "注册失败，请稍后重试")
    } finally {
      setLoading(false)
    }
  }

  return (
    <main
      className="flex items-center justify-center min-h-screen"
      style={{
        background:
          "linear-gradient(135deg, hsl(var(--background)) 0%, color-mix(in srgb, hsl(var(--primary)) 8%, hsl(var(--background))) 100%)",
      }}
    >
      <motion.div variants={scaleIn} initial="hidden" animate="visible" className="w-full max-w-sm px-4">
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold" style={{ color: "hsl(var(--primary))" }}>熵析云枢</h1>
          <p className="text-muted-foreground text-sm mt-1">打卡管理系统</p>
        </div>
        <Card>
          <CardHeader>
            <CardTitle className="text-center text-lg">注册账户</CardTitle>
          </CardHeader>
          <CardContent>
            <form className="space-y-4" onSubmit={handleSubmit}>
              <Field label="账号" error={fieldErrors.username}>
                <Input placeholder="字母/数字/下划线，至少 3 位" value={form.username}
                  onChange={(e) => set("username", e.target.value)}
                  className={fieldErrors.username ? "border-destructive focus-visible:ring-destructive" : ""}
                  required />
              </Field>
              <Field label="姓名" error={fieldErrors.full_name}>
                <Input placeholder="真实姓名" value={form.full_name}
                  onChange={(e) => set("full_name", e.target.value)}
                  className={fieldErrors.full_name ? "border-destructive focus-visible:ring-destructive" : ""}
                  required />
              </Field>
              <Field label="密码" error={fieldErrors.password}>
                <PasswordInput placeholder="至少 8 位，含字母和数字" value={form.password}
                  onChange={(e) => set("password", e.target.value)}
                  className={fieldErrors.password ? "border-destructive focus-visible:ring-destructive" : ""}
                  required />
              </Field>
              <Field label="确认密码" error={fieldErrors.confirm}>
                <PasswordInput placeholder="再次输入密码" value={form.confirm}
                  onChange={(e) => set("confirm", e.target.value)}
                  className={fieldErrors.confirm ? "border-destructive focus-visible:ring-destructive" : ""}
                  required />
              </Field>
              {serverError && <p className="text-destructive text-sm">{serverError}</p>}
              <Button className="w-full mt-2" size="md" isLoading={loading}>注册</Button>
            </form>
            <p className="text-center text-sm text-muted-foreground mt-4">
              已有账户？{" "}
              <Link href="/login" className="text-primary hover:underline">去登录</Link>
            </p>
          </CardContent>
        </Card>
      </motion.div>
    </main>
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
