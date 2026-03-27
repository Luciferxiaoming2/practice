import axios from "axios"
import Cookies from "js-cookie"

export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000",
})

// 自动附加 token
api.interceptors.request.use((config) => {
  const token = Cookies.get("token")
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 401 自动跳登录
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && typeof window !== "undefined") {
      Cookies.remove("token")
      window.location.href = "/login"
    }
    return Promise.reject(err)
  }
)

// ── Auth ──────────────────────────────────────────────
export async function login(username: string, password: string) {
  const { data } = await api.post("/auth/login", { username, password })
  return data as { access_token: string; token_type: string }
}

export async function register(username: string, full_name: string, password: string) {
  const { data } = await api.post<User>("/auth/register", { username, full_name, password })
  return data
}

// ── Users ─────────────────────────────────────────────
export interface User {
  id: number
  username: string
  full_name: string
  is_active: boolean
  is_admin: boolean
  face_enrolled: boolean
  require_location: boolean
  location_lat: number | null
  location_lng: number | null
  location_radius: number | null
  require_time: boolean
  checkin_time_start: string | null
  checkin_time_end: string | null
  require_face: boolean
}

export async function getUsers() {
  const { data } = await api.get<User[]>("/users/")
  return data
}

export async function createUser(body: {
  username: string
  full_name: string
  password: string
  is_admin?: boolean
}) {
  const { data } = await api.post<User>("/users/", body)
  return data
}

export async function updateUser(id: number, body: Partial<User>) {
  const { data } = await api.patch<User>(`/users/${id}`, body)
  return data
}

export async function resetPassword(id: number, newPassword: string) {
  await api.post(`/users/${id}/reset-password`, { new_password: newPassword })
}

export async function resetFace(id: number) {
  await api.post(`/users/${id}/reset-face`)
}

// ── Checkins ──────────────────────────────────────────
export interface CheckIn {
  id: number
  user_id: number
  timestamp: string
  lat: number | null
  lng: number | null
  status: string
}

export async function getCheckins(params?: {
  user_id?: number
  date_from?: string
  date_to?: string
}) {
  const { data } = await api.get<CheckIn[]>("/checkins/", { params })
  return data
}
