import React from 'react';
import { Container, Row, Col, Card } from 'react-bootstrap';
import { useTranslation } from 'react-i18next';

function Services() {
  const { t } = useTranslation();

  const services = [
    { id: 1, nameKey: 'service_electricity', icon: 'bi-lightning-charge-fill', color: '#f39c12' },
    { id: 2, nameKey: 'service_plumbing', icon: 'bi-droplet-fill', color: '#3498db' },
    { id: 3, nameKey: 'service_gas', icon: 'bi-fire', color: '#e74c3c' },
    { id: 4, nameKey: 'service_air_conditioning', icon: 'bi-snow2', color: '#1abc9c' },
    { id: 5, nameKey: 'service_home_appliances', icon: 'bi-house-gear-fill', color: '#9b59b6' },
    { id: 6, nameKey: 'service_carpentry', icon: 'bi-hammer', color: '#d35400' },
  ];

  return (
    <section className="services-section section-padding" id="services">
      <Container>
        <div className="text-center mb-5 fade-in-up">
          <h2 className="display-5 fw-bold mb-3" style={{ color: '#2c3e50' }}>
            {t('services_title')}
          </h2>
          <p className="lead text-muted mx-auto" style={{ maxWidth: '700px' }}>
            {t('services_subtitle')}
          </p>
        </div>

        <Row className="g-4">
          {services.map((service) => (
            <Col key={service.id} md={4} lg={2} className="mb-4">
              <Card 
                className="service-card border-0 shadow-sm h-100 text-center p-4 rounded-4"
                style={{ 
                  transition: 'all 0.3s ease',
                  cursor: 'pointer'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateY(-10px)';
                  e.currentTarget.style.boxShadow = '0 20px 40px rgba(52, 152, 219, 0.15)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = '0 5px 15px rgba(0, 0, 0, 0.08)';
                }}
              >
                <div className="mb-3">
                  <div 
                    className="rounded-circle p-3 mx-auto"
                    style={{ 
                      backgroundColor: `${service.color}15`,
                      width: '80px',
                      height: '80px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}
                  >
                    <i 
                      className={`bi ${service.icon} fs-2`}
                      style={{ color: service.color }}
                    ></i>
                  </div>
                </div>
                <Card.Body className="p-0">
                  <Card.Title className="fw-bold mb-2" style={{ color: '#2c3e50' }}>
                    {t(service.nameKey)}
                  </Card.Title>
                  <Card.Text className="text-muted small">
                    {t('service_card_description')}
                  </Card.Text>
                  <button 
                    className="btn btn-sm btn-outline-primary mt-2 rounded-pill px-3"
                    style={{ fontSize: '0.8rem' }}
                  >
                    {t('service_book_button')}
                  </button>
                </Card.Body>
              </Card>
            </Col>
          ))}
        </Row>
      </Container>
    </section>
  );
}

export default Services;