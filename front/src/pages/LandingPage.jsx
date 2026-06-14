import React from 'react';
import { Container } from 'react-bootstrap';
import Header from '../components/layout/Header';
import Hero from '../components/landing/Hero';
import Services from '../components/landing/Services';
import HowItWorks from '../components/landing/HowItWorks';
import WhyChoose from '../components/landing/WhyChoose';
import AppPromotion from '../components/landing/AppPromotion';
import EmergencySection from '../components/landing/EmergencySection';
import Footer from '../components/layout/Footer';
import './Landing.css';

function LandingPage() {
  return (
    <div className="landing-page">
      <Header />
      <Hero />
      <Services />
      <HowItWorks />
      <WhyChoose />
      <AppPromotion />
      <EmergencySection />
      <Footer />
    </div>
  );
}

export default LandingPage;