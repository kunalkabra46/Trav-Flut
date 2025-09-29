import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  return NextResponse.json({
    message: 'Simple media test endpoint working',
    timestamp: new Date().toISOString()
  })
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    return NextResponse.json({
      message: 'Simple media test POST working',
      receivedData: body,
      timestamp: new Date().toISOString(),
      status: 'success'
    })
  } catch (error) {
    return NextResponse.json({
      error: 'Failed to parse request body',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 400 })
  }
}
