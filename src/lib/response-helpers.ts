import { NextResponse } from 'next/server'

// Success response helpers
export function ok<T>(data: T, status: number = 200) {
  return NextResponse.json({
    success: true,
    data
  }, { status })
}

export function created<T>(data: T) {
  return ok(data, 201)
}

// Error response helpers
export function badRequest(message: string, details?: any) {
  return NextResponse.json({
    success: false,
    error: message,
    ...(details && { details })
  }, { status: 400 })
}

export function unauthorized(message: string = 'Unauthorized') {
  return NextResponse.json({
    success: false,
    error: message
  }, { status: 401 })
}

export function forbidden(message: string = 'Forbidden') {
  return NextResponse.json({
    success: false,
    error: message
  }, { status: 403 })
}

export function notFound(message: string = 'Resource not found') {
  return NextResponse.json({
    success: false,
    error: message
  }, { status: 404 })
}

export function conflict(message: string) {
  return NextResponse.json({
    success: false,
    error: message
  }, { status: 409 })
}

export function serverError(message: string = 'Internal server error') {
  return NextResponse.json({
    success: false,
    error: message
  }, { status: 500 })
}
