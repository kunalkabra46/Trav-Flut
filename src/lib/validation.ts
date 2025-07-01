import { z } from 'zod'

// Enhanced validation schemas with better error messages and security
export const signupSchema = z.object({
  email: z.string()
    .email('Please enter a valid email address')
    .max(255, 'Email must be less than 255 characters')
    .transform(email => email.toLowerCase().trim()),
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password must be less than 128 characters')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  name: z.string()
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must be less than 100 characters')
    .regex(/^[a-zA-Z\s'-]+$/, 'Name can only contain letters, spaces, hyphens, and apostrophes')
    .transform(name => name.trim()),
  username: z.string()
    .min(3, 'Username must be at least 3 characters')
    .max(30, 'Username must be less than 30 characters')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores')
    .transform(username => username.toLowerCase().trim())
    .optional()
})

export const loginSchema = z.object({
  email: z.string()
    .email('Please enter a valid email address')
    .transform(email => email.toLowerCase().trim()),
  password: z.string()
    .min(1, 'Password is required')
    .max(128, 'Password is too long')
})

export const updateProfileSchema = z.object({
  name: z.string()
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must be less than 100 characters')
    .regex(/^[a-zA-Z\s'-]+$/, 'Name can only contain letters, spaces, hyphens, and apostrophes')
    .transform(name => name.trim())
    .optional(),
  username: z.string()
    .min(3, 'Username must be at least 3 characters')
    .max(30, 'Username must be less than 30 characters')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores')
    .transform(username => username.toLowerCase().trim())
    .optional(),
  bio: z.string()
    .max(500, 'Bio must be less than 500 characters')
    .transform(bio => bio.trim())
    .optional(),
  avatarUrl: z.string()
    .url('Please enter a valid URL')
    .max(2048, 'URL is too long')
    .optional()
})

// Trip validation schemas with enhanced security
export const createTripSchema = z.object({
  title: z.string()
    .min(1, 'Title is required')
    .max(100, 'Title must be less than 100 characters')
    .transform(title => title.trim()),
  description: z.string()
    .max(500, 'Description must be less than 500 characters')
    .transform(desc => desc.trim())
    .optional(),
  startDate: z.string()
    .datetime('Invalid start date format')
    .optional()
    .refine((date) => {
      if (!date) return true
      const startDate = new Date(date)
      const now = new Date()
      now.setHours(0, 0, 0, 0) // Start of today
      return startDate >= now
    }, 'Start date cannot be in the past'),
  endDate: z.string()
    .datetime('Invalid end date format')
    .optional(),
  destinations: z.array(
    z.string()
      .min(1, 'Destination cannot be empty')
      .max(100, 'Destination name is too long')
      .transform(dest => dest.trim())
  )
    .min(1, 'At least one destination is required')
    .max(10, 'Maximum 10 destinations allowed'),
  mood: z.enum(['RELAXED', 'ADVENTURE', 'SPIRITUAL', 'CULTURAL', 'PARTY', 'MIXED']).optional(),
  type: z.enum(['SOLO', 'GROUP', 'COUPLE', 'FAMILY']).optional(),
  coverMediaUrl: z.string()
    .url('Please enter a valid URL')
    .max(2048, 'URL is too long')
    .optional()
}).refine((data) => {
  if (data.startDate && data.endDate) {
    return new Date(data.startDate) <= new Date(data.endDate)
  }
  return true
}, {
  message: 'End date must be after start date',
  path: ['endDate']
})

export const createThreadEntrySchema = z.object({
  type: z.enum(['TEXT', 'MEDIA', 'LOCATION', 'CHECKIN']),
  contentText: z.string()
    .max(1000, 'Content must be less than 1000 characters')
    .transform(text => text.trim())
    .optional(),
  mediaUrl: z.string()
    .url('Please enter a valid media URL')
    .max(2048, 'URL is too long')
    .optional(),
  locationName: z.string()
    .max(200, 'Location name must be less than 200 characters')
    .transform(name => name.trim())
    .optional(),
  gpsCoordinates: z.object({
    lat: z.number()
      .min(-90, 'Latitude must be between -90 and 90')
      .max(90, 'Latitude must be between -90 and 90'),
    lng: z.number()
      .min(-180, 'Longitude must be between -180 and 180')
      .max(180, 'Longitude must be between -180 and 180')
  }).optional(),
  taggedUserIds: z.array(
    z.string().uuid('Invalid user ID format')
  )
    .max(10, 'Maximum 10 users can be tagged')
    .optional()
}).refine((data) => {
  // Type-specific validation
  switch (data.type) {
    case 'TEXT':
      return data.contentText && data.contentText.length > 0
    case 'MEDIA':
      return data.mediaUrl && data.mediaUrl.length > 0
    case 'LOCATION':
      return data.locationName && data.locationName.length > 0
    case 'CHECKIN':
      return data.locationName && data.locationName.length > 0
    default:
      return false
  }
}, {
  message: 'Required fields missing for entry type'
})

export const addParticipantSchema = z.object({
  userId: z.string().uuid('Invalid user ID format'),
  role: z.string()
    .max(50, 'Role name is too long')
    .regex(/^[a-zA-Z_]+$/, 'Role can only contain letters and underscores')
    .optional()
})

export const updateFinalPostSchema = z.object({
  summaryText: z.string()
    .min(1, 'Summary text is required')
    .max(2000, 'Summary must be less than 2000 characters')
    .transform(text => text.trim()),
  curatedMedia: z.array(
    z.string().url('Invalid media URL')
  )
    .max(20, 'Maximum 20 media items allowed'),
  caption: z.string()
    .max(500, 'Caption must be less than 500 characters')
    .transform(caption => caption.trim())
    .optional()
})

// Pagination schema
export const paginationSchema = z.object({
  page: z.string()
    .regex(/^\d+$/, 'Page must be a number')
    .transform(Number)
    .refine(n => n >= 1, 'Page must be at least 1')
    .default('1'),
  limit: z.string()
    .regex(/^\d+$/, 'Limit must be a number')
    .transform(Number)
    .refine(n => n >= 1 && n <= 100, 'Limit must be between 1 and 100')
    .default('20')
})

// File upload validation
export const fileUploadSchema = z.object({
  filename: z.string()
    .min(1, 'Filename is required')
    .max(255, 'Filename is too long')
    .regex(/^[a-zA-Z0-9._-]+$/, 'Invalid filename format'),
  contentType: z.string()
    .regex(/^(image|video)\/(jpeg|jpg|png|gif|mp4|mov|avi)$/, 'Unsupported file type'),
  size: z.number()
    .min(1, 'File cannot be empty')
    .max(50 * 1024 * 1024, 'File size cannot exceed 50MB') // 50MB limit
})

// Search and filter schemas
export const tripFilterSchema = z.object({
  status: z.enum(['UPCOMING', 'ONGOING', 'ENDED']).optional(),
  mood: z.enum(['RELAXED', 'ADVENTURE', 'SPIRITUAL', 'CULTURAL', 'PARTY', 'MIXED']).optional(),
  type: z.enum(['SOLO', 'GROUP', 'COUPLE', 'FAMILY']).optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional()
})

// Rate limiting validation
export const rateLimitSchema = z.object({
  maxRequests: z.number().min(1).max(1000).default(100),
  windowMs: z.number().min(1000).max(3600000).default(60000) // 1 second to 1 hour
})