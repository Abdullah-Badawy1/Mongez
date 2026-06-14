import React, { useState, useEffect } from 'react';
import { Container, Navbar, Nav, Button, Offcanvas, Dropdown } from 'react-bootstrap';
import { Link, useNavigate, useLocation } from 'react-router-dom';
// eslint-disable-next-line no-unused-vars -- used as <motion.*> in JSX (lowercase, missed by no-unused-vars)
import { motion } from 'framer-motion';
import { useTranslation } from 'react-i18next';
import logo from '../../assets/images/a.png';

function Header() {
  const { t, i18n } = useTranslation();
  const [scrolled, setScrolled] = useState(false);
  const [showOffcanvas, setShowOffcanvas] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  // دالة تغيير اللغة
  const changeLanguage = (lng) => {
    i18n.changeLanguage(lng);
    // تغيير اتجاه الصفحة (RTL للعربية، LTR للإنجليزية)
    document.documentElement.dir = lng === 'ar' ? 'rtl' : 'ltr';
    // إغلاق القائمة الجانبية إذا كانت مفتوحة (اختياري)
    setShowOffcanvas(false);
  };

  // Handle scroll effect
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 50) {
        setScrolled(true);
      } else {
        setScrolled(false);
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Nav items (باستخدام الترجمة)
  const navItems = [
    { id: 2, nameKey: 'nav_services', path: '#services', icon: 'bi-tools' },
    { id: 3, nameKey: 'nav_how_it_works', path: '#how-it-works', icon: 'bi-play-circle' },
    { id: 4, nameKey: 'nav_why_choose', path: '#why-choose', icon: 'bi-star' },
    { id: 5, nameKey: 'nav_app', path: '#app', icon: 'bi-phone' },
  ];

  // Handle navigation to sections
  const handleNavClick = (path) => {
    if (path.startsWith('#')) {
      // Scroll to section
      const element = document.querySelector(path);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    } else {
      // Navigate to page
      navigate(path);
    }
    setShowOffcanvas(false);
  };

  // Check if item is active
  const isActive = (path) => {
    if (path === '/') return location.pathname === '/';
    if (path.startsWith('#')) {
      // يمكنك إضافة منطق لتحديد القسم النشط هنا
      return false;
    }
    return location.pathname.startsWith(path);
  };

  // اللغة الحالية
  const currentLanguage = i18n.language || 'en';

  return (
    <>
      <Navbar
        expand="lg"
        fixed="top"
        className={`py-3 transition-all ${scrolled ? 'bg-white shadow-sm' : 'bg-transparent'}`}
        style={{
          transition: 'all 0.3s ease',
          zIndex: 1030
        }}
      >
        <Container>
          {/* Logo */}
          <Navbar.Brand 
            as={Link} 
            to="/" 
            className="d-flex align-items-center fw-bold fs-3"
            style={{ color: '#2c3e50' }}
          >
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 260, damping: 20 }}
              className="d-flex align-items-center"
            >
              <img
                src={logo}
                alt="Mongez"
                style={{ width: '36px', height: '36px', objectFit: 'contain' }}
                className="me-2"
              />
            </motion.div>
            <span className="text-primary">Mongez</span>
          </Navbar.Brand>

          {/* Mobile Menu Button */}
          <Button
            variant="outline-primary"
            className="d-lg-none border-0 rounded-circle"
            onClick={() => setShowOffcanvas(true)}
            style={{ width: '45px', height: '45px' }}
          >
            <i className="bi bi-list"></i>
          </Button>

          {/* Desktop Navigation */}
          <Navbar.Collapse id="navbar-nav" className="justify-content-between">
            {/* Center Navigation */}
            <Nav className="mx-auto">
              {navItems.map((item) => (
                <Nav.Item key={item.id} className="mx-2">
                  <button
                    className={`btn btn-link text-decoration-none px-3 py-2 rounded-pill ${
                      isActive(item.path) 
                        ? 'bg-primary text-white' 
                        : scrolled 
                        ? 'text-dark' 
                        : 'text-white'
                    }`}
                    onClick={() => handleNavClick(item.path)}
                    style={{
                      fontWeight: '500',
                      transition: 'all 0.3s ease'
                    }}
                    onMouseEnter={(e) => {
                      if (!isActive(item.path)) {
                        e.currentTarget.style.transform = 'translateY(-2px)';
                        e.currentTarget.style.backgroundColor = 'rgba(52, 152, 219, 0.1)';
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (!isActive(item.path)) {
                        e.currentTarget.style.transform = 'translateY(0)';
                        e.currentTarget.style.backgroundColor = 'transparent';
                      }
                    }}
                  >
                    <i className={`bi ${item.icon} me-2`}></i>
                    {t(item.nameKey)}  {/* استخدام الترجمة */}
                  </button>
                </Nav.Item>
              ))}
            </Nav>

            {/* Right Side - Auth & Emergency & Language */}
            <div className="d-flex align-items-center gap-3">
              {/* Emergency Button */}
              <Button
                variant="danger"
                className="rounded-pill px-4 py-2 d-none d-lg-flex align-items-center"
                onClick={() => handleNavClick('#emergency')}
                style={{
                  background: 'linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%)',
                  border: 'none',
                  fontWeight: '600'
                }}
              >
                <i className="bi bi-telephone-outbound-fill me-2"></i>
                {t('emergency_button', { number: '19019' })}  {/* استخدام الترجمة مع متغير */}
              </Button>

              {/* Language Switcher */}
              <Dropdown align="end">
                <Dropdown.Toggle 
                  variant={scrolled ? 'outline-primary' : 'outline-light'} 
                  id="dropdown-language"
                  className="rounded-pill px-3 d-flex align-items-center"
                  style={{ borderWidth: '2px' }}
                >
                  <i className="bi bi-globe2 me-2"></i>
                  {currentLanguage === 'ar' ? 'العربية' : 'English'}
                </Dropdown.Toggle>

                <Dropdown.Menu>
                  <Dropdown.Item 
                    onClick={() => changeLanguage('en')}
                    active={currentLanguage === 'en'}
                  >
                    English
                  </Dropdown.Item>
                  <Dropdown.Item 
                    onClick={() => changeLanguage('ar')}
                    active={currentLanguage === 'ar'}
                  >
                    العربية
                  </Dropdown.Item>
                </Dropdown.Menu>
              </Dropdown>

              {/* Auth Buttons (معلقة حالياً) */}
              {/* {authButtons.map((btn) => (
                <Button
                  key={btn.id}
                  as={Link}
                  to={btn.path}
                  variant={btn.variant}
                  className="rounded-pill px-4 py-2"
                  style={{
                    fontWeight: '500',
                    minWidth: '100px'
                  }}
                >
                  {t(btn.nameKey)}
                </Button>
              ))} */}
            </div>
          </Navbar.Collapse>
        </Container>
      </Navbar>

      {/* Spacer for fixed navbar */}
      <div style={{ height: '80px' }}></div>

      {/* Mobile Offcanvas Menu */}
      <Offcanvas
        show={showOffcanvas}
        onHide={() => setShowOffcanvas(false)}
        placement="end"
        style={{ maxWidth: '300px' }}
      >
        <Offcanvas.Header closeButton className="border-bottom">
          <Offcanvas.Title className="fw-bold fs-4">
            <span className="text-primary">Mongez</span>
          </Offcanvas.Title>
        </Offcanvas.Header>
        <Offcanvas.Body className="p-0">
          {/* User Info (if logged in) */}
          <div className="p-4 bg-light border-bottom">
            <div className="d-flex align-items-center">
              <div className="bg-primary rounded-circle p-3 me-3">
                <i className="bi bi-person-fill text-white fs-4"></i>
              </div>
              <div>
                <h6 className="mb-1 fw-bold">{t('offcanvas_welcome')}</h6>
                <small className="text-muted">{t('offcanvas_sign_in_prompt')}</small>
              </div>
            </div>
          </div>

          {/* Mobile Navigation */}
          <Nav className="flex-column p-3">
            {navItems.map((item) => (
              <button
                key={item.id}
                className={`btn btn-link text-decoration-none text-start w-100 py-3 px-3 rounded ${
                  isActive(item.path) ? 'bg-primary text-white' : 'text-dark'
                }`}
                onClick={() => handleNavClick(item.path)}
              >
                <i className={`bi ${item.icon} me-3`}></i>
                {t(item.nameKey)}
              </button>
            ))}
          </Nav>

          {/* Language Switcher in Mobile */}
          <div className="p-3 border-top">
            <h6 className="fw-bold mb-3">{t('offcanvas_language') || 'Language'}</h6>
            <div className="d-flex gap-2">
              <Button 
                variant={currentLanguage === 'en' ? 'primary' : 'outline-primary'}
                className="flex-fill rounded-pill"
                onClick={() => changeLanguage('en')}
              >
                English
              </Button>
              <Button 
                variant={currentLanguage === 'ar' ? 'primary' : 'outline-primary'}
                className="flex-fill rounded-pill"
                onClick={() => changeLanguage('ar')}
              >
                العربية
              </Button>
            </div>
          </div>

          {/* Emergency Button Mobile */}
          <div className="p-3 border-top">
            <Button
              variant="danger"
              className="w-100 rounded-pill py-3 mb-3"
              onClick={() => {
                handleNavClick('#emergency');
                setShowOffcanvas(false);
              }}
            >
              <i className="bi bi-telephone-outbound-fill me-2"></i>
              {t('emergency_button', { number: '19019' })}
            </Button>

            {/* Auth Buttons Mobile */}
            {/* <div className="d-grid gap-2">
              {authButtons.map((btn) => (
                <Button
                  key={btn.id}
                  as={Link}
                  to={btn.path}
                  variant={btn.variant}
                  className="rounded-pill py-2"
                  onClick={() => setShowOffcanvas(false)}
                >
                  {t(btn.nameKey)}
                </Button>
              ))}
            </div> */}
          </div>

          {/* Contact Info */}
          <div className="p-3 border-top bg-light">
            <h6 className="fw-bold mb-3">{t('offcanvas_contact_us')}</h6>
            <div className="mb-2">
              <i className="bi bi-telephone text-primary me-2"></i>
              <span>+1 234 567 890</span>
            </div>
            <div className="mb-2">
              <i className="bi bi-envelope text-primary me-2"></i>
              <span>support@mongez.com</span>
            </div>
            <div>
              <i className="bi bi-clock text-primary me-2"></i>
              <span>{t('offcanvas_24_7')}</span>
            </div>
          </div>

          {/* Social Media */}
          <div className="p-3 border-top">
            <h6 className="fw-bold mb-3">{t('offcanvas_follow_us')}</h6>
            <div className="d-flex justify-content-center gap-3">
              {['facebook', 'twitter', 'instagram', 'linkedin'].map((platform) => (
                <a
                  key={platform}
                  href="#"
                  className="text-primary text-decoration-none"
                  style={{ fontSize: '1.5rem' }}
                >
                  <i className={`bi bi-${platform}`}></i>
                </a>
              ))}
            </div>
          </div>
        </Offcanvas.Body>
      </Offcanvas>

      {/* Floating Emergency Button for Mobile */}
      <div className="d-lg-none fixed-bottom p-3" style={{ zIndex: 1020 }}>
        <Button
          variant="danger"
          className="w-100 rounded-pill py-3 shadow-lg"
          onClick={() => handleNavClick('#emergency')}
          style={{
            background: 'linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%)',
            border: 'none',
            fontWeight: '600'
          }}
        >
          <i className="bi bi-telephone-outbound-fill me-2"></i>
          {t('emergency_button', { number: '19019' })}
        </Button>
      </div>
    </>
  );
}

export default Header;