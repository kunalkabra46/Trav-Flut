import { Trip, User } from '../types';

export const mockUser: User = {
  id: '1',
  name: 'Sarah Chen',
  username: 'sarahexplores',
  avatar: 'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=150&h=150&dpr=2',
  bio: 'Digital nomad • Travel photographer • Food enthusiast',
  followers: 2847,
  following: 891,
  trips: 23
};

export const mockTrips: Trip[] = [
  {
    id: '1',
    title: 'Tokyo Adventure',
    destination: 'Tokyo, Japan',
    startDate: new Date('2024-01-15'),
    endDate: new Date('2024-01-22'),
    status: 'completed',
    coverImage: 'https://images.pexels.com/photos/2506923/pexels-photo-2506923.jpeg?auto=compress&cs=tinysrgb&w=600',
    description: 'Exploring the vibrant culture, incredible food, and modern marvels of Tokyo',
    threads: [
      {
        id: '1',
        tripId: '1',
        timestamp: new Date('2024-01-15T10:30:00'),
        type: 'note',
        content: {
          text: 'Just arrived in Tokyo! The energy here is incredible. First stop: Shibuya Crossing to experience the famous organized chaos. The jetlag is real but the excitement is keeping me going! 🇯🇵'
        },
        location: {
          name: 'Shibuya Crossing',
          address: 'Shibuya, Tokyo, Japan',
          coordinates: { lat: 35.6591, lng: 139.7005 },
          type: 'attraction'
        }
      },
      {
        id: '2',
        tripId: '1',
        timestamp: new Date('2024-01-15T14:20:00'),
        type: 'media',
        content: {
          text: 'Lunch at this hidden ramen shop recommended by a local. The broth is absolutely divine!',
          media: [
            {
              id: '1',
              type: 'photo',
              url: 'https://images.pexels.com/photos/1907228/pexels-photo-1907228.jpeg?auto=compress&cs=tinysrgb&w=600',
              caption: 'Tonkotsu ramen perfection'
            }
          ]
        },
        location: {
          name: 'Menya Saimi',
          address: 'Shibuya, Tokyo, Japan',
          coordinates: { lat: 35.6580, lng: 139.7016 },
          type: 'restaurant'
        }
      },
      {
        id: '3',
        tripId: '1',
        timestamp: new Date('2024-01-16T09:15:00'),
        type: 'checkin',
        content: {
          text: 'Peaceful morning at Senso-ji Temple. The contrast between ancient traditions and modern Tokyo is fascinating.',
          checkIn: {
            venue: 'Senso-ji Temple',
            type: 'attraction',
            rating: 5,
            notes: 'Arrived early to avoid crowds - perfect decision!'
          }
        },
        location: {
          name: 'Senso-ji Temple',
          address: 'Asakusa, Tokyo, Japan',
          coordinates: { lat: 35.7148, lng: 139.7967 },
          type: 'attraction'
        }
      }
    ],
    totalMedia: 12,
    totalNotes: 8
  },
  {
    id: '2',
    title: 'Bali Escape',
    destination: 'Bali, Indonesia',
    startDate: new Date('2024-02-10'),
    status: 'active',
    coverImage: 'https://images.pexels.com/photos/3073666/pexels-photo-3073666.jpeg?auto=compress&cs=tinysrgb&w=600',
    description: 'Island paradise, temples, and incredible sunsets',
    threads: [
      {
        id: '4',
        tripId: '2',
        timestamp: new Date('2024-02-10T16:45:00'),
        type: 'media',
        content: {
          text: 'Sunset at Tanah Lot Temple. No words can describe this beauty.',
          media: [
            {
              id: '2',
              type: 'photo',
              url: 'https://images.pexels.com/photos/2161449/pexels-photo-2161449.jpeg?auto=compress&cs=tinysrgb&w=600',
              caption: 'Golden hour magic'
            }
          ]
        },
        location: {
          name: 'Tanah Lot Temple',
          address: 'Tabanan, Bali, Indonesia',
          coordinates: { lat: -8.6211, lng: 115.0864 },
          type: 'attraction'
        }
      }
    ],
    totalMedia: 5,
    totalNotes: 3
  },
  {
    id: '3',
    title: 'Iceland Road Trip',
    destination: 'Reykjavik, Iceland',
    startDate: new Date('2024-03-01'),
    status: 'planning',
    coverImage: 'https://images.pexels.com/photos/1586298/pexels-photo-1586298.jpeg?auto=compress&cs=tinysrgb&w=600',
    description: 'Chasing waterfalls and northern lights on the Ring Road',
    threads: [],
    totalMedia: 0,
    totalNotes: 0
  }
];