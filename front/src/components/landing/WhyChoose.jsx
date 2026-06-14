import React from 'react';
import { Container, Row, Col, Card } from 'react-bootstrap';
import { useTranslation } from 'react-i18next';

function WhyChoose() {
  const { t } = useTranslation();

  const features = [
    {
      id: 1,
      titleKey: 'why_choose_feature1_title',
      descriptionKey: 'why_choose_feature1_desc',
      statsKey: 'why_choose_feature1_stats',
      icon: 'bi-shield-check'
    },
    {
      id: 2,
      titleKey: 'why_choose_feature2_title',
      descriptionKey: 'why_choose_feature2_desc',
      statsKey: 'why_choose_feature2_stats',
      icon: 'bi-lightning-charge'
    },
    {
      id: 3,
      titleKey: 'why_choose_feature3_title',
      descriptionKey: 'why_choose_feature3_desc',
      statsKey: 'why_choose_feature3_stats',
      icon: 'bi-star-fill'
    },
    {
      id: 4,
      titleKey: 'why_choose_feature4_title',
      descriptionKey: 'why_choose_feature4_desc',
      statsKey: 'why_choose_feature4_stats',
      icon: 'bi-lock-fill'
    }
  ];

  return (
    <section className="why-choose-section section-padding">
      <Container>
        <Row className="align-items-center">
          <Col lg={5} className="mb-5 mb-lg-0">
            <div className="fade-in-up">
              <h2 className="display-5 fw-bold mb-4" style={{ color: '#2c3e50' }}>
                {t('why_choose_title')} <span className="text-primary">Mongez</span>?
              </h2>
              <p className="lead mb-4" style={{ color: '#7f8c8d' }}>
                {t('why_choose_subtitle')}
              </p>
              
              <div className="bg-light p-4 rounded-3 mb-4">
                <div className="d-flex align-items-center">
                  <div className="bg-primary rounded-circle p-3 me-3">
                    <i className="bi bi-award-fill text-white fs-4"></i>
                  </div>
                  <div>
                    <h5 className="fw-bold mb-1">{t('why_choose_award_title')}</h5>
                    <p className="text-muted mb-0">{t('why_choose_award_desc')}</p>
                  </div>
                </div>
              </div>
              
              <button className="btn btn-outline-primary btn-lg px-4 py-3 rounded-pill">
                <i className="bi bi-chat-left-text me-2"></i>
                {t('why_choose_button')}
              </button>
            </div>
          </Col>
          
          <Col lg={7}>
            <Row className="g-4">
              {features.map((feature) => (
                <Col key={feature.id} md={6}>
                  <Card className="border-0 shadow-sm h-100 rounded-4 overflow-hidden">
                    <Card.Body className="p-4">
                      <div className="d-flex align-items-start mb-3">
                        <div 
                          className="rounded-circle p-3 me-3"
                          style={{ 
                            backgroundColor: '#e3f2fd',
                            flexShrink: 0
                          }}
                        >
                          <i className={`bi ${feature.icon} fs-4`} style={{ color: '#3498db' }}></i>
                        </div>
                        <div>
                          <Card.Title className="fw-bold mb-1" style={{ color: '#2c3e50' }}>
                            {t(feature.titleKey)}
                          </Card.Title>
                          <span className="badge bg-primary bg-opacity-10 text-primary rounded-pill px-3 py-1">
                            {t(feature.statsKey)}
                          </span>
                        </div>
                      </div>
                      <Card.Text className="text-muted">
                        {t(feature.descriptionKey)}
                      </Card.Text>
                    </Card.Body>
                  </Card>
                </Col>
              ))}
            </Row>
          </Col>
        </Row>
      </Container>
    </section>
  );
}

export default WhyChoose;