import React from 'react';
import { Container, Row, Col, Form, Button } from 'react-bootstrap';
import { useTranslation } from 'react-i18next';

function Footer() {
  const { t } = useTranslation();
  const currentYear = new Date().getFullYear();

  return (
    <footer className="footer-section" style={{ backgroundColor: '#2c3e50', color: 'white' }}>
      <Container className="py-5">
        <Row className="g-4">
          <Col lg={4} className="mb-4 mb-lg-0">
            <div className="mb-4">
              <h3 className="fw-bold mb-3">
                <span className="text-primary">Mongez</span>
              </h3>
              <p className="opacity-75">
                {t('footer_description')}
              </p>
            </div>
            
            <div className="social-icons mb-4">
              <h6 className="mb-3">{t('footer_follow_us')}</h6>
              <div className="d-flex gap-3">
                {['facebook', 'twitter', 'instagram', 'linkedin', 'youtube'].map((platform) => (
                  <a 
                    key={platform}
                    href="#" 
                    className="text-white text-decoration-none bg-primary bg-opacity-10 rounded-circle p-2"
                    style={{ 
                      width: '40px',
                      height: '40px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      transition: 'all 0.3s ease'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.backgroundColor = '#3498db';
                      e.currentTarget.style.transform = 'translateY(-3px)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.backgroundColor = 'rgba(52, 152, 219, 0.1)';
                      e.currentTarget.style.transform = 'translateY(0)';
                    }}
                  >
                    <i className={`bi bi-${platform}`}></i>
                  </a>
                ))}
              </div>
            </div>
            
            <div className="app-download">
              <h6 className="mb-3">{t('footer_download_app')}</h6>
              <div className="d-flex gap-2">
                <Button 
                  variant="outline-light" 
                  size="sm"
                  className="rounded-pill"
                >
                  <i className="bi bi-apple me-1"></i>
                  {t('footer_app_store')}
                </Button>
                <Button 
                  variant="outline-light" 
                  size="sm"
                  className="rounded-pill"
                >
                  <i className="bi bi-google-play me-1"></i>
                  {t('footer_google_play')}
                </Button>
              </div>
            </div>
          </Col>
          
          <Col lg={2} md={4} sm={6} className="mb-4">
            <h6 className="fw-bold mb-3">{t('footer_services_title')}</h6>
            <ul className="list-unstyled">
              {[
                { key: 'footer_service_electricity', default: 'Electricity' },
                { key: 'footer_service_plumbing', default: 'Plumbing' },
                { key: 'footer_service_gas', default: 'Gas' },
                { key: 'footer_service_ac', default: 'AC Repair' },
                { key: 'footer_service_appliances', default: 'Appliances' },
                { key: 'footer_service_carpentry', default: 'Carpentry' }
              ].map((service) => (
                <li key={service.key} className="mb-2">
                  <a 
                    href="#" 
                    className="text-white-50 text-decoration-none hover-text-primary"
                    style={{ transition: 'color 0.3s ease' }}
                    onMouseEnter={(e) => e.currentTarget.style.color = '#3498db'}
                    onMouseLeave={(e) => e.currentTarget.style.color = 'rgba(255, 255, 255, 0.5)'}
                  >
                    {t(service.key)}
                  </a>
                </li>
              ))}
            </ul>
          </Col>
          
          <Col lg={2} md={4} sm={6} className="mb-4">
            <h6 className="fw-bold mb-3">{t('footer_company_title')}</h6>
            <ul className="list-unstyled">
              {[
                { key: 'footer_company_about', default: 'About Us' },
                { key: 'footer_company_careers', default: 'Careers' },
                { key: 'footer_company_press', default: 'Press' },
                { key: 'footer_company_blog', default: 'Blog' },
                { key: 'footer_company_partners', default: 'Partners' },
                { key: 'footer_company_contact', default: 'Contact' }
              ].map((item) => (
                <li key={item.key} className="mb-2">
                  <a 
                    href="#" 
                    className="text-white-50 text-decoration-none hover-text-primary"
                    style={{ transition: 'color 0.3s ease' }}
                    onMouseEnter={(e) => e.currentTarget.style.color = '#3498db'}
                    onMouseLeave={(e) => e.currentTarget.style.color = 'rgba(255, 255, 255, 0.5)'}
                  >
                    {t(item.key)}
                  </a>
                </li>
              ))}
            </ul>
          </Col>
          
          <Col lg={4} md={4} className="mb-4">
            <h6 className="fw-bold mb-3">{t('footer_contact_title')}</h6>
            <ul className="list-unstyled">
              <li className="mb-3">
                <i className="bi bi-geo-alt-fill me-2 text-primary"></i>
                <span className="text-white-50">
                  {t('footer_address')}
                </span>
              </li>
              <li className="mb-3">
                <i className="bi bi-telephone-fill me-2 text-primary"></i>
                <span className="text-white-50">
                  {t('footer_phone')}
                </span>
              </li>
              <li className="mb-3">
                <i className="bi bi-envelope-fill me-2 text-primary"></i>
                <span className="text-white-50">
                  {t('footer_email')}
                </span>
              </li>
              <li className="mb-3">
                <i className="bi bi-clock-fill me-2 text-primary"></i>
                <span className="text-white-50">
                  {t('footer_hours')}
                </span>
              </li>
            </ul>
            
            <div className="newsletter mt-4">
              <h6 className="fw-bold mb-3">{t('footer_newsletter_title')}</h6>
              <Form className="d-flex">
                <Form.Control 
                  type="email" 
                  placeholder={t('footer_newsletter_placeholder')}
                  className="rounded-pill me-2"
                  style={{ border: 'none' }}
                />
                <Button 
                  variant="primary" 
                  className="rounded-pill px-3"
                >
                  <i className="bi bi-send"></i>
                </Button>
              </Form>
            </div>
          </Col>
        </Row>
        
        <hr className="my-4 opacity-25" />
        
        <Row className="align-items-center">
          <Col md={6} className="mb-3 mb-md-0">
            <p className="mb-0 text-white-50">
              &copy; {currentYear} Mongez. {t('footer_rights')}
            </p>
          </Col>
          <Col md={6} className="text-md-end">
            <div className="d-flex justify-content-md-end gap-4">
              <a href="#" className="text-white-50 text-decoration-none">{t('footer_privacy')}</a>
              <a href="#" className="text-white-50 text-decoration-none">{t('footer_terms')}</a>
              <a href="#" className="text-white-50 text-decoration-none">{t('footer_cookie')}</a>
            </div>
          </Col>
        </Row>
      </Container>
    </footer>
  );
}

export default Footer;