import { NextRequest, NextResponse } from 'next/server'
import { checkDatabaseHealth, checkExternalServices, getSystemMetrics, PerformanceMonitor, ErrorTracker } from '@/lib/monitoring'

export async function GET(request: NextRequest) {
  try {
    const [dbHealth, externalServices, systemMetrics] = await Promise.all([
      checkDatabaseHealth(),
      checkExternalServices(),
      Promise.resolve(getSystemMetrics())
    ])

    const performanceMonitor = PerformanceMonitor.getInstance()
    const errorTracker = ErrorTracker.getInstance()

    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: dbHealth,
        external: externalServices
      },
      system: systemMetrics,
      performance: performanceMonitor.getAllMetrics(),
      errors: errorTracker.getErrorStats()
    }

    // Determine overall health status
    if (!dbHealth.healthy) {
      health.status = 'unhealthy'
    } else if (Object.values(externalServices).some(service => !service.healthy)) {
      health.status = 'degraded'
    }

    const statusCode = health.status === 'healthy' ? 200 : 503

    return NextResponse.json(health, { status: statusCode })
  } catch (error) {
    return NextResponse.json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 503 })
  }
}