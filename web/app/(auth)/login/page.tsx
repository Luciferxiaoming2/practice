"use client"
import { useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import Link from "next/link"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { PasswordInput } from "@/components/ui/password-input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { useAuth } from "@/lib/auth-context"
import { scaleIn } from "@/lib/motion"

export default function LoginPage() {
  const { signIn } = useAuth()
  const router = useRouter()
  const searchParams = useSearchParams()
  const justRegistered = searchParams.get("registered") === "1"
  const [username, setUsername] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError("")
    setLoading(true)
    try {
      await signIn(username, password)
      router.push("/dashboard")
    } catch {
      setError("账号或密码错误")
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
          <h1 className="text-2xl font-bold" style={{ color: "hsl(var(--primary))" }}>
            熵析云枢
          </h1>
          <p className="text-muted-foreground text-sm mt-1">打卡管理系统</p>
        </div>
        <Card>
          <CardHeader>
            <CardTitle className="text-center text-lg">管理员登录</CardTitle>
          </CardHeader>
          <CardContent>
            {justRegistered && (
              <p className="text-sm text-green-600 bg-green-50 rounded-xl px-3 py-2 mb-4 text-center">
                注册成功，请登录
              </p>
            )}
            <form className="space-y-4" onSubmit={handleSubmit}>
              <div className="space-y-1.5">
                <label className="text-sm font-medium">账号</label>
                <Input
                  type="text"
                  placeholder="请输入账号"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-sm font-medium">密码</label>
                <PasswordInput
                  placeholder="请输入密码"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>
              {error && <p className="text-destructive text-sm">{error}</p>}
              <Button className="w-full mt-2" size="md" isLoading={loading}>
                登录
              </Button>
            </form>
            <p className="text-center text-sm text-muted-foreground mt-4">
              没有账户？{" "}
              <Link href="/register" className="text-primary hover:underline">去注册</Link>
            </p>
          </CardContent>
        </Card>
      </motion.div>
    </main>
  )
}
