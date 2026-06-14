/**
 * Utility functions and constants for the Mongez application
 */

// Services data
export const services = [
  {
    id: 1,
    name: 'Electricity',
    icon: 'bi-lightning-charge-fill',
    description: 'Professional electrical repairs and installations',
    color: '#f39c12'
  },
  {
    id: 2,
    name: 'Plumbing',
    icon: 'bi-droplet-fill',
    description: 'Fix leaks, install pipes, and plumbing solutions',
    color: '#3498db'
  },
  {
    id: 3,
    name: 'Gas',
    icon: 'bi-fire',
    description: 'Safe gas line repairs and maintenance',
    color: '#e74c3c'
  },
  {
    id: 4,
    name: 'Air Conditioning',
    icon: 'bi-snow2',
    description: 'AC installation, repair, and maintenance',
    color: '#1abc9c'
  },
  {
    id: 5,
    name: 'Home Appliances',
    icon: 'bi-house-gear-fill',
    description: 'Repair of all home appliances',
    color: '#9b59b6'
  },
  {
    id: 6,
    name: 'Carpentry',
    icon: 'bi-hammer',
    description: 'Furniture repair and woodwork',
    color: '#d35400'
  }
];

// Steps for How It Works
export const steps = [
  { 
    id: 1, 
    title: 'Choose Service', 
    description: 'Select the service you need from our wide range',
    icon: 'bi-list-check'
  },
  { 
    id: 2, 
    title: 'Select Technician', 
    description: 'Pick a nearby verified technician with ratings & reviews',
    icon: 'bi-person-check-fill'
  },
  { 
    id: 3, 
    title: 'Get Fixed', 
    description: 'Your problem gets solved quickly and professionally',
    icon: 'bi-check-circle-fill'
  }
];

// Features for Why Choose section
export const features = [
  {
    id: 1,
    title: 'Verified Technicians',
    description: 'All technicians pass rigorous background checks and verification',
    icon: 'bi-shield-check',
    stats: '100% Verified'
  },
  {
    id: 2,
    title: 'Fast Response',
    description: 'Emergency services? We respond in less than 1 hour',
    icon: 'bi-lightning-charge',
    stats: '< 60 Min'
  },
  {
    id: 3,
    title: 'Ratings & Reviews',
    description: 'Real reviews from previous customers ensure quality',
    icon: 'bi-star-fill',
    stats: '4.9/5 Rating'
  },
  {
    id: 4,
    title: 'Safe & Reliable',
    description: 'Insured services with satisfaction guaranteed',
    icon: 'bi-lock-fill',
    stats: '100% Safe'
  }
];

// Contact information
export const contactInfo = {
  phone: '+1 234 567 890',
  emergencyPhone: '19019',
  email: 'info@mongez.com',
  address: '123 Main Street, City, Country',
  workingHours: '24/7 Available'
};

// Social media links
export const socialLinks = [
  { platform: 'facebook', url: '#', icon: 'bi-facebook' },
  { platform: 'twitter', url: '#', icon: 'bi-twitter' },
  { platform: 'instagram', url: '#', icon: 'bi-instagram' },
  { platform: 'linkedin', url: '#', icon: 'bi-linkedin' },
  { platform: 'youtube', url: '#', icon: 'bi-youtube' }
];

// App download links
export const appLinks = {
  appStore: '#',
  googlePlay: '#'
};

// Format phone number
export const formatPhoneNumber = (phoneNumber) => {
  return phoneNumber.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
};

// Validate email
export const validateEmail = (email) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

// Get service by ID
export const getServiceById = (id) => {
  return services.find(service => service.id === id);
};

// Calculate average rating
export const calculateAverageRating = (ratings) => {
  if (!ratings || ratings.length === 0) return 0;
  const sum = ratings.reduce((total, rating) => total + rating, 0);
  return (sum / ratings.length).toFixed(1);
};

// Format currency
export const formatCurrency = (amount, currency = 'USD') => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency
  }).format(amount);
};

// Truncate text
export const truncateText = (text, maxLength = 100) => {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
};