import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Collapse, Space, Drawer } from 'antd';
import {
  Sparkles,
  Clock,
  MapPin,
  Star,
  Menu,
  X,
  ChevronDown,
  Moon,
  Sun,
  ShieldCheck,
  IndianRupee,
  Activity,
  Smile
} from 'lucide-react';
import useAuthStore from '../store/useAuthStore.ts';

const { Panel } = Collapse;

export default function LandingPage() {
  const navigate = useNavigate();
  const { isAuthenticated, user, isDarkMode, toggleTheme, logout } = useAuthStore();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const testimonials = [
    {
      name: 'Rohan Sharma',
      location: 'Gurugram',
      comment: 'Super fast express service. My suit came back looking brand new. Definitely recommendation!',
      rating: 5,
      role: 'Software Engineer'
    },
    {
      name: 'Ananya Iyer',
      location: 'Bengaluru',
      comment: 'The convenience of doorstep pickup is a lifesaver. Regular washing is clean and folded perfectly.',
      rating: 5,
      role: 'Product Manager'
    },
    {
      name: 'Vikram Malhotra',
      location: 'Mumbai',
      comment: 'Same day laundry delivery is a game changer in India. Affordable rates and excellent support.',
      rating: 5,
      role: 'Consultant'
    }
  ];

  const faqs = [
    {
      q: 'How does the Doorstep Pickup & Delivery work?',
      a: 'Simply select your services, add clothing items to your cart, pick a convenient pickup date & time slot, and check out. Our agent will arrive at your address with custom laundry bags, tag your items, and deliver them back fresh within 24-72 hours.'
    },
    {
      q: 'What is the processing time for Express and Standard deliveries?',
      a: 'Standard delivery takes 3 days. Express delivery takes 24 hours (₹50 extra charges apply). Same-day delivery is available if booked before 11 AM (₹100 extra charges).'
    },
    {
      q: 'Is there a minimum order value for Free Delivery?',
      a: 'Yes, orders with a cart subtotal above ₹500 get free delivery! For orders below ₹500, a standard delivery fee of ₹30 applies.'
    },
    {
      q: 'How do you handle delicate clothes like sarees and suits?',
      a: 'We use our premium Dry Cleaning service for all delicate fabrics, silks, woolens, and heavy designer wears. Items are individually inspected, cleaned using eco-friendly solvents, and hand-pressed.'
    }
  ];

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 transition-colors duration-300" style={{ backgroundColor: 'var(--bg-primary)', color: 'var(--text-main)' }}>
      {/* Sticky Header Nav */}
      <header className="sticky top-0 z-50 w-full glass-panel" style={{ borderRadius: '0px', borderBottom: '1px solid var(--border-color)' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-2 cursor-pointer" onClick={() => navigate('/')}>
            <div className="h-10 w-10 rounded-xl gradient-primary-bg flex items-center justify-center text-white font-extrabold shadow-md">
              L
            </div>
            <span className="font-extrabold text-xl tracking-tight bg-gradient-to-r from-blue-600 to-green-500 bg-clip-text text-transparent" style={{ color: 'var(--primary-color)' }}>
              LaundryIndia
            </span>
          </div>

          {/* Desktop Navigation Links */}
          <nav className="hidden md:flex items-center space-x-8">
            <a href="#services" className="font-medium text-sm hover:text-blue-500 transition-colors" style={{ color: 'var(--text-muted)' }}>Services</a>
            <a href="#why-us" className="font-medium text-sm hover:text-blue-500 transition-colors" style={{ color: 'var(--text-muted)' }}>Why Us</a>
            <a href="#reviews" className="font-medium text-sm hover:text-blue-500 transition-colors" style={{ color: 'var(--text-muted)' }}>Reviews</a>
            <a href="#faqs" className="font-medium text-sm hover:text-blue-500 transition-colors" style={{ color: 'var(--text-muted)' }}>FAQs</a>
          </nav>

          <div className="hidden md:flex items-center space-x-4">
            <Button
              type="text"
              icon={isDarkMode ? <Sun size={18} /> : <Moon size={18} />}
              onClick={toggleTheme}
              className="flex items-center justify-center"
            />
            {isAuthenticated ? (
              <div className="flex items-center space-x-3">
                <Button type="primary" onClick={() => navigate(user?.role === 'admin' ? '/admin' : '/dashboard')}>
                  Dashboard
                </Button>
                <Button type="default" onClick={logout} icon={<X size={14} />}>
                  Logout
                </Button>
              </div>
            ) : (
              <Button type="primary" className="gradient-primary-bg border-none" onClick={() => navigate('/login')}>
                Book / Login
              </Button>
            )}
          </div>

          {/* Mobile Menu Icon */}
          <div className="flex md:hidden items-center space-x-2">
            <Button
              type="text"
              icon={isDarkMode ? <Sun size={18} /> : <Moon size={18} />}
              onClick={toggleTheme}
            />
            <Button
              type="text"
              icon={mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            />
          </div>
        </div>
      </header>

      {/* Mobile Drawer Navigation */}
      <Drawer
        title="LaundryIndia Navigation"
        placement="right"
        onClose={() => setMobileMenuOpen(false)}
        open={mobileMenuOpen}
        styles={{ body: { backgroundColor: 'var(--bg-primary)', color: 'var(--text-main)' } }}
      >
        <div className="flex flex-col space-y-6">
          <a href="#services" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Services</a>
          <a href="#why-us" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Why Us</a>
          <a href="#reviews" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Reviews</a>
          <a href="#faqs" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">FAQs</a>
          <div className="border-t pt-4 border-slate-200">
            {isAuthenticated ? (
              <div className="flex flex-col space-y-3">
                <Button type="primary" block onClick={() => { setMobileMenuOpen(false); navigate(user?.role === 'admin' ? '/admin' : '/dashboard'); }}>
                  Dashboard
                </Button>
                <Button block onClick={() => { setMobileMenuOpen(false); logout(); }}>
                  Logout
                </Button>
              </div>
            ) : (
              <Button type="primary" block onClick={() => { setMobileMenuOpen(false); navigate('/login'); }}>
                Book / Login
              </Button>
            )}
          </div>
        </div>
      </Drawer>

      {/* Hero Section */}
      <section className="relative overflow-hidden pt-12 pb-24 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="space-y-8 animate-fade-in">
            <div className="inline-flex items-center space-x-2 bg-blue-100 text-blue-800 px-3 py-1.5 rounded-full text-xs font-semibold" style={{ backgroundColor: 'rgba(30,136,229,0.15)', color: 'var(--primary-color)' }}>
              <Sparkles size={14} />
              <span>Premium Doorstep Laundry India</span>
            </div>
            
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight leading-none" style={{ fontFamily: 'Outfit' }}>
              Fresh Clothes,<br />
              <span className="bg-gradient-to-r from-blue-600 to-green-500 bg-clip-text text-transparent">Doorstep Pickup</span><br />
              In Just 24 Hours.
            </h1>
            
            <p className="text-lg sm:text-xl" style={{ color: 'var(--text-muted)' }}>
              Professional washing, dry cleaning, and steam pressing services across major Indian cities. Affordable rates, glassmorphic order tracking, and online UPI checkouts.
            </p>

            <div className="flex flex-col sm:flex-row space-y-3 sm:space-y-0 sm:space-x-4">
              <Button
                type="primary"
                size="large"
                className="gradient-primary-bg h-14 text-base font-bold shadow-lg"
                onClick={() => navigate('/login')}
              >
                Schedule Free Pickup
              </Button>
              <Button
                size="large"
                className="h-14 text-base font-semibold"
                onClick={() => {
                  const el = document.getElementById('services');
                  el?.scrollIntoView({ behavior: 'smooth' });
                }}
              >
                View Rate List
              </Button>
            </div>

            {/* Quick trust metrics */}
            <div className="grid grid-cols-3 gap-4 pt-6 border-t" style={{ borderColor: 'var(--border-color)' }}>
              <div>
                <span className="block text-2xl font-bold" style={{ color: 'var(--primary-color)' }}>15,000+</span>
                <span className="text-xs" style={{ color: 'var(--text-muted)' }}>Orders Completed</span>
              </div>
              <div>
                <span className="block text-2xl font-bold" style={{ color: 'var(--primary-color)' }}>4.9 ★</span>
                <span className="text-xs" style={{ color: 'var(--text-muted)' }}>Google Rating</span>
              </div>
              <div>
                <span className="block text-2xl font-bold" style={{ color: 'var(--primary-color)' }}>24 Hours</span>
                <span className="text-xs" style={{ color: 'var(--text-muted)' }}>Express Delivery</span>
              </div>
            </div>
          </div>

          {/* Hero Image / Design */}
          <div className="relative flex justify-center lg:justify-end">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-72 h-72 gradient-premium-card rounded-full blur-3xl opacity-60 animate-spin-slow"></div>
            <img
              src="https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=600&auto=format&fit=crop&q=80"
              alt="Premium Laundry Service"
              className="relative rounded-3xl shadow-2xl w-full max-w-md object-cover aspect-square border"
              style={{ borderColor: 'var(--border-color)' }}
            />
          </div>
        </div>
      </section>

      {/* Services Cards Section */}
      <section id="services" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-t" style={{ borderColor: 'var(--border-color)' }}>
        <div className="text-center space-y-4 mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold" style={{ fontFamily: 'Outfit' }}>Our Laundry Services</h2>
          <p className="max-w-2xl mx-auto text-base" style={{ color: 'var(--text-muted)' }}>
            Choose from our premium cleaning options. Book custom orders matching your lifestyle.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Card 1: Washing */}
          <div className="glass-card overflow-hidden flex flex-col justify-between">
            <div>
              <img
                src="https://images.unsplash.com/photo-1545173168-9f19472ef7f4?w=500&auto=format&fit=crop&q=60"
                alt="Washing & Fold"
                className="h-48 w-full object-cover"
              />
              <div className="p-6 space-y-3">
                <h3 className="text-xl font-bold">Washing & Fold</h3>
                <p className="text-sm" style={{ color: 'var(--text-muted)' }}>
                  Everyday wardrobe wash. Thorough washing using premium detergents, dried cleanly and machine folded.
                </p>
                <div className="text-sm font-semibold flex items-center space-x-1" style={{ color: 'var(--primary-color)' }}>
                  <span>Starting at ₹20 / clothing item</span>
                </div>
              </div>
            </div>
            <div className="p-6 pt-0">
              <Button type="primary" block className="gradient-primary-bg border-none" onClick={() => navigate('/login')}>
                Select Washing
              </Button>
            </div>
          </div>

          {/* Card 2: Dry Cleaning */}
          <div className="glass-card overflow-hidden flex flex-col justify-between">
            <div>
              <img
                src="https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=500&auto=format&fit=crop&q=60"
                alt="Dry Cleaning"
                className="h-48 w-full object-cover"
              />
              <div className="p-6 space-y-3">
                <h3 className="text-xl font-bold">Dry Cleaning</h3>
                <p className="text-sm" style={{ color: 'var(--text-muted)' }}>
                  Specialist solvent care for designer dresses, sarees, suits, curtains, blazers, and delicate fabrics.
                </p>
                <div className="text-sm font-semibold flex items-center space-x-1" style={{ color: 'var(--primary-color)' }}>
                  <span>Starting at ₹60 / clothing item</span>
                </div>
              </div>
            </div>
            <div className="p-6 pt-0">
              <Button type="primary" block className="gradient-primary-bg border-none" onClick={() => navigate('/login')}>
                Select Dry Cleaning
              </Button>
            </div>
          </div>

          {/* Card 3: Steam Pressing */}
          <div className="glass-card overflow-hidden flex flex-col justify-between">
            <div>
              <img
                src="https://images.unsplash.com/photo-1525971977907-22d555db64c0?w=500&auto=format&fit=crop&q=60"
                alt="Steam Pressing"
                className="h-48 w-full object-cover"
              />
              <div className="p-6 space-y-3">
                <h3 className="text-xl font-bold">Steam Pressing</h3>
                <p className="text-sm" style={{ color: 'var(--text-muted)' }}>
                  Crisp crease control. Creaseless ironing using high-pressure steam generators. Delivered on hanger hooks.
                </p>
                <div className="text-sm font-semibold flex items-center space-x-1" style={{ color: 'var(--primary-color)' }}>
                  <span>Starting at ₹10 / clothing item</span>
                </div>
              </div>
            </div>
            <div className="p-6 pt-0">
              <Button type="primary" block className="gradient-primary-bg border-none" onClick={() => navigate('/login')}>
                Select Pressing
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Why Choose Us Section */}
      <section id="why-us" className="py-20 px-4 sm:px-6 lg:px-8 bg-slate-100" style={{ backgroundColor: 'var(--bg-glass)' }}>
        <div className="max-w-7xl mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold" style={{ fontFamily: 'Outfit' }}>Why Choose Us</h2>
            <p className="max-w-2xl mx-auto text-base" style={{ color: 'var(--text-muted)' }}>
              We provide the highest quality laundry service in India, backed by modern technology.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="glass-panel p-6 text-center space-y-4">
              <div className="mx-auto w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600" style={{ backgroundColor: 'rgba(30,136,229,0.15)', color: 'var(--primary-color)' }}>
                <Clock size={24} />
              </div>
              <h4 className="font-bold text-lg">Fast 24h Turnaround</h4>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Select Express Delivery to get clean garments returned in just 24 hours.</p>
            </div>

            <div className="glass-panel p-6 text-center space-y-4">
              <div className="mx-auto w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-green-600" style={{ backgroundColor: 'rgba(0,200,83,0.15)', color: 'var(--secondary-color)' }}>
                <MapPin size={24} />
              </div>
              <h4 className="font-bold text-lg">Free Doorstep Pickup</h4>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>No need to step outside. We pick up and drop at your Home, Office, or Hotel.</p>
            </div>

            <div className="glass-panel p-6 text-center space-y-4">
              <div className="mx-auto w-12 h-12 rounded-full bg-yellow-100 flex items-center justify-center text-yellow-600" style={{ backgroundColor: 'rgba(255,193,7,0.15)', color: 'var(--accent-color)' }}>
                <ShieldCheck size={24} />
              </div>
              <h4 className="font-bold text-lg">Premium Cleaning</h4>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Washed in soft water with fabric conditioners. Safe on prints, embroideries and lace.</p>
            </div>

            <div className="glass-panel p-6 text-center space-y-4">
              <div className="mx-auto w-12 h-12 rounded-full bg-red-100 flex items-center justify-center text-red-600" style={{ backgroundColor: 'rgba(239,68,68,0.15)', color: '#ef4444' }}>
                <IndianRupee size={24} />
              </div>
              <h4 className="font-bold text-lg">Affordable Pricing</h4>
              <p className="text-sm" style={{ color: 'var(--text-muted)' }}>Item rates starting at just ₹10. Transparent billing with no hidden fees.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Customer Reviews Section */}
      <section id="reviews" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center space-y-4 mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold" style={{ fontFamily: 'Outfit' }}>Loved by Our Customers</h2>
          <p className="max-w-2xl mx-auto text-base" style={{ color: 'var(--text-muted)' }}>
            Read real feedback from our regular customers in metro areas.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {testimonials.map((t, idx) => (
            <div key={idx} className="glass-panel p-8 space-y-4 flex flex-col justify-between">
              <p className="italic text-base" style={{ color: 'var(--text-muted)' }}>"{t.comment}"</p>
              <div className="flex items-center space-x-3">
                <div className="h-10 w-10 rounded-full bg-slate-300 flex items-center justify-center font-bold text-slate-800">
                  {t.name[0]}
                </div>
                <div>
                  <h5 className="font-bold text-sm">{t.name}</h5>
                  <span className="text-xs block" style={{ color: 'var(--text-muted)' }}>{t.role}, {t.location}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* FAQ Section */}
      <section id="faqs" className="py-20 px-4 sm:px-6 lg:px-8 bg-slate-50" style={{ backgroundColor: 'var(--bg-primary)' }}>
        <div className="max-w-4xl mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold" style={{ fontFamily: 'Outfit' }}>Frequently Asked Questions</h2>
            <p className="text-base" style={{ color: 'var(--text-muted)' }}>Have a query? Find instant replies to our common workflows.</p>
          </div>

          <Collapse accordion expandIconPosition="end" className="glass-panel bg-transparent border-none">
            {faqs.map((faq, idx) => (
              <Panel header={<span className="font-semibold text-base">{faq.q}</span>} key={idx} className="border-b" style={{ borderColor: 'var(--border-color)' }}>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--text-muted)' }}>{faq.a}</p>
              </Panel>
            ))}
          </Collapse>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-400 py-12 px-4 sm:px-6 lg:px-8 border-t border-slate-800" style={{ backgroundColor: 'var(--bg-secondary)', borderTop: '1px solid var(--border-color)' }}>
        <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="space-y-4">
            <div className="flex items-center space-x-2">
              <div className="h-8 w-8 rounded-lg gradient-primary-bg flex items-center justify-center text-white font-extrabold">
                L
              </div>
              <span className="font-bold text-lg text-white">LaundryIndia</span>
            </div>
            <p className="text-xs">Premium doorstep dry cleaning and wash laundry services in India.</p>
            <p className="text-xs">© 2026 LaundryIndia Private Limited. All rights reserved.</p>
          </div>
          <div>
            <h5 className="text-white font-semibold text-sm mb-4">Our Services</h5>
            <ul className="space-y-2 text-xs">
              <li>Washing & Fold</li>
              <li>Premium Dry Cleaning</li>
              <li>Express Steam Pressing</li>
              <li>Pickup & Drop Logistics</li>
            </ul>
          </div>
          <div>
            <h5 className="text-white font-semibold text-sm mb-4">Contact Info</h5>
            <p className="text-xs mb-2">Support Helpline: +91 99999 99999</p>
            <p className="text-xs">Email: care@laundryindia.in</p>
            <p className="text-xs mt-2">Noida Sector 62, Uttar Pradesh, India</p>
          </div>
          <div>
            <h5 className="text-white font-semibold text-sm mb-4">Install App</h5>
            <p className="text-xs mb-4">You can install this laundry platform directly as a PWA app on Android or iOS homescreens.</p>
            <Button type="primary" size="small" onClick={() => navigate('/login')}>
              Launch Booking Portal
            </Button>
          </div>
        </div>
      </footer>
    </div>
  );
}
